package PostScript::Graph::Bar;
our $VERSION = 0.03;
use strict;
use warnings;
use Text::CSV_XS;
use PostScript::File	     1.00 qw(check_file str);
use PostScript::Graph::Key   1.00;
use PostScript::Graph::Paper 1.00;
use PostScript::Graph::Style 1.00;

=head1 NAME

PostScript::Graph::Bar - draw a bar chart on a postscript file

=head1 SYNOPSIS

=head2 Simplest

Take labels and values from a csv file and output as a bar chart on a postscript file.

    use PostScript::Graph::Bar;
    
    my $bar = new PostScript::Graph::Bar();
    $bar->build_chart("survey.csv");
    $bar->output("survey");

=head2 Typical

    use PostScript::Graph::Bar;

    my $bar = new PostScript::Graph::Bar(
	    file   => {
		paper      => 'A4',
		landscape  => 1,
	    },
	    layout => {
		background => [1, 1, 0.9],
		heading    => 'Test results',
	    },
	    y_axis => {
		smallest   => 4,
	    },
	    style  => {
		auto       => [qw(green blue red)],
	    }
	);

    $bar->series_from_file( 'data.csv' );
    $bar->build_chart();
    $bar->output( 'results' );

The file 'data.csv' has a row of headings followed by 4 rows of 10 items.  This
produces a bar chart with four groups of ten bars each.  The groups are labelled
with the first value in each row.  The bars in each group are coloured ranging
from brown through green and then shades of blue.  A Key links the row of
headings to each colour.  In addition, the background is beige, a heading is
placed above the chart and the y axis is not too crowded.

=head2 All options

    use PostScript::Graph::Bar;

    my $bar = new PostScript::Graph::Bar(
	file   => {
	    # Paper size, orientation etc
	    # See PostScript::File
	},
	layout => {
	    # General proportions, headings
	    # See PostScript::Graph::Paper
	},
	x_axis => {
	    # All settings for X axis
	    # See PostScript::Graph::Paper
	},
	y_axis => {
	    # All settings for Y axis
	    # See PostScript::Graph::Paper
	},
	style  => {
	    # Appearance of bars
	    # See PostScript::Graph::Style
	},
	key    => {
	    # Settings for any Key area
	    # See PostScript::Graph::Key
	},
	show_key   => 1,
	labels_row => 1,
    );
    
=head1 DESCRIPTION

This is a top level module in the PostScript::Graph series.  It produces bar charts from CSV files.  There are
three basic variants, depending on the structure of the data.

=head2 Independent values

A CSV file with just a label and a single value on each line produces the most basic form of bar chart.  All the
bars are the same colour, all standing alone.

File 1

    Months,	Sales
    March,	671
    April,	944
    May,	867
    June,	851

If the first entry in the second column cannot be interpreted as a number it is assumed that the first line of
data contains headings for each column.  The first column heading becomes the X axis title and the second column
heading goes into the Key box alongside the colour of the bars.

=head2 Multiple series

The CSV file can have more than one column of values.  The columns for each row are shown as different coloured
bars next to each other.  There is then a gap and data for the next row is displayed using the same sequence of
coloured bars.  The following data would be shown as four groups with two bars in each.  

File 2

    Months, Joe,    Jim
    March,  344,    327
    April,  489,    455
    May,    437,    430
    June,   369,    482

The groups (months) are labelled across the X axis and each comprise a column for Joe and a column for Jim.  A Key
shows which coloured bar represents each salesman.

=head2 Single series

If the CSV file is just a row of numbers, this is interpreted as a single series, so each number is
represented as a different coloured bar, and the bars are adjacent to each other.  A Key shows the labels
associated with each colour.  These can either come from the first line of data or passed as a seperate array.

File 3

    Months, March,  April,  May,    June
    Sales,  671,    1044,   867,    2851

=head2 Additional data

=head3 Series

It is possible to have several B<series_from_file> calls, each adding more data.  The simplest case is where the
labels shown across the X axis (rows in the file) are the same for all data sets.  Each new set just adds an
additional series to the labels.

Example 1

    use PostScript::Graph::Bar;
    my $b = new PostScript::Graph::Bar();

    $b->series_from_file( "joe_sales.csv" );
    $b->series_from_file( "jim_sales.csv" );
    
