=head1 NAME

Spreadsheet::Write - Simplified writer for CSV or XLS (MS Excel) files

=head1 SYNOPSIS

    # EXCEL spreadsheet

    use Spreadsheet::Write;

    my $h=Spreadsheet::Write->new(
        file    => 'spreadsheet.xls',
        format  => 'xls',
        sheet   => 'Products',
        styles  => {
            money   => '($#,##0_);($#,##0)',
        },
    );

    $h->addrow('foo',{
        content         => 'bar',
        type            => 'number',
        style           => 'money',
        font_weight     => 'bold',
        font_color      => 42,
        font_face       => 'Times New Roman',
        font_size       => 20,
        align           => 'center',
        valign          => 'vcenter',
        font_decoration => 'strikeout',
        font_style      => 'italic',
    });
    $h->addrow('foo2','bar2');
    $h->freeze(1,0);

    # CSV file

    use Spreadsheet::Write;

    my $h=Spreadsheet::Write->new(
        file        => 'file.csv',
        encoding    => 'iso8859',
    );
    die $h->error() if $h->error;
    $h->addrow('foo','bar');

=head1 DESCRIPTION

C<Spreadsheet::Write> writes files in CSV or XLS (Microsoft Excel)
formats. It is especially suitable for building various dumps and
reports where rows are built in sequence, one after another.

=head1 METHODS

=cut

###############################################################################
package Spreadsheet::Write;

require 5.008_001;

use strict;
use IO::File;
use Text::CSV;
use Encode;
use Spreadsheet::WriteExcel;

BEGIN {
  use vars       qw($VERSION);
  $VERSION =     '0.03';
}

sub version {
  return $VERSION;
}

###############################################################################

=head2 new()

    $spreadsheet = Spreadsheet::Write->new(
        file            => 'table.xls',
        styles          => {
            mynumber        => '#,##0.00',
        }
    );

Creates a new spreadsheet object. It takes a list of options. The
following are valid:

    file        filename of the new spreadsheet (mandatory)
    encoding    encoding of output file (optional, csv format only)
    format      format of spreadsheet - 'csv', 'xls', or 'auto' (default).
    sheet       Sheet name (optional, xls format only)
    styles      Defines cell formatting shortcuts (optional)

If file format is 'auto' (or omitted), the format is guessed from the
filename extention. If impossible to guess the format defaults to 'csv'.

=cut

sub new(@) {
    my $proto = shift;
    my $args={@_};

    my $class = ref($proto) || $proto;
    my $self = {};

    bless $self, $class;

    my $filename=$args->{'file'} || $args->{'filename'} || die 'No file given';

    $self->{'_FILENAME'}=$filename;

    $self->{'_SHEETNAME'}=$args->{'sheet'} || '';

    my $format=$args->{'format'} || 'auto';
    if($format eq 'auto') {
        $format=($filename=~/\.(.+)$/) ? lc($1) : 'csv';
    }

    if(($format ne 'csv') && ($format ne 'xls')) {
        die "Format $format is not supported";
    }

    $self->{'_FORMAT'}=$format;

    $self->{'_STYLES'}=$args->{'styles'} || { };

    ### $self->_open();

    return $self;
}

###############################################################################

sub DESTROY {
    my $self=shift;
    $self->close();
}

###############################################################################

sub close {
    my $self=shift;

    return if $self->{'_CLOSED'};

    if($self->{'_FORMAT'} eq 'csv') {
        $self->{'_FH'}->close if $self->{'_FH'};
    }
    elsif($self->{'_FORMAT'} eq 'xls') {
        $self->{'_WORKBOOK'}->close if $self->{'_WORKBOOK'};
        $self->{'_FH'}->close if $self->{'_FH'};
    }

    $self->{'_CLOSED'}=1;
}

###############################################################################

sub error {
    my $self=shift;
    return $self->{'_ERROR'};
}

###############################################################################

sub _open($) {
    my $self=shift;

    $self->{'_CLOSED'} && die "Can't reuse a closed spreadsheet";

    my $fh=$self->{'_FH'};

    if(!$fh) {
        my $filename=$self->{'_FILENAME'} || return undef;
        $fh=new IO::File;
        $fh->open($filename,"w") || die "Can't open file $filename for writing: $!";
        $self->{'_FH'}=$fh;
    }

    if($self->{'_FORMAT'} eq 'xls') {
        my $worksheet=$self->{'_WORKSHEET'};
        my $workbook=$self->{'_WORKBOOK'};
        if(!$worksheet) {
            $fh->binmode();
            $workbook=Spreadsheet::WriteExcel->new($fh);
            $self->{'_WORKBOOK'}=$workbook;
            $worksheet = $workbook->add_worksheet($self->{'_SHEETNAME'});
            $self->{'_WORKSHEET'}=$worksheet;
            $self->{'_WORKBOOK_ROW'}=0;
        }
    }
    elsif($self->{'_FORMAT'} eq 'csv') {
        $self->{'_CSV_OBJ'}||=Text::CSV->new;
    }
    return $self;
}

