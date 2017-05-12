package PDL::IO::XLSX::Reader::Relationships;
use 5.010;
use strict;
use warnings;

use Carp;
use XML::Parser::Expat;
use Archive::Zip ();
use File::Temp;

sub new {
    my ($class, $zip) = @_;

    my $self = bless {
        _relationships => {}, # { <rid> => {Target => "...", Type => "..."}, ... }
    }, $class;

    my $fh = File::Temp->new( SUFFIX => '.xml.rels');

    my $handle = $zip->memberNamed('xl/_rels/workbook.xml.rels') or return $self;
    croak 'Cannot write to: '.$fh->filename if $handle->extractToFileNamed($fh->filename) != Archive::Zip::AZ_OK;

    my $parser = XML::Parser::Expat->new;
    $parser->setHandlers(
        Start => sub { $self->_start(@_) },
        End   => sub { $self->_end(@_) },
    );
    $parser->parse($fh);

    $self;
}

sub relation_target {
    my ($self, $rid) = @_;
    return unless exists $self->{_relationships}->{$rid};
    my $relation = $self->{_relationships}->{$rid};
    return $relation->{Target};
}

sub relation {
    my ($self, $rid) = @_;
    return unless exists $self->{_relationships}->{$rid};
    return $self->{_relationships}->{$rid};
}

sub _start {
    my ($self, $parser, $name, %attrs) = @_;
    $self->{_in_relationships} = 1 if $name eq "Relationships";
    if ($self->{_in_relationships} && $name eq "Relationship" && $attrs{Id}) {
        $self->{_relationships}->{$attrs{Id}} = {
            Target => $attrs{Target},
            Type   => $attrs{Type},
        };
    }
}

sub _end {
    my ($self, $parser, $name) = @_;
    $self->{_in_relationships} = 0 if $name eq "Relationships";
}

package PDL::IO::XLSX::Reader::SharedStrings;
use 5.010;
use strict;
use warnings;

use Carp;
use XML::Parser::Expat;
use Archive::Zip ();
use File::Temp;

sub new {
    my ($class, $zip) = @_;

    my $self = bless {
        _data      => [],
        _is_string => 0,
        _is_ph     => 0,
        _buf       => '',
    }, $class;

    my $fh = File::Temp->new( SUFFIX => '.xml' );
    my $handle = $zip->memberNamed('xl/sharedStrings.xml') or return $self;
    croak 'Cannot write to: '.$fh->filename if $handle->extractToFileNamed($fh->filename) != Archive::Zip::AZ_OK;

    my $parser = XML::Parser::Expat->new;
    $parser->setHandlers(
        Start => sub { $self->_start(@_) },
        End   => sub { $self->_end(@_) },
        Char  => sub { $self->_char(@_) },
    );
    $parser->parse($fh);

    $self;
}

sub count {
    my ($self) = @_;
    scalar @{ $self->{_data} };
}

sub get {
    my ($self, $index) = @_;
    $self->{_data}->[$index];
}

sub _start {
    my ($self, $parser, $name, %attrs) = @_;
    $self->{_is_string} = 1 if $name eq 'si';
    $self->{_is_ph}     = 1 if $name eq 'rPh';
}

sub _end {
    my ($self, $parser, $name) = @_;

    if ($name eq 'si') {
        $self->{_is_string} = 0;
        push @{ $self->{_data} }, $self->{_buf};
        $self->{_buf} = '';
    }
    $self->{_is_ph} = 0 if $name eq 'rPh';
}

sub _char {
    my ($self, $parser, $data) = @_;
    $self->{_buf} .= $data if $self->{_is_string} && !$self->{_is_ph};
}

package PDL::IO::XLSX::Reader::Sheet;
use 5.010;
use strict;
use warnings;

use Carp;
use File::Temp;
use XML::Parser::Expat;
use Archive::Zip ();
use Scalar::Util ();

