package PostScript::Graph::XY;
our $VERSION = 0.04;
use strict;
use warnings;
use Text::CSV_XS;
use PostScript::File	     1.00 qw(check_file array_as_string);
use PostScript::Graph::Key   1.00;
use PostScript::Graph::Paper 1.00;
use PostScript::Graph::Style 1.00;

=head1 NAME

PostScript::Graph::XY - graph lines and points

=head1 SYNOPSIS

=head2 Simplest

Draw a graph from data in the CSV file 'results.csv', and saves it as 'results.ps':
    
    use PostScript::Graph::XY;

    my $xy = new PostScript::Graph::XY();
    $xy->build_chart("results.csv");
    $xy->output("results");
     
=head2 Typical
     
With more direct control:

    use PostScript::Graph::XY;
    use PostScript::Graph::Style;

    my $seq = PostScript::Graph::Sequence;
    $seq->setup('color',
	[ [ 1, 1, 0 ],	    # yellow
	  [ 0, 1, 0 ],	    # green
	  [ 0, 1, 1 ], ],   # cyan
      );
	
    my $xy = new PostScript::Graph::XY(
	    file  => {
		errors    => 1,
		eps       => 0,
		landscape => 1,
		paper     => 'Letter',
	    },
	    
	    layout => {
		dots_per_inch => 72,
		heading       => "Example",
		background    => [ 0.9, 0.9, 1 ],
		heavy_color   => [ 0, 0.2, 0.8 ],
		mid_color     => [ 0, 0.5, 1 ],
		light_color   => [ 0.7, 0.8, 1 ],
	    },
	    
	    x_axis => {
		smallest => 4,
		title    => "Control variable",
		font     => "Courier",
	    },
	    y_axis => {
		smallest => 3,
		title    => "Dependent variable",
		font     => "Courier",
	    },
	    
	    style  => {
		auto  => [qw(color dashes)],
		color => 0,
		line  => {
		    inner_width  => 2,
		    outer_width  => 2.5,
		    outer_dashes => [],
		},
		point => {
		    shape => "circle",
		    size  => 8,
		    color => [ 1, 0, 0 ],
		},
	    },
	    
	    key    => {
		    background => 0.9,
	    },
	);

    $xy->line_from_array(
	[ [ qw(Control First Second Third Fourth),
	    qw(Fifth Sixth Seventh Eighth Nineth)],
	  [ 1, 0, 1, 2, 3, 4, 5, 6, 7, 8 ],
	  [ 2, 1, 2, 3, 4, 5, 6, 7, 8, 9 ],
	  [ 3, 2, 3, 4, 5, 6, 7, 8, 9,10 ],
	  [ 4, 3, 4, 5, 6, 7, 8, 9,10,11 ], ]
	);
    $xy->build_chart();
    $xy->output("controlled");
 
=head2 All options
    
    $xy = new PostScript::Graph::XY(
	file    => {
	    # see PostScript::File
	},
	layout  => {
	    # see PostScript::Graph::Paper
	},
	x_axis  => {
	    # see PostScript::Graph::Paper
	},
	y_axis  => {
	    # see PostScript::Graph::Paper
	},
	style   => {
	    # see PostScript::Graph::Style
	},
	key     => {
	    # see PostScript::Graph::Key
	},
	chart   => {
	    # see 'new' below 
	},
    );
    
=head1 DESCRIPTION

A graph is drawn on a PostScript file from one or more sets of numeric data.  Scales are automatically adjusted
for each data set and the style of lines and points varies between them.  A title, axis labels and a key are also
provided.

=head1 CONSTRUCTOR

=cut

sub new {
    my $class = shift;
    my $opt = {};
    if (@_ == 1) { $opt = $_[0]; } else { %$opt = @_; }
   
    my $o = {};
    bless( $o, $class );
    $o->{opt} = $opt;
    
    $o->{opt}{file}   = {} unless (defined $o->{opt}{file});
    $o->{opt}{layout} = {} unless (defined $o->{opt}{layout});
    $o->{opt}{x_axis} = {} unless (defined $o->{opt}{x_axis});
    $o->{opt}{y_axis} = {} unless (defined $o->{opt}{y_axis});
    $o->{opt}{style}  = {} unless (defined $o->{opt}{style});
    $o->{opt}{key}    = {} unless (defined $o->{opt}{key});
    $o->{opt}{chart}  = {} unless (defined $o->{opt}{chart});

    my $ch = $opt->{chart};
    $o->{points} = defined($ch->{show_points})      ? $ch->{show_points}        : 1;
    $o->{lines}  = defined($ch->{show_lines})       ? $ch->{show_lines}         : 1;
    $o->{key}    = defined($ch->{show_key})         ? $ch->{show_key}           : 1;
    $o->{data}   = defined($ch->{data})             ? $ch->{data}               : undef;

    $o->{opt}{style}{sequence} = new PostScript::Graph::Sequence() unless (defined $o->{opt}{style}{sequence});
    $o->build_chart($o->{data}, $opt->{style}) if ($o->{data});

    return $o;
}