Each file here would be just two columns like File 1.  But the end result would be the same as for File 2.

=head3 Labels

Data can also be extended by adding more items (labels) within a series.  Care should be taken with this, as any
duplicate data will be overwritten.

File 4

    Months, Joe,    Jim
    July,   392,    404
    August, 401,    438

Example 2

    my $b = new PostScript::Graph::Bar();

    $b->series_from_file( "file_2.csv" );
    $b->series_from_file( "file_4.csv", 0 );
    
The sales data for both Joe and Jim would now cover months March to August.  Note that the C<new_series> flag must
be set to '0' for this behaviour.

=head3 Both

If the C<new_series> flag is not 0, the new data is added as new series, regardless of whether series with the
same name already exist.  It is possible for new labels to be added at the same time.  Of course this means that
some data slots will have no value and these are just set to zero.

File 5

    Months, Fred
    June,   288
    July,   302
    August, 378
    Sept,   421

Example 3

    my $b = new PostScript::Graph::Bar();

    $b->series_from_file( "file_2.csv" );
    $b->series_from_file( "file_4.csv", 0 );
    $b->series_from_file( "file_5.csv" );

The data would now be as follows:

    Months, Joe,    Jim,    Fred
    March,  344,    327,    0
    April,  489,    455,    0
    May,    437,    430,    0
    June,   369,    482,    288    
    July,   392,    404,    302
    August, 401,    438,    378
    Sept,   0,	    0,	    421

=head2 Styles

Each series has a PostScript::Graph::Style object associated with it, managing the colour, outline and so on.
These objects are created with different values by default, and how these vary is controlled by a StyleSequence.
This allows the colours to be controlled as closely (or as loosely) as you like.  Each colour could be set up
seperately as in Example 4, or they could be generated as in Example 5.  See L<PostScript::Graph::Style>
for all the style settings.

Example 4

    use PostScript::Graph::Style;
    my $s1 = new PostScript::Graph::Style(
	    auto => 'none',
	    bar => {
		color => [0.5, 0.2, 0.3],
	    },
	);

Example 5

    use PostScript::Graph::Style;
    my $seq = new StyleSequence;
    $seq->setup('red',   [0.5, 0.9]);
    $seq->setup('green', [0.2, 0.8]);
    $seq->setup('blue',  [0.3]);
    
    my $opts = { sequence => $seq,
		 auto => [ 'red', 'green' ],
		 bar => {} };
    
    my $s1 = new PostScript::Graph::Style($opts);
    my $s2 = new PostScript::Graph::Style($opts);
    my $s3 = new PostScript::Graph::Style($opts);
    my $s4 = new PostScript::Graph::Style($opts);

The fill colour for each style would be as follows.

    $s1	    [0.5, 0.2, 0.3]	a dull dark red
    $s2	    [0.9, 0.2, 0.3]	a bright red
    $s3	    [0.5, 0.8, 0.3]	an orange yellow
    $s4	    [0.9, 0.8, 0.3]	light orange cream

These could then be used to specify colours for each data series added to the chart.

Example 6

    my $b = new PostScript::Graph::Bar();

    $b->series_from_file( "joe.csv",  $s1 );
    $b->series_from_file( "jim.csv",  $s2 );
    $b->series_from_file( "fred.csv", $s3 );
    $b->series_from_file( "alan.csv", $s4 );

=head1 CONSTRUCTOR

=cut

sub new {
    my $class = shift;
    my $opt = {};
    if (@_ == 1) { $opt = $_[0]; } else { %$opt = @_; }
   
    my $o = {};
    bless( $o, $class );

    $o->{opt}   = $opt;
    $opt->{x_axis} = {} unless (defined $opt->{x_axis});
    $opt->{y_axis} = {} unless (defined $opt->{y_axis});

    my $ch = $opt->{chart};
    if (not defined($opt->{style})) {
	$opt->{style} = { 
	    sequence => new PostScript::Graph::Sequence,
	    auto => [qw(red green blue)],
	    bar => {},
	}
    }
    $opt->{style}{bar} = {} unless (defined $opt->{style}{bar});
    
    $o->{key}    = defined($opt->{show_key})         ? $opt->{show_key}           : 1;
    $o->{line1}  = defined($opt->{labels_row})       ? $opt->{labels_row}         : undef;

    $o->build_chart($ch->{data}, $opt->{style}, 1, 1, $ch->{labels}) if ($o->{data});
    
    return $o;
}