use constant {
    STYLE_IDX          => 'i',
    STYLE              => 's',
    FMT                => 'f',
    REF                => 'r',
    COLUMN             => 'c',
    VALUE              => 'v',
    TYPE               => 't',
    TYPE_SHARED_STRING => 's',
    GENERATED_CELL     => 'g',
};

sub new {
    my ($class, $zip, $target, $shared_strings, $styles, $row_callback) = @_;

    my $self = bless {
        _data => '',
        _is_sheetdata => 0,
        _row_count => 0,
        _current_row => [],
        _cell => undef,
        _is_value => 0,
        _row_callback   => $row_callback,
        _shared_strings => $shared_strings,
        _styles         => $styles,

    }, $class;

    my $fh = File::Temp->new( SUFFIX => '.xml' );
    my $handle = $zip->memberNamed("xl/$target");
    croak 'Cannot write to: '.$fh->filename if $handle->extractToFileNamed($fh->filename) != Archive::Zip::AZ_OK;

    my $parser = XML::Parser::Expat->new;
    $parser->setHandlers(
        Start => sub { $self->_start(@_) },
        End   => sub { $self->_end(@_) },
        Char  => sub { $self->_char(@_) },
    );
    $parser->parse($fh);

    $self;
}

sub _start {
    my ($self, $parser, $name, %attrs) = @_;

    if ($name eq 'sheetData') {
        $self->{_is_sheetdata} = 1;
    }
    elsif ($self->{_is_sheetdata} and $name eq 'row') {
        $self->{_current_row} = [];
    }
    elsif ($name eq 'c') {
        $self->{_cell} = {
            STYLE_IDX() => $attrs{ STYLE() },
            TYPE()      => $attrs{ TYPE() },
            REF()       => $attrs{ REF() },
            COLUMN()    => scalar(@{ $self->{_current_row} }) + 1,
        };
    }
    elsif ($name eq 'v') {
        $self->{_is_value} = 1;
    }
}

sub _end {
    my ($self, $parser, $name) = @_;

    if ($name eq 'sheetData') {
        $self->{_is_sheetdata} = 0;
    }
    elsif ($self->{_is_sheetdata} and $name eq 'row') {
        $self->{_row_count}++;
        $self->{_row_callback}->( delete $self->{_current_row} );
    }
    elsif ($name eq 'c') {
        my $c = $self->{_cell};
        $self->_parse_rel($c);

        if (($c->{ TYPE() } || '') eq TYPE_SHARED_STRING()) {
            my $idx = int($self->{_data});
            $c->{ VALUE() } = $self->{_shared_strings}->get($idx);
        }
        else {
            $c->{ VALUE() } = $self->{_data};
        }

        $c->{ STYLE() } = $self->{_styles}->cell_style( $c->{ STYLE_IDX() } );
        $c->{ FMT() }   = my $cell_type =
            $self->{_styles}->cell_type_from_style($c->{ STYLE() });

        my $v = $c->{ VALUE() };

        if (!defined $c->{ TYPE() }) {
            # actual value (number or date)
            if (Scalar::Util::looks_like_number($v)) {
                $c->{ VALUE() } = $v + 0;
            }
        } else {
            if (!defined $v) {
                $c->{ VALUE() } = '';
            }
            elsif ($cell_type ne 'unicode') {
                # warn 'not unicode: ' . $cell_type;
                $c->{ VALUE() } = $v;
            }
        }

        push @{ $self->{_current_row} }, $c;

        $self->{_data} = '';
        $self->{_cell} = undef;
    }
    elsif ($name eq 'v') {
        $self->{_is_value} = 0;
    }
}

sub _char {
    my ($self, $parser, $data) = @_;

    if ($self->{_is_value}) {
        $self->{_data} .= $data;
    }
}

