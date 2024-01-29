package Spreadsheet::HTML;
use strict;
use warnings FATAL => 'all';
our $VERSION = '1.22';

use Exporter 'import';
our @EXPORT_OK = qw(
    generate portrait landscape
    north east south west handson
    layout checkerboard scroll
    chess checkers draughts conway sudoku
    calculator calendar banner maze
    beadwork list
);

use HTML::AutoTag;
use Spreadsheet::HTML::Engine;
use Spreadsheet::HTML::Presets;
use Spreadsheet::HTML::File::Loader;

sub portrait    { generate( @_, theta =>   0 ) }
sub landscape   { generate( @_, theta => -270, tgroups => 0 ) }

sub north   { generate( @_, theta =>    0 ) }
sub east    { generate( @_, theta =>   90, tgroups => 0, pinhead => 1 ) }
sub south   { generate( @_, theta => -180, tgroups => 0, pinhead => 1 ) }
sub west    { generate( @_, theta => -270, tgroups => 0 ) }

sub layout          { Spreadsheet::HTML::Presets::layout(           @_ ) }
sub list            { Spreadsheet::HTML::Presets::List::list(       @_ ) }
sub select          { Spreadsheet::HTML::Presets::List::select(     @_ ) }
sub handson         { Spreadsheet::HTML::Presets::Handson::handson( @_ ) }
sub conway          { Spreadsheet::HTML::Presets::Conway::conway(   @_ ) }
sub calculator      { Spreadsheet::HTML::Presets::Calculator::calculator( @_ ) }
sub chess           { Spreadsheet::HTML::Presets::Chess::chess(         @_ ) }
sub checkers        { Spreadsheet::HTML::Presets::Draughts::draughts(   @_ ) }
sub draughts        { Spreadsheet::HTML::Presets::Draughts::draughts(   @_ ) }
sub tictactoe       { Spreadsheet::HTML::Presets::TicTacToe::tictactoe( @_ ) }
sub sudoku          { Spreadsheet::HTML::Presets::Sudoku::sudoku(   @_ ) }
sub checkerboard    { Spreadsheet::HTML::Presets::checkerboard(     @_ ) }
sub calendar        { Spreadsheet::HTML::Presets::calendar(         @_ ) }
sub scroll          { Spreadsheet::HTML::Presets::Scroll::scroll(   @_ ) }
sub maze            { Spreadsheet::HTML::Presets::maze(             @_ ) }
sub banner          { Spreadsheet::HTML::Presets::banner(           @_ ) }
sub beadwork        { Spreadsheet::HTML::Presets::Beadwork::beadwork( @_ ) }