=head2 new( [options] )

C<options> can either be a list of hash keys and values or a hash reference, or omitted altogether.  In either
case, the hash is expected to have the same structure.  A couple of the primary keys are simple values but most
point to sub-hashes which hold options or groups themselves.  See the B<All options> section of L</SYNOPSIS> for
the complete structure.

All color options can take either monochrome or colour format values.  If a single number from 0 to 1.0 inclusive,
this is interpreted as a shade of grey, with 0 being black and 1 being white.  Alternatively an array ref holding
three such values is read as holding red, green and blue values - again 1 is the brightest possible value.

    Value	    Interpretation
    =====	    ==============
    0		    black
    0.5		    grey
    1		    white
    [1, 0, 0]	    red
    [0, 1, 0]	    green
    [0, 0, 1]       blue
    [1, 1, 0.9]	    light cream
    [0, 0.8, 0.6]   turquoise

Other numbers are floating point values in PostScript native units (72 per inch).

=head3 file

This may be either a PostScript::File object or a hash ref holding options for it. See
L<PostScript::File> for details.  Options within this group include the paper size, orientation, debugging
features and whether it is an EPS or a normal PostScript file.

=head3 labels_row

Although an attempt is made to automatically detect labels in the top row of each CSV file, it sometimes fails.
Giving a value here forces the module to either use (1) or not use (0) the first row for labels instead of data.
(Default: undefined)

=head3 layout

See L<PostScript::Graph::Paper/layout> for the options controlling how the various parts of the chart are laid out.

=head3 x_axis

See L<PostScript::Graph::Paper/x_axis> for configuring the X axis sizes, font etc.

=head3 y_axis

See L<PostScript::Graph::Paper/y_axis> for configuring the appearance of the Y axis.

=head3 key

See L<PostScript::Graph::Key> for configuring the appearance of the Key showing what the colours mean.

=head3 show_key

If set to 0, the Key is hidden.  (Default: 1)

=head3 style

The settings given here control how the colours for each series are generated.  See L</"Styles"> and
L<PostScript::Graph::Styles> for further information.

=head1 OBJECT METHODS

=cut