sub _parse_rel {
    my ($self, $cell) = @_;

    my ($column, $row) = $cell->{ REF() } =~ /([A-Z]+)(\d+)/;

    my $v = 0;
    my $i = 0;
    for my $ch (split '', $column) {
        my $s = length($column) - $i++ - 1;
        $v += (ord($ch) - ord('A') + 1) * (26**$s);
    }

    $cell->{ REF() } = [$v, $row];

    if ($cell->{ COLUMN() } > $v) {
        croak sprintf 'Detected smaller index than current cell, something is wrong! (row %s): %s <> %s', $row, $v, $cell->{ COLUMN() };
    }

    # add omitted cells
    for ($cell->{ COLUMN() } .. $v-1) {
        push @{ $self->{_current_row} }, {
            GENERATED_CELL() => 1,
            STYLE_IDX()      => undef,
            TYPE()           => undef,
            REF()            => [ $_, $row ],
            COLUMN()         => $_,
            VALUE()          => '',
            FMT()            => 'unicode',
        };
    }
}

package PDL::IO::XLSX::Reader::Styles;
use 5.010;
use strict;
use warnings;

use Carp;
use XML::Parser::Expat;
use Archive::Zip ();
use File::Temp;

use constant BUILTIN_FMT  => 0;
use constant BUILTIN_TYPE => 1;

use constant BUILTIN_NUM_FMTS => [
    ['@', 'unicode'],           # 0x00
    ['0', 'int'],               # 0x01
    ['0.00', 'float'],          # 0x02
    ['#,##0', 'float'],         # 0x03
    ['#,##0.00', 'float'],      # 0x04
    ['($#,##0_);($#,##0)', 'float'], # 0x05
    ['($#,##0_);[RED]($#,##0)', 'float'], # 0x06
    ['($#,##0.00_);($#,##0.00_)', 'float'], # 0x07
    ['($#,##0.00_);[RED]($#,##0.00_)', 'float'], # 0x08
    ['0%', 'int'],                               # 0x09
    ['0.00%', 'float'],                          # 0x0a
    ['0.00E+00', 'float'],                       # 0x0b
    ['# ?/?', 'float'],                          # 0x0c
    ['# ??/??', 'float'],                        # 0x0d
    ['m-d-yy', 'datetime.date'],                 # 0x0e
    ['d-mmm-yy', 'datetime.date'],               # 0x0f
    ['d-mmm', 'datetime.date'],                  # 0x10
    ['mmm-yy', 'datetime.date'],                 # 0x11
    ['h:mm AM/PM', 'datetime.time'],             # 0x12
    ['h:mm:ss AM/PM', 'datetime.time'],          # 0x13
    ['h:mm', 'datetime.time'],                   # 0x14
    ['h:mm:ss', 'datetime.time'],                # 0x15
    ['m-d-yy h:mm', 'datetime.datetime'],        # 0x16
    #0x17-0x24 -- Differs in Natinal
    undef,                      # 0x17
    undef,                      # 0x18
    undef,                      # 0x19
    undef,                      # 0x1a
    undef,                      # 0x1b
    undef,                      # 0x1c
    undef,                      # 0x1d
    undef,                      # 0x1e
    undef,                      # 0x1f
    undef,                      # 0x20
    undef,                      # 0x21
    undef,                      # 0x22
    undef,                      # 0x23
    undef,                      # 0x24
    ['(#,##0_);(#,##0)', 'int'], # 0x25
    ['(#,##0_);[RED](#,##0)', 'int'], # 0x26
    ['(#,##0.00);(#,##0.00)', 'float'], # 0x27
    ['(#,##0.00);[RED](#,##0.00)', 'float'], # 0x28
    ['_(*#,##0_);_(*(#,##0);_(*"-"_);_(@_)', 'float'], # 0x29
    ['_($*#,##0_);_($*(#,##0);_(*"-"_);_(@_)', 'float'], # 0x2a
    ['_(*#,##0.00_);_(*(#,##0.00);_(*"-"??_);_(@_)', 'float'], # 0x2b
    ['_($*#,##0.00_);_($*(#,##0.00);_(*"-"??_);_(@_)', 'float'], # 0x2c
    ['mm:ss', 'datetime.timedelta'],                             # 0x2d
    ['[h]:mm:ss', 'datetime.timedelta'],                         # 0x2e
    ['mm:ss.0', 'datetime.timedelta'],                           # 0x2f
    ['##0.0E+0', 'float'],                                       # 0x30
    ['@', 'unicode'],                                            # 0x31
];