sub generate {
    my %args = _process( @_ );

    $args{theta} *= -1 if $args{theta} and $args{flip};

    if (!$args{theta}) { # north

        $args{data} = $args{flip} ? [ map [ CORE::reverse @$_ ], @{ $args{data} } ] : $args{data};

    } elsif ($args{theta} == -90) {

        $args{data} = [ CORE::reverse @{ _transpose( $args{data} ) }];
        $args{data} = ($args{pinhead} and !$args{headless})
            ? [ map [ @$_[1 .. $#$_], $_->[0] ], @{ $args{data} } ]
            : [ map [ CORE::reverse @$_ ], @{ $args{data} } ];

    } elsif ($args{theta} == 90) { # east

        $args{data} = _transpose( $args{data} );
        $args{data} = ($args{pinhead} and !$args{headless})
            ? [ map [ @$_[1 .. $#$_], $_->[0] ], @{ $args{data} } ]
            : [ map [ CORE::reverse @$_ ], @{ $args{data} } ];

    } elsif ($args{theta} == -180) { # south

        $args{data} = ($args{pinhead} and !$args{headless})
            ? [ @{ $args{data} }[1 .. $#{ $args{data} }], $args{data}[0] ]
            : [ CORE::reverse @{ $args{data} } ];

    } elsif ($args{theta} == 180) {

        $args{data} = ($args{pinhead} and !$args{headless})
            ? [ map [ CORE::reverse @$_ ], @{ $args{data} }[1 .. $#{ $args{data} }], $args{data}[0] ]
            : [ map [ CORE::reverse @$_ ], CORE::reverse @{ $args{data} } ];

    } elsif ($args{theta} == -270) { # west

        $args{data} = [@{ _transpose( $args{data} ) }];

    } elsif ($args{theta} == 270) {

        $args{data} = [ CORE::reverse @{ _transpose( $args{data} ) }];
    }

    if ($args{scroll}) {
        my ($js, %new_args) = Spreadsheet::HTML::Presets::Scroll::scroll(
            %args,
            data => [ map [ map $_->{cdata}, @$_ ], @{ $args{data} } ],
        );
        for (keys %args) {
            if (ref $args{$_} eq 'HASH') {
                $new_args{$_} = { %{ $new_args{$_} || {} }, %{ $args{$_} || {} } };
            }
        }
        my $table = _make_table( _process( %new_args ) );
        return $js . $table;
    }

    return _make_table( %args );
}

sub new {
    my $class = shift;
    my %attrs = ref($_[0]) eq 'HASH' ? %{+shift} : @_;
    return bless { %attrs }, $class;
}

sub _process {
    my ($self,$data,$args) = _args( @_ );

    if ($self and $self->{is_cached}) {
        return wantarray ? ( data => $self->{data}, %{ $args || {} } ) : $data;
    }

    # headings is an alias for -r0
    $args->{-r0} = $args->{headings} if exists $args->{headings};

    # headings to index mapping (alias for some -cX)
    my %index = ();
    if ($#{ $data->[0] }) {
        %index = map { '-' . ($data->[0][$_] || '') => $_ } 0 .. $#{ $data->[0] };
        for (grep /^-/, keys %$args) {
            $args->{"-c$index{$_}" } = $args->{$_} if exists $index{$_};
        }
    }

    my $empty = exists $args->{empty} ? $args->{empty} : '&nbsp;';
    my $tag   = ($args->{headless} or $args->{matrix}) ? 'td' : 'th';
    for my $row (0 .. $args->{_max_rows} - 1) {

        unless ($args->{_layout}) {
            push @{ $data->[$row] }, undef for 1 .. $args->{_max_cols} - $#{ $data->[$row] } + 1;  # pad
            pop  @{ $data->[$row] } for $args->{_max_cols} .. $#{ $data->[$row] };                 # truncate
        }

        for my $col (0 .. $#{ $data->[$row] }) {

            my ( $cdata, $attr ) = ( $data->[$row][$col], undef );
            for ($tag, "-c$col", "-r$row", "-r${row}c${col}") {
                next unless exists $args->{$_};
                ( $cdata, $attr ) = _extrapolate( $cdata, $attr, $args->{$_} );
            }

            do{ no warnings;
                $cdata = HTML::Entities::encode_entities( $cdata, $args->{encodes} ) if $args->{encode} || exists $args->{encodes};
                $cdata =~ s/^\s*$/$empty/g;
            };

            $data->[$row][$col] = { 
                tag => $tag, 
                (defined( $cdata ) ? (cdata => $cdata) : ()), 
                (keys( %$attr )    ? (attr => $attr)   : ()),
            };
        }
        $tag = 'td';
    }

    if ($args->{cache} and $self and !$self->{is_cached}) {
        $self->{data} = $data;
        $self->{is_cached} = 1;
    }

    shift @$data if $args->{headless};

    return wantarray ? ( data => $data, %$args ) : $data;
}

sub _make_table {
    my %args = @_;

    my @cdata = ( _tag( %args, tag => 'caption' ) || (), _colgroup( %args ) );

    if ($args{tgroups}) {

        my @body = @{ $args{data} };
        my $head = shift @body unless $args{matrix} and scalar @{ $args{data} } > 2;
        my $foot = pop @body if !$args{matrix} and $args{tgroups} > 1 and scalar @{ $args{data} } > 2;

        my $head_row  = { tag => 'tr', attr => $args{'thead.tr'}, cdata => $head };
        my $foot_row  = { tag => 'tr', attr => $args{'tfoot.tr'}, cdata => $foot };
        my $body_rows = [ map { tag => 'tr', attr => $args{tr}, cdata => $_ }, @body ];

        if (int($args{group} || 0) > 1) {
            $body_rows = [
                map [ @$body_rows[$_ .. $_ + $args{group} - 1] ],
                _range( 0, $#$body_rows, $args{group} )
            ];
            pop @{ $body_rows->[-1] } while !defined $body_rows->[-1][-1];
        } else {
            $body_rows = [ $body_rows ];
        }

        push @cdata, (
            ( $head ? { tag => 'thead', attr => $args{thead}, cdata => $head_row } : () ),
            ( $foot ? { tag => 'tfoot', attr => $args{tfoot}, cdata => $foot_row } : () ),
            ( map     { tag => 'tbody', attr => $args{tbody}, cdata => $_ }, @$body_rows ),
        );


    } else {
        push @cdata, map { tag => 'tr', attr => $args{tr}, cdata => $_ }, @{ $args{data} };
    }

    return $args{_auto}->tag( tag => 'table', attr => $args{table}, cdata => \@cdata );
}

sub _args {
    my ($self,@data,$data,@args,$args);
    $self = shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    $data = shift if (@_ == 1);

    while (@_) {
        if (ref( $_[0] )) {
            push @data, shift;
            if (ref( $_[0] )) {
                push @data, shift;
            } elsif (defined $_[0]) {
                push @args, shift, shift;
            }
        } else {
            push @args, shift, shift;
        }
    }

    $data ||= (@data == 1) ? $data[0] : (@data) ? [ @data ] : undef;
    $args = scalar @args ? { @args } : {};
    $args = { %{ $self || {} }, %{ $args || {} } };
    $data = delete $args->{data} if exists $args->{data};

    $args->{_auto} ||= HTML::AutoTag->new(
        indent  => $args->{indent},
        level   => $args->{level},
        sorted  => $args->{sorted_attrs},
    );

    return ( $self, $self->{data}, $args ) if $self and $self->{is_cached};

    $args->{worksheet} ||= 1;
    $args->{worksheet} = 1 if $args->{worksheet} < 1;
    if ($args->{file}) {
        $data = Spreadsheet::HTML::File::Loader::_parse( $args, $data );
        unlink $args->{file} if $args->{_unlink};
    }

    $data = [ $data ] unless ref($data) eq 'ARRAY';
    $data = [ $data ] unless ref($data->[0]) eq 'ARRAY';

    if ($args->{wrap} and defined $data->[0][0]) {
        my @flat = map @$_, @$data;
        $data = [
            map [ @flat[$_ .. $_ + $args->{wrap} - 1] ],
            _range( 0, $#flat, $args->{wrap} )
        ];
    }

    $data = Spreadsheet::HTML::Engine::_apply( $data, $args->{apply} ) if $args->{apply};

    $args->{_max_rows} = scalar @{ $data }      || 1;
    $args->{_max_cols} = scalar @{ $data->[0] } || 1;

    if ($args->{fill}) {
        my ($row,$col) = split /\D/, $args->{fill};
        $args->{_max_rows} = $row if (int($row || 0)) > ($args->{_max_rows});
        $args->{_max_cols} = $col if (int($col || 0)) > ($args->{_max_cols});
    }

    return ( $self, [ map [@$_], @$data], $args );
}

sub _extrapolate {
    my ( $cdata, $attr, $thingy ) = @_;
    my $new_attr;
    $thingy = [ $thingy ] unless ref( $thingy ) eq 'ARRAY';
    for (@{ $thingy }) {
        if (ref($_) eq 'CODE') {
            $cdata = $_->($cdata);
        } elsif (ref($_) eq 'HASH') {
            $new_attr = $_;
        }
    }
    $attr = { %{ $attr || {} }, %{ $new_attr || {} } };
    return ( $cdata, $attr );
}

sub _colgroup {
    my %args = @_;

    my @colgroup;
    $args{col} = [ $args{col} ] if ref($args{col}) eq 'HASH';

    if (ref($args{col}) eq 'ARRAY') {

        if (ref $args{colgroup} eq 'ARRAY') {
            @colgroup = map {
                tag   => 'colgroup',
                attr  => $_,
                cdata => [ map { tag => 'col', attr => $_ }, @{ $args{col} } ]
            }, @{ $args{colgroup} }; 
        } else {
            @colgroup = {
                tag   => 'colgroup',
                attr  => $args{colgroup},
                cdata => [ map { tag => 'col', attr => $_ }, @{ $args{col} } ]
            }; 
        }

    } else {

        $args{colgroup} = [ $args{colgroup} ] if ref($args{colgroup}) eq 'HASH';
        if (ref $args{colgroup} eq 'ARRAY') {
            @colgroup = map { tag => 'colgroup', attr => $_ }, @{ $args{colgroup} };
        }
    }

    return @colgroup;
}

sub _tag {
    my %args = @_;
    my $thingy = $args{ $args{tag} };
    return unless defined $thingy;
    my $tag = { tag => $args{tag}, cdata => $thingy };
    if (ref $thingy eq 'HASH') {
        $tag->{cdata} = ( keys   %$thingy )[0];
        $tag->{attr}  = ( values %$thingy )[0];
    }
    return $tag;
}

# credit: Math::Matrix
sub _transpose {
    my $data = shift;
    my @trans;
    for my $i (0 .. $#{ $data->[0] }) {
        push @trans, [ map $_->[$i], @$data ]
    }
    return \@trans;
}

sub _range {grep!(($_-$_[0])%($_[2]||1)),$_[0]..$_[1]}


1;

__END__
=head1 NAME

Spreadsheet::HTML - Just another HTML table generator.

=head1 SYNOPSIS

Object oriented interface:

    use Spreadsheet::HTML;

    my @data = ( [qw(foo b&r b&z)], [1,2,3], [4,5,6], [7,8,9] );
    my $gen  = Spreadsheet::HTML->new( data => \@data, encode => 1 );

    print $gen->portrait( indent => '   ' );
    print $gen->landscape( indent => "\t" );

    $gen = Spreadsheet::HTML->new( file => 'data.xls', worksheet => 2 );
    print $gen->generate( preserve => 1 );

Procedural interface:

    use Spreadsheet::HTML qw( portrait landscape );

    print portrait( \@data, td => sub { sprintf "%02d", shift } );
    print landscape( \@data, tr => { class => [qw(odd even)] } );

=head1 DESCRIPTION

Generate HTML tables with ease (HTML4, XHTML and HTML5). Generate portrait,
landscape and other rotated views, Handsontable tables, HTML calendars,
checkerboard patterns, games such as sudoku, banners and mazes, and create
animations of cell values and backgrounds via jQuery. Transform Excel, HTML,
JSON, CSV, YAML, PNG, JPEG and GIF files instantly into HTML tables.

=head1 CLI TOOLS

=over 4

=item * C<mktable>

Quickly generate tables without writing a script:

  $ mktable landscape --param file=data.xls --param preserve=1 > out.html

If you have L<HTML::Display> installed, you can direct the output to
your default browser:

  $ mktable landscape --param data=[[a..d],[1..4],[5..8]] --display

  $ mktable conway --param data=[1..300] --param wrap=20 --param matrix=1 --display

  $ mktable sudoku --display

  $ mktable tictactoe --display

  $ mktable calendar --param today='{bgcolor=>"red"}' --display

  $ mktable beadwork --param preset=dk --display

Run C<mktable --man> for more documentation. You can also use this tool to quickly look
up documentation for methods and (most) parameters:

  $ mktable --help handson

  $ mktable --help theta

  $ mktable --help td

=item * C<benchmark-spreadsheet-html>

Run benchmarks against several different HTML table generators
available on CPAN. See C<benchmark-spreadsheet-html --man> for more.

=back

=head1 METHODS

All methods (except C<new>) are exportable as functions. They all
accept the same named parameters (see PARAMETERS below).  With the
exception of C<new>, all methods return an HTML table as a scalar string.

=over 4

=item * C<new( %params )>

  my $generator = Spreadsheet::HTML->new( data => $data );

Constructs object. Accepts the same named parameters as the table
generating methods below:

=item * C<generate( %params )>

Generate an HTML table.

  print $generator->generate();

=item * C<portrait( %params )>

Generate an HTML table with headings positioned at the top.

  print $generator->portrait();

=for html
<table style="border: 1px dashed #A0A0A0"><tr><td><b>&nbsp;&nbsp;heading1&nbsp;&nbsp;</b></td><td><b>&nbsp;&nbsp;heading2&nbsp;&nbsp;</b></td><td><b>&nbsp;&nbsp;heading3&nbsp;&nbsp;</b></td><td><b>&nbsp;&nbsp;heading4&nbsp;&nbsp;</b></td></tr><tr><td>&nbsp;&nbsp;row1col1&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row1col2&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row1col3&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row1col4&nbsp;&nbsp;</td></tr><tr><td>&nbsp;&nbsp;row2col1&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col2&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col3&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col4&nbsp;&nbsp;</td></tr><tr><td>&nbsp;&nbsp;row3col1&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col2&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col3&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col4&nbsp;&nbsp;</td></tr></table>

=item * C<north( %params )>

Alias for C<portrait()>.

  print $generator->north();

=item * C<landscape( %params )>

Generate an HTML table with headings positioned at the left.

  print $generator->landscape();

=for html
<table style="border: 1px dashed #A0A0A0"><tr><td><b>&nbsp;&nbsp;heading1&nbsp;&nbsp;</b></td><td>&nbsp;&nbsp;row1col1&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col1&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col1&nbsp;&nbsp;</td></tr><tr><td><b>&nbsp;&nbsp;heading2&nbsp;&nbsp;</b></td><td>&nbsp;&nbsp;row1col2&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col2&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col2&nbsp;&nbsp;</td></tr><tr><td><b>&nbsp;&nbsp;heading3&nbsp;&nbsp;</b></td><td>&nbsp;&nbsp;row1col3&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col3&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col3&nbsp;&nbsp;</td></tr><tr><td><b>&nbsp;&nbsp;heading4&nbsp;&nbsp;</b></td><td>&nbsp;&nbsp;row1col4&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col4&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col4&nbsp;&nbsp;</td></tr></table>

=item * C<west( %params )>

Alias for C<landscape>.

  print $generator->west();

=item * C<south( %params )>

Generate an HTML table with headings positioned at the bottom.

  print $generator->south();

=for html
<table style="border: 1px dashed #A0A0A0"><tr><td>&nbsp;&nbsp;row1col1&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row1col2&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row1col3&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row1col4&nbsp;&nbsp;</td></tr><tr><td>&nbsp;&nbsp;row2col1&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col2&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col3&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col4&nbsp;&nbsp;</td></tr><tr><td>&nbsp;&nbsp;row3col1&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col2&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col3&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col4&nbsp;&nbsp;</td></tr><tr><td><b>&nbsp;&nbsp;heading1&nbsp;&nbsp;</b></td><td><b>&nbsp;&nbsp;heading2&nbsp;&nbsp;</b></td><td><b>&nbsp;&nbsp;heading3&nbsp;&nbsp;</b></td><td><b>&nbsp;&nbsp;heading4&nbsp;&nbsp;</b></td></tr></table>

=item * C<east( %params )>

This method generates an HTML table with headings positioned at the right.

  print $generator->east();

=for html
<table style="border: 1px dashed #A0A0A0"><tr><td>&nbsp;&nbsp;row1col1&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col1&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col1&nbsp;&nbsp;</td><td><b>&nbsp;&nbsp;heading1&nbsp;&nbsp;</b></td></tr><tr><td>&nbsp;&nbsp;row1col2&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col2&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col2&nbsp;&nbsp;</td><td><b>&nbsp;&nbsp;heading2&nbsp;&nbsp;</b></td></tr><tr><td>&nbsp;&nbsp;row1col3&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col3&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col3&nbsp;&nbsp;</td><td><b>&nbsp;&nbsp;heading3&nbsp;&nbsp;</b></td></tr><tr><td>&nbsp;&nbsp;row1col4&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row2col4&nbsp;&nbsp;</td><td>&nbsp;&nbsp;row3col4&nbsp;&nbsp;</td><td><b>&nbsp;&nbsp;heading4&nbsp;&nbsp;</b></td></tr></table>

=back

For most cases, C<portrait> (headings at top)
and C<landscape> (headings at left) are all you need.

=head1 PARAMETERS

All methods/procedures accept the same named parameters. Some methods
pre-define parameters on your behalf, for convenience. If these parameters
are defined, they may be overriden where applicable. You do not necessarily
have to specify C<data>, any bare array references will be collected
and assigned to C<data>. Just because you can, however, does not
mean you should. Everything is meant to be convenient.

=head2 LITERAL PARAMETERS

Literal parameters provides the means to modify the macro
aspects of the table, such as indentation, encoding, data
source and table orientation.

=over 4

=item * C<data>

The data to be rendered into table cells. Should be
an array ref of array refs.

  data => [["a".."c"],[1..3],[4..6],[7..9]]

=item * C<file>

String. The name of the data file to read. Supported formats
are XLS, CSV, JSON, YAML, HTML, GIF, PNG and JPG.

  file => 'foo.json'

C<file> overrides C<data>. You generally either specify C<data>
or C<file> but not both (unless the file is an image in which the
two can be combined). 

  data => \@data, file => 'background.png'

See L<Spreadsheet::HTML::File::Loader> for more on supported file formats.
See L<DBIx::HTML> for formatting your SQL database queries.

If you don't mind having a temp file created on your behalf, you can
also supply a URI:

  file => 'http://your.site.com/path/to/foo.json'

The temp file will be unlinked unless you set the super secret hidden
param C<_unlink> to zero (0):

  _unlink => 0

=item * C<block>

Integer. Can be supplied in conjunction with C<file> for image
formats (JPEG, PNG and GIF). Defaults to 8. Cannot be less than 1.
Representing an image as an HTML table on a pixel by pixel basis
tends to produce tables that are too large. This parameter can be
used to increase and decrease that size, by reading in blocks of
pixels (8x8=64 pixels to be represented by one table cell) and
determining the pixel color for that block (see C<blend> below).
The smaller the block size the longer the processing time.

  block => 4

=item * C<blend>

Boolean. Default false. Can be supplied in conjuction with C<block>
to change the algorithm for determining block's pixel color. When
set to true, the pixel color is determined by averaging the colors of
all pixels in that block. When false (default), the pixel color is
determined by finding the the most used color in the block.

  blend => 1

Turning C<blend> on tends to work better for photo realism. Keep it
off for producing 1980's style pixel art images.

=item * C<worksheet>

Integer. Can be supplied in conjunction with C<file>. If multiple
worksheets or data tables (or image frames) are present, use this
parameter to select which one (index 1 based). Defaults to 1 (first found).

  worksheet => 3 # the third worksheet, data table or image frame found  

=item * C<preserve>

Boolean. Can be supplied in conjunction with C<file>. Attempts to copy
over all formatting styles from original document to table.
Styles are not currently deduped, so use with care as the
final output will contain a lot of redundant cell styles.

  preserve => 1

=item * C<fill>

String. Can be supplied instead of C<data> to generate empty
cells, or in conjunction with C<data> to pad existing
cells (currently pads the right and bottom sides only.)

  fill => '5x12'

=item * C<wrap>

Integer. Can be supplied in conjunction with a 1D C<data> to
automatically wrap into a 2D array matrix. Can also
"rewrap" existed 2D array matrices, but at the expense
of likely mangling the headings.

  wrap => 10 

=item * C<apply>

String. Applies formulas parsable by L<Spreadsheet::Engine> to data.

  apply => 'set B6 formula SUM(B2:B5)'

Accepts lists:

  apply => ['set B6 formula SUM(B2:B5)', 'set C6 formula SUM(C2:C5)']

Can be used to create total and sub total rows. See
L<Spreadsheet::Engine> for more.

=item * C<theta: 0, 90, 180, 270, -90, -180, -270>

Integer. Rotates table clockwise for positive values and 
counter-clockwise for negative values. Default to 0:
headers at top.  90: headers at right. 180: headers at bottom.
270: headers at left. To achieve landscape, use -270.

  theta => -270

=item * C<flip>

Boolean. Flips table horizontally from the perspective of
the headings "row" by negating the value of C<theta>.

  flip => 1

=item * C<pinhead>

Boolean. Works in conjunction with C<theta> to ensure reporting
readability. Without it, C<south()> and C<east()> would
have data cells arranged in reverse order.

  pinhead => 1

=item * C<indent>

String. Render the table with nested indentation. Defaults to
undefined which produces no indentation. Adds newlines
when set to any value that is defined.

  indent => '    '

  indent => "\t"

=item * C<level>

Integer. Start indentation at this level. Useful for matching
nesting styles of original HTML text that you may want
to insert into to.

  level => 4

This value does not say 'use 4 spaces', it applies the
repetition operator to the value of C<indent> 4 times.

=item * C<encode>

Boolean. Encode HTML entities. Defaults to false, which produces no encoding.
If set to true without further specifying a value for C<encodes> (see below),
will encode all control chars, high bit chars and '<', '&', '>', ''' and '"'.

  encode => 1

=item * C<encodes>

String. Set value to those characters you wish to have HTML encoded.

  encodes => '<>"'

=item * C<empty>

String. Replace empty cells with this value. Defaults to C<&nbsp;>.
Set value to C<undef> to avoid any substitutions.

  empty => '&#160;'

=item * C<matrix>

Boolean. Render the headings row with only <td> tags, no <th> tags.

  matrix => 1

=item * C<headless>

Boolean. Render the table with without the headings row at all. 
Any configuration to C<headings> or C<-r0> will be discarded with
the headings row.

  headless => 1

=item * C<tgroups>

Integer. Group table rows into <thead>, <tbody> and <tfoot> sections.

When C<tgroups> is set to 1, the <tfoot> section is
omitted. The last row of the data is found at the end
of the <tbody> section instead. (loose)

  tgroups => 1

When C<tgroups> is set to 2, the <tfoot> section is found
in between the <thead> and <tbody> sections. (strict)

  tgroups => 2

=item * C<group>

Integer. Will chunk body rows into tbody groups of size C<group>.

  group => 4

Currently only accepts integers (not column names).

=item * C<cache>

Boolean. Preserve data after it has been processed (and loaded).
Useful for loading data from files only once.

  cache => 1

=item * C<scroll>

Boolean. Scrolls the table cells. See L<Spreadsheet::HTML::Presets::Scroll>.

  scroll => 1

=item * C<headings>

Apply callback subroutine to each cell in headings row.

  headings => sub { join(" ", map {ucfirst lc $_} split "_", shift) }

Or apply hash reference as attributes:

  headings => { class => 'some-class' }

Or both via array reference:

  headings => [ sub { uc shift }, { class => "foo" } ]

Since C<headings> is a natural alias for the dynamic parameter
C<-r0>, it could be considered as a dynamic parameter. Be
careful not to prepend a dash to C<headings> ... only dynamic
parameters use leading dashes.

=item * C<sorted_attrs>

Boolean. This is useful for ensuring that attributes within tags are
rendered in alphabetical order, for consistancy. You will most likely
never need this feature.

  sorted_attrs

=back

=head2 DYNAMIC PARAMETERS

Dynamic parameters provide a means to control the micro
elements of the table, such as modifying headings by their
name and rows and columns by their indices (X). They contain
leading dashes to seperate them from literal and tag parameters.

=over 4

=item * C<-rX>

Apply this callback subroutine to all cells in row X.
(0 index based)

  -r3 => sub { uc shift }

Or apply hash ref as attributes:

  -r3 => { class => 'some-class' }

Or both:

  -r3 => [ sub { uc shift }, { class => "foo" } ]

=item * C<-cX>

Apply this callback to all cells in column X.
(0 index based)

  -c4 => sub { sprintf "%02d", shift || 0 }

Or apply hash ref as attributes:

  -c4 => { class => 'some-class' }

Or both:

  -c4 => [ sub { uc shift }, { class => "foo" } ]

You can alias any column number by the value of the heading
name in that column:

  -occupation => sub { "<b>$_[0]"</b>" }

  -salary => { class => 'special-row' }

  -employee_no => [ sub { sprintf "%08d", shift }, { class => "foo" } ]

=item * C<-rXcX>

Apply this callback or hash ref of attributres
to the cell at row X and column X. (0 index based)

  -r3c4 => { class => 'special-cell' }

=back

=head2 TAG PARAMETERS

Tag parameters provide a means to control the attributes
of the table's tags, and in the case of <th> and <td> the
contents via callback subroutines. Although similar in form,
they are differentiated from litertal parameters because they
share the names of the actual HTML table tags.

=over 4

=item * C<table>

Hash ref. Apply these attributes to the specified tag.

  table => { border => 1 }

=item * C<thead>

Hash ref. Apply these attributes to the specified tag.

  thead => { class => 'heading' }

=item * C<tfoot>

Hash ref. Apply these attributes to the specified tag.

  tfoot => { class => 'footing' }

=item * C<tbody>

Hash ref. Apply these attributes to the specified tag.

  tbody => { class => 'body' }

=item * C<tr>

Hash ref. Apply these attributes to the specified tag.

  tr => { style => { background => [qw( color1 color2 )]' } }

Does not apply to <tr> groups found within <thead> or <tfoot>.
(See C<thead.tr> and C<tfoot.tr> below.)

=item * C<th>

Hash ref, sub ref or array ref containing either.

  th => { class => 'heading' }

  th => sub { uc shift }

  th => [ sub { uc shift }, { class => 'heading' } ]

=item * C<td>

Hash ref, sub ref or array ref containing either.

  td => { class => 'cell' }

  td => sub { uc shift }

  td => [ sub { uc shift }, { class => 'cell' } ]

=item * C<caption>

Caption is special in that you can either pass a string to
be used as CDATA or a hash whose only key is the string
to be used as CDATA.

  caption => "Just Another Title"

  caption => { "A Title With Attributes" => { align => "bottom" } }

=item * C<colgroup>

Add colgroup tag(s) to the table. Use an AoH for multiple.

  colgroup => { span => 2, style => { 'background-color' => 'orange' } }

  colgroup => [ { span => 20 }, { span => 1, class => 'end' } ]

=item * C<col>

Add col tag(s) to the table. Use an AoH for multiple. Wraps
tags within a colgroup tag. Same usage as C<colgroup>.

  col => { span => 2, style => { 'background-color' => 'orange' } }

  col => [ { span => 20 }, { span => 1, class => 'end' } ]

=item * C<thead.tr>

When C<tgroups> is 1 or 2, this tag parameter is available to control
the attributes of the <tr> tag within the <thead> group.

  'tr.head' => { class => 'heading-row' }

=item * C<tfoot.tr>

When C<tgroups> is 2, this tag parameter is available to control
the attributes of the <tr> tag within the <tfoot> group.

  'tr.foot' => { class => 'footing-row' }

=back

=head1 PRESET METHODS

The following preset methods are availble for creating tables that can be used
with little to no additional coding. All preset methods accept all of the
above mentioned parameters (%params) in addition to those specific to themselves.

=over 4

=item * C<layout( %params )>

Generate layout tables.

=item * C<list( ordered, col, row, %params )>

Generate <ol> and <ul> lists.

=item * C<select( col, row, values, selected, placeholder, optgroup, label, %params )>

Generate <select> form elements.

=item * C<handson( args, jquery, handsonjs, css, %params )>

Generate Handsontable tables. (Excel like interface for browsers.)

=item * C<checkerboard( colors || class, %params )>

Generate checkerboard patterns in cell backgrounds. Specify an array of colors to be
arranged in checkerboard pattern or array of class names (for external CSS).

=item * C<banner( on, off, text, font, dir, emboss, %params )>

Generate banners via Text::FIGlet.

=item * C<scroll( fgdirection, fx, fy, bgdirection, bx, by, interval, jquery, %params )>

Scroll table cell foregrounds and backgrounds.

=item * C<calendar( month, year, today, -day, %params )>

Generate calendars.

=item * C<calculator( jquery, %params )>

Generate a simple HTML table calculator.

=item * C<beadwork( preset, art, map, bgcolor, %params )>

Turn cell backgrounds into 8-bit pixel art.

=item * C<conway( on, off, colors, fade, interval, jquery, %params )>

Turn cell backgrounds into Conway's game of life.

=item * C<sudoku( blanks, attempts, jquery, %params )>

Generate 9x9 HTML table sudoku boards.

=item * C<maze( on, off, %params )>

Generates a static maze.

=item * C<tictactoe( jquery, %params )>

Creates a playable Tic-Tac-Toe game board.

=item * C<draughts( on, off, jquery, %params )>

=item * C<checkers( on, off, jquery, %params )>

Creates a NON playable Draughts/Checkers game board.

=item * C<chess( on, off, jquery, jqueryui, %params )>

Creates a NON playable Chess game board.

=back

See L<Spreadsheet::HTML::Presets> for more documentation
(and source code for usage examples).

=head1 REQUIRES

=over 4

=item * L<HTML::AutoTag>

Used to generate HTML tags and  attributes. Handles indentation and HTML entity encoding.
Requires L<Tie::Hash::Attribute> and L<HTML::Entities>.

=back

=head1 OPTIONAL

The following is used to apply formulas to data:

=over 4

=item * L<Spreadsheet::Engine>

=back

The following are used to load data from various
different file formats:

=over 4

=item * L<Spreadsheet::Read>

Uses the following optional modules:

=over 4

=item * L<Text::CSV>

=item * L<Text::CSV_XS>

=item * L<Text::CSV_PP>

=item * L<Spreadsheet::ParseExcel>

=back

=item * L<JSON>

=item * L<YAML>

=item * L<HTML::TableExtract>

=item * L<Imager>

=back

The following are used by some presets to enhance output, if installed:

=over 4

=item * L<JavaScript::Minifier>

=item * L<Color::Spectrum>

=back

=head1 SEE ALSO

=over 4

=item * L<DBIx::HTML>

Uses this module (Spreadsheet::HTML) to format SQL query results.

=item * L<http://www.w3.org/TR/html5/tabular-data.html>

=item * L<http://en.wikipedia.org/wiki/Rotation_matrix>

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to either

=over 4

=item * Email: C<bug-spreadsheet-html at rt.cpan.org>

=item * Web: L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-HTML>

=back

I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spreadsheet::HTML

The Github project is L<https://github.com/jeffa/Spreadsheet-HTML>

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here) L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spreadsheet-HTML>

=item * AnnoCPAN: Annotated CPAN documentation L<http://annocpan.org/dist/Spreadsheet-HTML>

=item * CPAN Ratings L<http://cpanratings.perl.org/d/Spreadsheet-HTML>

=item * Search CPAN L<http://search.cpan.org/dist/Spreadsheet-HTML/>

=back

=head1 ACKNOWLEDGEMENTS

Thank you very much! :)

=over 4

=item * Neil Bowers

Helped with Makefile.PL suggestions and corrections.

=item * L<Math::Matrix>

Implementation of 2D array transposition.

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2024 Jeff Anderson.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