###############################################################################

sub _format_cache($$) {
    my $self=shift;
    my $format=shift;
    
    my $cache_key='';
    foreach my $key (sort keys %$format) {
        $cache_key.=$key.$format->{$key};
    }

    if(exists($self->{'_FORMAT_CACHE'}->{$cache_key})) {
        return $self->{'_FORMAT_CACHE'}->{$cache_key};
    }

    return $self->{'_FORMAT_CACHE'}->{$cache_key}=$self->{'_WORKBOOK'}->add_format(%$format);
}

###############################################################################

=head2 addrow(arg1,arg2,...)

Adds a row into the spreadsheet. Takes arbitrary number of
arguments. Arguments represent column values and may be strings or hash
references. If an argument is a hash reference, additional optional
parameters may be passed:

    content         value to put into column
    style           formatting style, as defined in new()
    type            type of the content (defaults to 'auto')
    format          number format (see Spreadsheet::WriteExcel for details)
    font_weight     weight of font. Only valid value is 'bold'
    font_style      style of font. Only valid value is 'italic'
    font_decoration 'underline' or 'strikeout'
    font_face       font of column; default is 'Arial'
    font_color      color of font (see Spreadsheet::WriteExcel for color values)
    font_size       size of font
    align           alignment
    valign          vertical alignment
    width           column width, excel units (only makes sense once per column)

Styles can be used to assign default values for any of these formatting
parameters thus allowing easy global changes. Other parameters specified
override style definitions.

Example:

    my $sp=Spreadsheet::Write->new(
        file        => 'employees.xls',
        styles      => {
            header => { font_weight => 'bold' },
        },
    );
    $sp->addrow(
        { content => 'First Name', font_weight => 'bold' },
        { content => 'Last Name', font_weight => 'bold' },
        { content => 'Age', style => 'header' },
    );
    $sp->addrow("John","Doe",34);
    $sp->addrow("Susan","Smith",28);

Note that in this example all header cells will have identical
formatting even though some use direct formats and one uses
style.

If you want to store text that looks like a number you might want to use
{ type => 'string', format => '@' } arguments. By default the type detection is automatic,
as done by for instance L<Spreadsheet::WriteExcel> write() method.

It is also possible to supply an array reference in the 'content'
parameter of the extended format. It means to use the same formatting
for as many cells as there are elements in this array. Useful for
creating header rows. For instance, the above example can be rewritten
as:

    $sp->addrow(
        { style => 'header',
          content => [ 'First Name','Last Name','Age' ],
        }
    );

For CSV format all extra arguments are safely ignored.

=cut