sub new {
    my ($class, $zip) = @_;

    my $self = bless {
        _number_formats => [],
        _is_cell_xfs   => 0,
        _current_style => undef,
    }, $class;

    my $fh = File::Temp->new( SUFFIX => '.xml' );

    my $handle = $zip->memberNamed('xl/styles.xml');
    croak 'Cannot write to: '.$fh->filename if $handle->extractToFileNamed($fh->filename) != Archive::Zip::AZ_OK;

    my $parser = XML::Parser::Expat->new;
    $parser->setHandlers(
        Start => sub { $self->_start(@_) },
        End   => sub { $self->_end(@_) },
        Char  => sub {  },
    );
    $parser->parse($fh);

    $self;
}

sub cell_style {
    my ($self, $style_id) = @_;
    $style_id ||= 0;
    $self->{_number_formats}[int $style_id];
}

sub cell_type_from_style {
    my ($self, $style) = @_;

    if ($style->{numFmt} > scalar @{ BUILTIN_NUM_FMTS() }) {
        return $self->{_num_fmt}{ $style->{numFmt} }{_type} // undef;
    }

    BUILTIN_NUM_FMTS->[ $style->{numFmt} ][BUILTIN_TYPE];
}

sub cell_format_from_style {
    my ($self, $style) = @_;

    if ($style->{numFmt} > scalar @{ BUILTIN_NUM_FMTS() }) {
        return $self->{_num_fmt}{ $style->{numFmt} }{formatCode} // undef;
    }

    BUILTIN_NUM_FMTS->[ $style->{numFmt} ][BUILTIN_FMT];
}

sub _start {
    my ($self, $parser, $name, %attrs) = @_;

    if ($name eq 'cellXfs') {
        $self->{_is_cell_xfs} = 1;
    }
    elsif ($self->{_is_cell_xfs} and $name eq 'xf') {
        $self->{_current_style} = {
            numFmt => int($attrs{numFmtId}) || 0,
            exists $attrs{fontId}            ? ( font        => $attrs{fontId}            ) : (),
            exists $attrs{fillId}            ? ( fill        => $attrs{fillId}            ) : (),
            exists $attrs{borderId}          ? ( border      => $attrs{borderId}          ) : (),
            exists $attrs{xfId}              ? ( xf          => $attrs{xfId}              ) : (),
            exists $attrs{applyFont}         ? ( applyFont   => $attrs{applyFont}         ) : (),
            exists $attrs{applyNumberFormat} ? ( applyNumFmt => $attrs{applyNumberFormat} ) : (),
        };
    }
    elsif ($name eq 'numFmts') {
        $self->{_is_num_fmts} = 1;
    }
    elsif ($self->{_is_num_fmts} and $name eq 'numFmt'){
        $self->{_current_numfmt} = {
            numFmtId   => $attrs{numFmtId},
            exists $attrs{formatCode} ? (
                formatCode => $attrs{formatCode},
                _type      => $self->_parse_format_code_type($attrs{formatCode}),
            ) : (),
        };
    }
}

sub _end {
    my ($self, $parser, $name) = @_;

    if ($name eq 'cellXfs') {
        $self->{_is_cell_xfs} = 0;
    }
    elsif ($self->{_current_style} and $name eq 'xf') {
        push @{ $self->{_number_formats } }, delete $self->{_current_style};
    }
    elsif ($name eq 'numFmts') {
        $self->{_is_num_fmts} = 0;
    }
    elsif ($self->{_current_numfmt} and $name eq 'numFmt') {
        my $id = $self->{_current_numfmt}{numFmtId};
        $self->{_num_fmt}{ $id } = delete $self->{_current_numfmt};
    }
}