sub series_from_array {
    my ($o, $data, @rest) = @_;
    my ($styleopts, $newseries, $keynames);
    foreach my $arg (@rest) {
	CASE: {
	    if (ref($arg) eq "HASH")  { $styleopts = $arg; last CASE; }
	    if (ref($arg) eq "ARRAY") { $keynames  = $arg; last CASE; }
	    $newseries = ($arg != 0);
	}
    }
    die "Array required\nStopped"	unless (defined $data);
    $styleopts = $o->{opt}{style}	unless (defined $styleopts);
    $newseries = 1			unless (defined $newseries);
    $o->{series} = []			unless (defined $o->{series});
    $o->{labels} = []			unless (defined $o->{labels});
    $o->{data}   = {}			unless (defined $o->{data});
    
    ## extract keynames, if any
    my $number = qr/^\s*[-+]?[0-9.]+(?:[Ee][-+]?[0-9.]+)?\s*$/;
    unless (defined $keynames) {
	my $use_line1  = $o->{line1};
	my $is_alpha = ($data->[0][1] !~ $number);
	if (defined $use_line1) {
	    if ($use_line1) {
		$keynames = shift @$data;
		my $xtitle = shift @$keynames;
		$o->{opt}{x_axis}{title} = $xtitle unless (defined $o->{opt}{x_axis}{title});
	    }
	} else {
	    if ($is_alpha) {
		$keynames = shift @$data;
		my $xtitle = shift @$keynames;
		$o->{opt}{x_axis}{title} = $xtitle unless (defined $o->{opt}{x_axis}{title});
	    }
	}
    }
    unless (defined $keynames) {
	$keynames = [];
	for (my $i=1; $i <= $#{$data->[0]}; $i++) {
	    push @$keynames, "";
	}
    }

    ## create a style for each series
    my $nold = @{$o->{series}};
    if ($newseries) {
	for (my $i = 0; $i <= $#$keynames; $i++) {
	    my $style = new PostScript::Graph::Style($styleopts);
	    push @{$o->{series}}, [ $style, $keynames->[$i] ];
	}
    }
    my $nnew = @{$o->{series}};
    
    ## put values into data
    my $d = $o->{data};
    my $l = $o->{labels};
    my %idx;
    for my $label (@{$o->{labels}}) {
	$idx{$label}++;
    }
    ## add (ysa, ysb, ...) to $o->{data}{<label>} array in right position
    foreach my $row (@$data) {
	my $label = shift @$row;
	push @$l, $label unless ($idx{$label});
	if ($newseries) {
	    $d->{$label} = [] unless (defined $d->{$label});
	    my $x = $d->{$label};
	    while (@$x < $nold) { push @$x, 0; };
	    push @$x, @$row;
	} else {
	    my $x = $d->{$label} = [];
	    push @$x, @$row;
	}
    }
    ## fill up any labels without new data
    foreach my $label (@{$o->{labels}}) {
	my $x = $d->{$label};
	while (@$x < $nnew) { push @$x, 0; }
    }
}
## Labels are across x axis, series are multiple bars within each label
# Case 1: $newseries = 1
#   data is pushed onto existing data as new series
#   new labels are filled with 0 for old series values
# Case 2: $newseries = 0
#   data label overwritten if it already exists
#   data contains all series values needed
#
# Data structure - multiple series bars within multiple x axis labels
# $o->{series} = [ [style0, slabel0], 
#                  [style1, slabel1], ... ]
# $o->{labels} = [ xlabel0, xlabel1, ... ]
# $o->{data}   = { xlabel0 => [ ys0, ys1, ... ], 
#		   xlabel1 => [ ys0, ys1, ... ], }

=head2 series_from_array( data [, style | labels | new_series ]... )

=over 8

=item data

An array ref pointing to a list of array refs.  Each sub-array hold the data for one CSV row - a list comprising
one label followed by one or more numbers.

=item style

An optional hash ref.  This should contain settings for the PostScript::Graph::Style objects which will be
associated with each column of data.  If present, the whole hash ref overrides any 'style' hash ref given to
B<new>.

=item labels

An optional array ref.  This list of series names will appear in the Key, replacing the column headings, if given, as
the first data line.

=item new_series

A flag indicating whether the columns constitute new series to be added.  Set to 0 to force merging of data with
existing series of the same name.  (Default: 1)

=back

Add one or more series of data to whatever is already collected.  This can be used in place of
B<series_from_file>, which is merely a useful front end for it.

Example

    my $b = new PostScript::Graph::Bar();
    $b->series_from_array( 
	    [ [ March,  344, 327 ],
	      [ April,  489, 455 ],
	      [ May,    437, 430 ],
	      [ June,   369, 482 ], ],
	    { auto => ['red'] },
	    [ 'Joe', 'Jim' ],
      );

=cut

sub series_from_file {
    my ($o, $file, @rest) = @_;
    my $filename = check_file($file);
    my @data;
    my $csv = new Text::CSV_XS;
    open(INFILE, "<", $filename) or die "Unable to open \'$filename\': $!\nStopped";
    while (<INFILE>) {
	chomp;
	my $ok = $csv->parse($_);
	if ($ok) {
	    my @row = $csv->fields();
	    push @data, [ @row ] if (@row);
	}
    }
    close INFILE;

    $o->series_from_array( \@data, @rest );
}

=head2 series_from_file( file [, style | labels | new_series ]... )

Read in the named CSV file then pass it and any other arguments to B<series_from_array>.

=cut