=head2 new( [options] )

C<options> may be either a list of hash keys and values or a hash reference.  Either way, the hash should have the
same structure - made up of keys to several sub-hashes.  Only one (chart) holds options for this module.  The
other sections are passed on to the appropriate module as it is created.

    Hash Key	Module
    ========	======
    file	PostScript::File
    layout	PostScript::Graph::Paper
    x_axis	PostScript::Graph::Paper
    y_axis	PostScript::Graph::Paper
    style	PostScript::Graph::Style
    key		PostScript::Graph::Key
    chart	this one, see below 

=head3 data

This may be either an array or the name of a CSV file.  See B<line_from_array> or B<line_from_file> for details.
If data is given here, the chart is built automatically.  There is no opportunity to add extra lines (they should
be included in this data) but there is no need to call B<build_chart> explicitly as the chart is ready for output.

=head3 show_key

Set to 0 if key panel is not required.  (Default: 1)

=head3 show_lines

Set to 0 to hide lines and make a scatter graph.  (Default: 1)

=head3 show_points

Set to 0 to hide points.  (Default: 1)

All the settings are optional and the defaults work reasonably well.  See the other PostScript manpages for
details of their options.

=head1 OBJECT METHODS

=cut

sub line_from_array {
    my $o = shift;
    my ($data, $style, $opts, $label);
    foreach my $arg (@_) {
	$_ = ref($arg);
	CASE: {
	    if (/ARRAY/)                    { $data  = $arg; last CASE; }
	    if (/HASH/)                     { $opts  = $arg; last CASE; }
	    if (/PostScript::Graph::Style/) { $style = $arg; last CASE; }
	    $label = $arg;
	}
    }
    die "add_line() requires an array\nStopped"  unless (defined $data);
    $o->{ylabel} = $label                        unless (defined $o->{ylabel});
    
    ## create style object
    $opts = $o->{opt}{style}                     unless (defined $opts);
    $opts->{line} = {}				 unless (defined $opts->{line});
    $opts->{point} = {}				 unless (defined $opts->{point});
    $style = new PostScript::Graph::Style($opts) unless (defined $style); 
    
    ## split multi-columns into seperate lines
    my $name = $o->{default}++;
    my ($first, @rest) = split_data($data);
    foreach my $column (@rest) {
	$o->line_from_array($column, $opts);
    }
    
    ## identify axis titles
    $o->{line}{$name}{xtitle} = "";
    my $line = $o->{line}{$name};
    $line->{ytitle} = $label || "";
    $line->{style} = $style;
   
    my $number = qr/^\s*[-+]?[0-9.]+(?:[Ee][-+]?[0-9.]+)?\s*$/;
    unless ($first->[0][1] =~ $number) {
	my $row = shift(@$first);
	$line->{xtitle} = $$row[0];
	$line->{ytitle} = $$row[1];
    }
    $o->{ylabel} = $line->{ytitle} unless (defined $o->{ylabel});
    
    ## find min and max for each axis
    my @coords;
    my ($xmin, $ymin, $xmax, $ymax);
    foreach my $row (@$first) {
	my ($x, $y) = @$row;
	if ($x =~ $number) {
	    $xmin = $x if (not defined($xmin) or $x < $xmin);
	    $xmax = $x if (not defined($xmax) or $x > $xmax);
	}
	if ($y =~ $number) {
	    $ymin = $y if (not defined($ymin) or $y < $ymin);
	    $ymax = $y if (not defined($ymax) or $y > $ymax);
	}
    }
    $line->{data} = $first;
    $line->{last} = 2 * ($#$first + 1) - 1;
    $line->{xmin} = $xmin;
    $line->{xmax} = $xmax;
    $line->{ymin} = $ymin;
    $line->{ymax} = $ymax;
}

=head2 line_from_array( data [, label | opts | style ]... )

=over 8

=item data

An array reference pointing to a list of positions.  

=item label

A string to represent this line in the Key.

=item opts

This should be a hash reference containing keys and values suitable for a PostScript::Graph::Style object.  If present,
the object is created with the options specified.

=item style

It is also acceptable to create a PostScript::Graph::Style object independently and pass that in here.

=back

One or more lines of data is added to the chart.  This may be called many times before the chart is finalized with
B<build_chart>.
      
Each position is the data array contains an x value and one or more y values.  For example, the following points
will be plotted on an x axis from 2 to 4 a y axis including from 49 to 57.

    [ [ 2, 49.7 ],
      [ 3, 53.4 ],
      [ 4. 56.1 ], ]

This will plot three lines with 6 points each.  

    [ ["X", "Y", "Yb", "Yc"],
      [x0, y0, yb0, yc0],
      [x1, y1, yb1, yc1],
      [x2, y2, yb2, yc2],
      [x3, y3, yb3, yc3],
      [x4, y4, yb4, yc4],
      [x5, y5, yb5, yc5], ]

The first line is made up of (x0,y0), (x1,y1)... and these must be there.  The second line comes from (x0,yb0),
(x1,yp1)... and so on.  Optionally, the first row of data in the array may be labels for the X and Y axis, and
then for each line.

Where multiple lines are given, it is best to specify C<label> as an option.  Otherwise it will default to the
name of the first line - rarely what you want.  Of course this is ignored if the B<new> option 'y_axis => title'
was given.

=cut

sub line_from_file {
    my ($o, $file, $style) = @_;
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

    $o->line_from_array( \@data, $style );
}

=head2 line_from_file( file [, label|opts|style ]... )

=over 4

=item C<file>

The name of a CSV file.

=item C<label>

A string to represent this line in the Key.

=item C<opts>

This should be a hash reference containing keys and values suitable for a PostScript::Graph::Style object.  If present,
the object is created with the options specified.

=item C<style>

It is also acceptable to create a PostScript::Graph::Style object independently and pass that in here.

=back

The comma seperated file should contain data in the form:

    x0, y0
    x1, y1
    x2, y2

Optionally, the first line may hold labels.  Any additional columns are interpreted as y-values for additional
lines.  For example:

    Volts, R1k2, R1k8, R2k2
    4.0,   3.33, 2.22, 1.81
    4.5,   3.75, 2.50, 2.04
    5.0,   4.16, 2.78, 2.27
    5.5,   4.58, 3.05, 2.50

Where multiple lines are given, it is best to specify C<label> as an option.  Otherwise it will default to the
name of the first line - rarely what you want.  Of course the B<new> option 'y_axis => title' takes precedence
over both.

Note that the headings have to begin with a non-digit in order to be recognized as such.

=cut


sub split_data {
    my $data = shift;
    return ([[0, 0]]) unless (ref($data) eq "ARRAY");
    my @res;
    foreach my $row (@$data) {
	if (ref($row) eq "ARRAY") {
	    my ($x, @rest) = @$row;
	    for (my $i = 0; $i <= $#rest; $i++) {
		$res[$i] = [] unless (defined $res[$i]);
		push @{$res[$i]}, [ $x, $rest[$i] ];
	    }
	}
    }
    return @res;
}
# Internal function
# Splits array data of the form 
# [ [x1, a1, b1, c1],
#   [x2, a2, b2, c2], ]
# to an array holding several arrays of (x,y) points
# [ [ [x1, a1], [x2, a2] ],
#   [ [x1, b1], [x2, b2] ],
#   [ [x1, c1], [x2, c2] ], ]

sub build_chart {
    my $o = shift;
    if (@_) {
	if(ref($_[0]) eq "ARRAY") {
	    $o->line_from_array(@_);
	} else {
	    $o->line_from_file(@_);
	}
    }

    ## Define {opt} hash refs
    my ($first, @rest) = sort keys( %{$o->{line}} );
    my $oo  = $o->{opt};
    $oo->{x_axis} = {} unless (defined $oo->{x_axis});
    my $ox        = $o->{opt}{x_axis};
    $oo->{y_axis} = {} unless (defined $oo->{y_axis});
    my $oy        = $o->{opt}{y_axis};
    
    ## Examine all lines for extent of x & y axes and label lengths
    my ($xmin, $ymin, $xmax, $ymax, $xtitle, $ytitle);
    my $maxlen  = 0;
    my $lines   = 0;
    my $lwidth  = 3;
    my $maxsize = 0;
    foreach my $name ($first, @rest) {
	my $line     = $o->{line}{$name};
	my $style    = $line->{style};
	my $lw       = $style->line_outer_width();
	my $size     = $style->point_size() + $lwidth;
	$maxsize     = $size if ($size > $maxsize);
	$lwidth      = $lw/2 if ($lw/2 > $lwidth);
	$xmin        = $line->{xmin} if (not defined($xmin) or $line->{xmin} < $xmin);
	$xmax        = $line->{xmax} if (not defined($xmax) or $line->{xmax} > $xmax);
	$ymin        = $line->{ymin} if (not defined($ymin) or $line->{ymin} < $ymin);
	$ymax        = $line->{ymax} if (not defined($ymax) or $line->{ymax} > $ymax);
	$ox->{title} = $line->{xtitle} unless (defined $ox->{title});
	$oy->{title} = $o->{ylabel} unless (defined $oy->{title});
	my $len      = length($line->{ytitle});
	$maxlen      = $len if ($len > $maxlen);
	$lines++;
    }
    $ox->{low}  = $xmin;
    $ox->{high} = $xmax;
    $oy->{low}  = $ymin;
    $oy->{high} = $ymax;
   
    ## Ensure PostScript::File exists
    $oo->{file}   = {} unless (defined $oo->{file});
    my $of        = $o->{opt}{file};
    $of->{left}   = 36 unless (defined $of->{left});
    $of->{right}  = 36 unless (defined $of->{right});
    $of->{top}    = 36 unless (defined $of->{top});
    $of->{bottom} = 36 unless (defined $of->{bottom});
    $of->{errors} = 1 unless (defined $of->{errors});
    $o->{ps}      = (ref($of) eq "PostScript::File") ? $of : new PostScript::File( $of );

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
    if ($o->{key}) {
	$oo->{key} = {} unless (defined $oo->{key});
	my $ok     = $o->{opt}{key};
	if (defined $ok->{max_height}) {
	    $ok->{max_height} = $height if ($ok->{max_height} > $height);
	} else {
	    $ok->{max_height} = $height; 
	}
	$ok->{num_items}   = $lines;
	my $tsize          = defined($ok->{text_size}) ? $ok->{text_size} : 10;
	$ok->{text_width}  = $maxlen * $tsize * 0.7;
	$ok->{icon_width}  = $maxsize * 3;
	$ok->{icon_height} = $maxsize * 1.5;
	$ok->{spacing}     = $lwidth;
	$o->{gk}           = new PostScript::Graph::Key( $ok );
    }
	
    ## Create GraphPaper now key width is known
    $oo->{file}      = $o->{ps};
    $oc->{key_width} = $o->{key} ? $o->{gk}->width() : 0;
    $o->{gp}         = new PostScript::Graph::Paper( $oo );

    ## Add in lines and key details
    PostScript::Graph::XY->ps_functions( $o->{ps} );
    $o->{gk}->build_key( $o->{gp} ) if ($o->{key});
    $o->{ps}->add_to_page( <<END_INTRO );
	gpaperdict begin 
	gstyledict begin 
	xychartdict begin
END_INTRO
    my $linenum = 1;
    foreach my $name ($first, @rest) {

	## construct point data
	my $line = $o->{line}{$name};
	my $points = "";
	foreach my $row (@{$line->{data}}) {
	    my ($x, $y) = @$row;
	    my $px = $o->{gp}->px($x);
	    my $py = $o->{gp}->py($y);
	    $points = "$px $py " . $points;
	}
	# set style
	my $style = $line->{style};
	$style->background( $o->{gp}->layout_background() );
	$style->write( $o->{ps} );
	
	## prepare code for points and lines
	my ($cmd, $keylines, $keyouter, $keyinner);
	CASE: {
	    if (    $o->{points} and     $o->{lines}) {
		$cmd = "xyboth";
		$keyouter = "point_outer kpx kpy draw1point";
		$keylines = "[ kix0 kiy0 kix1 kiy1 ] 3 2 copy line_outer drawxyline line_inner drawxyline";
		$keyinner = "point_inner kpx kpy draw1point";
	    }
	    if (    $o->{points} and not $o->{lines}) {
		$cmd = "xypoints";
		$keyouter = "point_outer kpx kpy draw1point";
		$keylines = "";
		$keyinner = "point_inner kpx kpy draw1point";
	    }
	    if (not $o->{points} and     $o->{lines}) {
		$cmd = "xyline";
		$keyouter = "";
		$keylines = "[ kix0 kiy0 kix1 kiy1 ] 3 2 copy line_outer drawxyline line_inner drawxyline";
		$keyinner = "";
	    }
	    if (not $o->{points} and not $o->{lines}) {
		$cmd = "";
		$keyouter = "";
		$keylines = "";
		$keyinner = "";
	    }
	}
	
	## write graph and key code
	if ($cmd) {
	    $o->{ps}->add_to_page( "[ $points ] $line->{last} $cmd\n" );
	    $o->{gk}->add_key_item( $line->{ytitle}, <<END_KEY_ITEM ) if ($o->{key});
		2 dict begin
		    /kpx kix0 kix1 add 2 div def
		    /kpy kiy0 kiy1 add 2 div def
		    $keyouter
		    $keylines
		    $keyinner
		end
END_KEY_ITEM
	}
    }
    $o->{ps}->add_to_page( "end end end\n" );
}

=head2 build_chart([ file | data [, label | opts | style ]... ])

=over 8

=item data

An array reference pointing to a list of positions.  See L</line_from_array>.

=item file

The name of a CSV file.  See L</"line_from_file">.  

=item label

A string to represent this line in the Key.

=item opts

This should be a hash reference containing keys and values suitable for a PostScript::Graph::Style object.  If present,
the object is created with the options specified.

=item style

It is also acceptable to create a PostScript::Graph::Style object independently and pass that in here.

=back

If the first parameter is an array they are all passed to B<line_from_array>, otherwise if there are any
parameters they are passed to B<line_from_file>.  With no parameters, either of these two functions must have
already been called.

This method then calculates the scales from the data collected, draws the graph paper, puts the lines on it
and adds a key.

=cut

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

=head1 CLASS METHODS

The PostScript functions are provided as a class method so they are available to modules not needing an XY object.

=cut

sub ps_functions {
    my ($class, $ps) = @_;
    my $name = "XYChart";
    # dict entries: style fns=7, style code=19, here=6
    $ps->add_function( $name, <<END_FUNCTIONS ) unless ($ps->has_function($name));
	/xychartdict 35 dict def
	xychartdict begin
	    % _ coords_array last => _
	    /drawxyline {
		xychartdict begin
		    /idx exch def
		    /linearray exch def
		    /y linearray idx get def
		    /idx idx 1 sub def
		    /x linearray idx get def
		    /idx idx 1 sub def
		    newpath
		    x y moveto
		    {
			idx 0 le { exit } if
			/y linearray idx get def
			/idx idx 1 sub def
			/x linearray idx get def
			/idx idx 1 sub def
			x y lineto
		    } loop
		    stroke
		end
	    } bind def
	    
	    % x y => 0
	    % ppshape should be one of the make_ Style functions
	    /draw1point {
		xychartdict begin
		    gsave
			ppshape
			gsave stroke grestore
			eofill
		    grestore
		end
	    } bind def
	    
	    % _ coords_array last => _
	    /drawxypoints {
		xychartdict begin
		    /idx exch def
		    /linearray exch def
		    /y linearray idx get def
		    /idx idx 1 sub def
		    /x linearray idx get def
		    /idx idx 1 sub def
		    x y draw1point
		    {
			idx 0 le { exit } if
			/y linearray idx get def
			/idx idx 1 sub def
			/x linearray idx get def
			/idx idx 1 sub def
			x y draw1point
		    } loop
		end
	    } bind def
	    
	    % _ coords_array last => _
	    /xyboth {
		xychartdict begin
		    2 copy point_outer drawxypoints
		    2 copy line_outer drawxyline
		    2 copy line_inner drawxyline
		    point_inner drawxypoints
		end
	    } bind def
		
	    % _ coords_array last => _
	    /xyline {
		xychartdict begin
		    2 copy line_outer drawxyline
		    line_inner drawxyline
		end
	    } bind def
		    
	    % _ coords_array last => _
	    /xypoints {
		xychartdict begin
		    2 copy point_outer drawxypoints
		    point_inner drawxypoints
		end
	    } bind def
	    
	end
END_FUNCTIONS
}

=head1 BUGS

This is still alpha software. It has only been tested in limited, predictable conditions and the interface is
subject to change.

=head1 AUTHOR

Chris Willmot, chris@willmot.org.uk

=head1 SEE ALSO

L<PostScript::File>, L<PostScript::Graph::Style>,  L<PostScript::Graph::Key>, L<PostScript::Graph::Paper>,
L<PostScript::Graph::Bar>, L<Finance::Shares::Chart>.

=cut


1;