sub _parse_format_code_type {
    my ($self, $format_code) = @_;
    my $type;
    if ($format_code =~ /(y|m|d|h|s)/) {
        $type = 'datetime.';

        $type .= 'date' if $format_code =~ /(y|d)/;
        $type .= 'time' if $format_code =~ /(h|s)/;

        $type .= 'date' if $type eq 'datetime.'; # assume as date only specified 'm'
    } else {
        $type = 'unicode';
    }
    return $type;
}

package PDL::IO::XLSX::Reader::Workbook;
use 5.010;
use strict;
use warnings;

use Carp;
use XML::Parser::Expat;
use Archive::Zip ();
use File::Temp;

sub new {
    my ($class, $zip) = @_;
    my $self = bless [], $class;
    my $fh = File::Temp->new( SUFFIX => '.xml' );
    my $handle = $zip->memberNamed('xl/workbook.xml');
    croak 'Cannot write to: '.$fh->filename if $handle->extractToFileNamed($fh->filename) != Archive::Zip::AZ_OK;
    my $parser = XML::Parser::Expat->new;
    $parser->setHandlers(
        Start => sub { $self->_start(@_) },
        End   => sub {},
        Char  => sub {},
    );
    $parser->parse($fh);
    $self;
}

sub names {
    my ($self) = @_;
    map { $_->{name} } @$self;
}

sub sheet_id {
    my ($self, $name) = @_;

    my ($meta) = grep { $_->{name} eq $name } @$self
        or return;

    if ($meta->{'r:id'}) {
        (my $r = $meta->{'r:id'}) =~ s/^rId//;
        return $r;
    }
    else {
        return $meta->{sheetId};
    }
}

sub _start {
    my ($self, $parser, $el, %attr) = @_;
    push @$self, \%attr if $el eq 'sheet';
}

package PDL::IO::XLSX::Reader;
use 5.010;
use strict;
use warnings;

use Carp;

sub new {
    my ($class, $filename) = @_;
    my $zip = Archive::Zip->new;
    croak "Cannot open file: $filename" if $zip->read($filename) != Archive::Zip::AZ_OK;
    bless {
        _zip            => $zip,
        _workbook       => PDL::IO::XLSX::Reader::Workbook->new($zip),
        _shared_strings => PDL::IO::XLSX::Reader::SharedStrings->new($zip),
        _styles         => PDL::IO::XLSX::Reader::Styles->new($zip),
        _relationships  => PDL::IO::XLSX::Reader::Relationships->new($zip),
    }, $class;
}

sub parse_sheet_by_name {
    my ($self, $name, $row_callback) = @_;
    my $id = $self->{_workbook}->sheet_id($name);
    croak "Non-existing sheet '$name'" if !defined $id;
    return $self->parse_sheet_by_id($id, $row_callback);
}

sub parse_sheet_by_id {
    my ($self, $id, $row_callback) = @_;

    my $relation = $self->{_relationships}->relation("rId$id");
    return unless $relation;

    if ($relation->{Type} eq 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet') {
        my $target = $relation->{Target};
        PDL::IO::XLSX::Reader::Sheet->new($self->{_zip}, $target, $self->{_shared_strings}, $self->{_styles}, $row_callback);
    }
}

1;

__END__

  my $xr = PDL::IO::XLSX::Reader->new("filename.xlsx");

  $xr->parse_sheet_by_name("Sheet1", sub {
        my ($row_values, $row_formats) = @_;
        #...
  });

  #or

  $xr->parse_sheet_by_id(1, sub {
        my ($row_values, $row_formats) = @_;
        #...
  });