sub build_chart {
    my $o = shift;
    if (@_) {
	if(ref($_[0]) eq "ARRAY") {
	    $o->series_from_array(@_);
	} else {
	    $o->series_from_file(@_);
	}
    }
    my $oo  = $o->{opt};
    
    ## Identify y axis range
    my ($ymin, $ymax);
    foreach my $label (@{$o->{labels}}) {
	foreach my $y (@{$o->{data}{$label}}) {
	    $ymin = $y if (not defined($ymin) or $y < $ymin);
	    $ymax = $y if (not defined($ymax) or $y > $ymax);
	}
    }
    
    ## Find largest x label
    my $xmaxlen = 0;
    foreach my $label (@{$o->{labels}}) {
	my $len = length($label);
	$xmaxlen = $len if ($len > $xmaxlen);
    }

    ## Find lagest series label for key
    my $smaxlen = 0;
    foreach my $series (@{$o->{series}}) {
	my $len = length($series->[1]);
	$smaxlen = $len if ($len > $smaxlen);
    }
    
    ## Ensure PostScript::File exists
    $oo->{file}   = {} unless (defined $oo->{file});
    my $of        = $o->{opt}{file};
    if (ref($of) eq "PostScript::File") {
	$o->{ps} = $of;
    } else {
	$of->{left}   = 36 unless (defined $of->{left});
	$of->{right}  = 36 unless (defined $of->{right});
	$of->{top}    = 36 unless (defined $of->{top});
	$of->{bottom} = 36 unless (defined $of->{bottom});
	$of->{errors} = 1 unless (defined $of->{errors});
	$o->{ps}      =  new PostScript::File( $of );
    }

    ## Calculate height of GraphPaper y axis
    # used as max_height for GraphKey
    $oo->{layout} = {} unless (defined $oo->{layout});
    my $oc       = $o->{opt}{layout};
    my @bbox     = $o->{ps}->get_page_bounding_box();
    my $bottom   = defined($oc->{bottom_edge})  ? $oc->{bottom_edge}  : $bbox[1]+1;
    my $top      = defined($oc->{top_edge})     ? $oc->{top_edge}     : $bbox[3]-1;
    my $spc      = defined($oc->{spacing})      ? $oc->{spacing}      : 0;
    my $height   = $top - $bottom - 2 * $spc;

    ## Ensure max_height and num_lines are set for GraphKey
    $oo->{key} = {} unless (defined $oo->{key});
    my $ok     = $o->{opt}{key};
    if (defined $ok->{max_height}) {
	$ok->{max_height} = $height if ($ok->{max_height} > $height);
    } else {
	$ok->{max_height} = $height; 
    }
    $ok->{num_items}   = @{$o->{series}};
    my $tsize          = defined($ok->{text_size}) ? $ok->{text_size} : 10;
    $ok->{text_width}  = $smaxlen * $tsize * 0.7;
    $ok->{icon_width}  = $tsize;
    $ok->{icon_height} = $tsize;
    $o->{gk}           = new PostScript::Graph::Key( $ok );
	
    ## Create GraphPaper now key width is known
    my $ox = $oo->{x_axis};
    $oo->{x_axis}{sub_divisions} = @{$o->{series}}+1;
    $oo->{x_axis}{labels}        = [ @{$o->{labels}}, "" ];
    $oo->{y_axis}{low}		 = $ymin unless (defined $oo->{y_axis}{low});
    $oo->{y_axis}{high}		 = $ymax unless (defined $oo->{y_axis}{high});;
    $oo->{file}			 = $o->{ps};
    $oc->{key_width}		 = $o->{key} ? $o->{gk}->width() : 0;
    $o->{gp}			 = new PostScript::Graph::Paper( $oo );

    ## Build Key
    if ($o->{key}) {
	$o->{gk}->build_key( $o->{gp} );
    } else {
	$o->{gk}->ps_functions( $o->{ps} );
    }
    $o->{ps}->add_to_page( <<END_INIT );
	gpaperdict begin
	gstyledict begin
	graphkeydict begin
END_INIT
    
    ## Add the bars
    my $bar = 0;
    my $laststyle = 0;
    my $keydone = 0;
    foreach my $label (@{$o->{labels}}) {
	# draw one series
	my $data = $o->{data}{$label};
	my $i = 0;
	foreach my $series (@{$o->{series}}) {
	    my $style = $series->[0];
	    $style->background( $o->{gp}->layout_background() );
	    $style->write( $o->{ps} );
	    $laststyle = $style;
	    my $y = $data->[$i++];
	    my @bb = $o->{gp}->vertical_bar_area($bar++, $y);
	    my $lwidth = $style->bar_outer_width()/2;
	    $bb[0] += $lwidth;
	    $bb[1] += $lwidth;
	    $bb[2] -= $lwidth;
	    $bb[3] -= $lwidth;
	    $o->{ps}->add_to_page( <<END_BAR );
		$bb[0] $bb[1] $bb[2] $bb[3] bocolor bowidth drawbox
		$bb[0] $bb[1] $bb[2] $bb[3] bicolor bicolor biwidth fillbox
END_BAR
	    unless ($keydone) {
		my $colour = str($style->bar_inner_color());
		$o->{gk}->add_key_item( $series->[1], <<END_KEY_ITEM ) if ($o->{key});
		    kix0 kiy0 kix1 kiy1 bocolor bowidth drawbox
		    kix0 kiy0 kix1 kiy1 bicolor bicolor biwidth fillbox
END_KEY_ITEM
	    }
	}
	$keydone = 1;
	$bar++;
    }

    ## Draw a line at y = 0
    my $y;
    my @gb  = $o->{gp}->graph_area();
    my $ylo = $o->{gp}->y_axis_low();
    my $yhi = $o->{gp}->y_axis_high();
    my $y0  = $o->{gp}->py(0);
    CASE: {
	if ($yhi <= 0)             { $y = $gb[3]; last CASE; }
	if ($ylo < 0 and $yhi > 0) { $y = $y0;    last CASE; }
	if ($ylo >= 0)             { $y = $gb[1]; last CASE; }
    }
    $o->{ps}->add_to_page( <<END_FINISHING );
	    newpath
	    gx0 $y moveto
	    gx1 $y lineto
	    yheavyc gpapercolor stroke
	end end end
END_FINISHING
}