sub addrow (@) {
    my $self=shift;
    my $parts=(@_ ? \@_ : [ '' ]);

    my @texts;
    my @props;

    $self->_open() || return undef;

    foreach my $part (@$parts) {
        if(ref($part) && (ref($part) eq 'HASH')) {
            my $content=$part->{'content'};
            if(ref($content) && (ref($content) eq 'ARRAY')) {
                foreach my $elt (@$content) {
                    push(@texts,$elt);
                    push(@props,$part);
                }
            }
            else {
                push(@texts,$part->{'content'});
                push(@props,$part);
            }
        }
        else {
            push(@texts,$part);
            push(@props,undef);
        }
    }
    if($self->{'_FORMAT'} eq 'csv') {
        my $string;
        my $nparts=scalar(@texts);
        for(my $i=0; $i<$nparts; $i++) {
            $texts[$i]=~s/([^\x20-\x7e])/'&#' . ord($1) . ';'/esg;
        }

        $self->{'_CSV_OBJ'}->combine(@texts) ||
            die "csv_combine failed at ".$self->{'_CSV_OBJ'}->error_input();

        $string=$self->{'_CSV_OBJ'}->string();
        $string=~s/&#(\d+);/chr($1)/esg;
        $string=Encode::decode('utf8',$string) unless Encode::is_utf8($string);
        $string=Encode::encode($self->{'_ENCODING'} || 'utf8',$string);
        $self->{'_FH'}->print($string."\n");

        return $self;
    }
    elsif($self->{'_FORMAT'} eq 'xls') {
        my $worksheet=$self->{'_WORKSHEET'};
        my $workbook=$self->{'_WORKBOOK'};
        my $row=$self->{'_WORKBOOK_ROW'};
        my $col=0;
        my $nparts=scalar(@texts);
        for(my $i=0; $i<$nparts; $i++) {
            my $value=$texts[$i];
            my $props=$props[$i];

            my %format;
            if($props) {
                if(my $style=$props->{'style'}) {
                    my $stprops=$self->{'_STYLES'}->{$style};
                    if(!$stprops) {
                        warn "Style '$style' is not defined\n";
                    }
                    else {
                        my %a;
                        @a{keys %$stprops}=values %$stprops;
                        @a{keys %$props}=values %$props;
                        $props=\%a;
                    }
                }

                if($props->{'font_weight'}) {
                    if($props->{'font_weight'} eq 'bold') {
                        $format{'bold'}=1;
                    }
                }
                if($props->{'font_style'}) {
                    if($props->{'font_style'} eq 'italic') {
                        $format{'italic'}=1;
                    }
                }
                my $decor=$props->{'font_decoration'};
                if($decor) {
                    if($decor eq 'underline') {
                        $format{'underline'}=1;
                    }
                    elsif($decor eq 'strikeout') {
                        $format{'font_strikeout'}=1;
                    }
                }
                if($props->{'font_color'}) {
                    $format{'color'}=$props->{'font_color'};
                }
                if($props->{'font_face'}) {
                    $format{'font'}=$props->{'font_face'};
                }
                if($props->{'font_size'}) {
                    $format{'size'}=$props->{'font_size'};
                }
                if($props->{'align'}) {
                    $format{'align'}=$props->{'align'};
                }
                if($props->{'valign'}) {
                    $format{'valign'}=$props->{'valign'};
                }
                if($props->{'format'}) {
                    $format{'num_format'}=$props->{'format'};
                }
                if($props->{'width'}) {
                    $worksheet->set_column($col,$col,$props->{'width'});
                }
            }

            my @params=($row,$col++,$value);

            push(@params,$self->_format_cache(\%format)) if keys %format;

            my $type=($props ? $props->{'type'} : '') || 'auto';
            if($type eq 'auto')         { $worksheet->write(@params); }
            elsif($type eq 'string')    { $worksheet->write_string(@params); }
            elsif($type eq 'text')      { $worksheet->write_string(@params); }
            elsif($type eq 'number')    { $worksheet->write_number(@params); }
            elsif($type eq 'blank')     { $worksheet->write_blank(@params); }
            elsif($type eq 'formula')   { $worksheet->write_formula(@params); }
            elsif($type eq 'url')       { $worksheet->write_url(@params); }
            else{
                warn "Unknown cell type $type";
                $worksheet->write(@params);
            }
        }
        $self->{'_WORKBOOK_ROW'}++;
    }
    return $self;
}

###############################################################################

=head2 addsheet(name)

Adds a new sheet into the document and makes it active. Subsequent
addrow() calls will add rows to that new sheet.

For CSV format this call is NOT ignored, but produces a fatal error
currently.

=cut

sub addsheet ($$) {
    my ($self,$name)=@_;

    $self->_open() || return undef;

    if($self->{'_FORMAT'} eq 'xls') {
        my $workbook=$self->{'_WORKBOOK'};
        my $worksheet=$workbook->add_worksheet($name);
        $self->{'_SHEETNAME'}=$name;
        $self->{'_WORKSHEET'}=$worksheet;
        $self->{'_WORKBOOK_ROW'}=0;
    }
    elsif($self->{'_FORMAT'} eq 'csv') {
        die "addsheet() is not supported for CSV format";
    }
}

###############################################################################

=head2 freeze($row, $col, $top_row, $left_col))

Sets a freeze-pane at the given position, equivalent to Spreadsheet::WriteExcel->freeze_panes().
Ignored for CSV files.

=cut

sub freeze (@) {
    my $self=shift;

    $self->_open() || return undef;

    if($self->{'_FORMAT'} eq 'xls') {
        $self->{'_WORKSHEET'}->freeze_panes(@_);
    }

    return $self;
}

###############################################################################

1;
__END__

=head1 AUTHORS

Nick Eremeev <nick.eremeev@gmail.com>
http://ejelta.com/