=head2 build_chart([ data | file [, style | labels | new_series ]... ])

The optional arguments are passed direct to B<series_from_array> or B<series_from_file> depending on whether the
first is an array ref.  This just provides a convenient way of providing a single data set.

If a PostScript::File object has not been given to B<new>, it is created along with the
PostScript::Graph::Paper and PostScript::Graph::Key objects.  The postscript code to draw these is generated with
bars and key entries superimposed.

=head1 SUPPORTING METHODS

=cut

sub file { 
    return shift()->{ps}; 
}

=head2 file

Return the underlying PostScript::File object.

=cut

sub graph_key { 
    return shift()->{gk}; 
}

=head2 graph_key

Return the underlying PostScript::Graph::Key object.  Only available after a call to B<build_chart>.

=cut

sub graph_paper { 
    return shift()->{gp}; 
}

=head2 graph_paper

Return the underlying PostScript::Graph::Paper object.  Only available after a call to B<build_chart>.

=cut

sub sequence { 
    return shift()->{opt}{style}{sequence}; 
}

=head2 sequence()

Return the style sequence being used.  This is only required when you wish to alter the ranges used by the auto
style feature.

=cut

sub output { 
    shift()->{ps}->output(@_);
}

=head2 output( file [, dir] )

Output the chart as a file.  See L<PostScript::File/output>.

=cut

sub newpage { 
    shift()->{ps}->newpage(@_);
}

=head2 newpage( [page] )

Start a new page in the underlying PostScript::File object.  See L<PostScript::File/newpage> and
L<PostScript::File/set_page_label>.

=cut

sub add_function {
    shift()->{ps}->add_function(@_); 
}

=head2 add_function( name, code )

Add functions to the underlying PostScript::File object.  See L<PostScript::File/add_function> for details.

=cut

sub add_to_page {
    shift()->{ps}->add_to_page(@_);
}

=head2 add_to_page( [page], code )

Add postscript code to the underlying PostScript::File object.  See L<PostScript::File/add_to_page> for details.

=cut

=head1 BUGS

When reading from a CSV file, the first line is only recognized as a label line if both the first and SECOND
entries are unable to be read as a number.  Putting quotes around them no longer works.

=head1 AUTHOR

Chris Willmot, chris@willmot.co.uk

=head1 SEE ALSO

L<PostScript::File>, L<PostScript::Graph::Style>,  L<PostScript::Graph::Key>, L<PostScript::Graph::Paper>,
L<PostScript::Graph::XY>, L<Finance::Shares::Chart>.

=cut

1;
