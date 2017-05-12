package PostScript::Graph::Paper;
our $VERSION = 1.01;
use strict;
use warnings;
use PostScript::File 1.00 qw(check_file array_as_string str);

# bit values for flags
our $fl_bar    = 1;
our $fl_rotate = 2;
our $fl_center = 4;
our $fl_offset = 8;
our $fl_show   = 16;

=head1 NAME

PostScript::Graph::Paper - prepare blank graph for a postscript file

=head1 SYNOPSIS

=head2 Simplest

Let the module create its own postscript file:
 
    use PostScript::Graph::Paper;
    
    my $pg = new PostScript::Graph::Paper( 
	    file => { landscape => 1 },
	    layout => { title => "Blank grid" } );
		
    $pg->output("testfile");

=head2 Typical
    
Add the chart to an existing postscript file:
 
    use PostScript::Graph::Paper;
    use PostScript::File;
    
    my $ps = new PostScript::File( 
			left      => 40,
			right     => 40,
			top       => 30,
			bottom	  => 30,
			landscape => 1,
			errors    => 1 );
	
    new PostScript::Graph::Paper(
	  file   => $ps,
	  layout => { title => 
			"Experimental results" },
	  x_axis => { high  => 10,
		      title => 
			"Control variable" },
	  y_axis => { low   => 23.6, 
		      high  => 24.95,
		      title => 
			"Dependent variable" });
		    
    $ps->output("testfile");

Create a bar chart layout:

    use PostScript::Graph::Paper;

    new PostScript::Graph::Paper(
	  layout  => { title => 
			"Survey" },
	  x_axis => { labels => [
		"Men", "Women", 
		"Boys", "Girls", ], },
	  y_axis => { low  => 8, 
		      high => 37, } );
		    
    $ps->output("testfile");

=head2 All options
    
    new PostScript::Graph::Paper(
	file => $ps_file,
	
	layout => {
	    bottom_edge	    => 30,
	    top_edge	    => 30,
	    left_edge	    => 30,
	    right_edge	    => 30,
	    spacing	    => 4,
	    top_margin	    => 10,
	    right_margin    => 10,
	    key_width	    => 0,
	    sub_divisions   => 4,
	    dots_per_inch   => 600,
	    font	    => 'Helvetica',
	    font_color	    => 0,
	    font_size	    => 10,
	    heading	    => 'My Graph',
	    heading_font    => 'Times-Bold',
	    heading_font_color => 0.9,
	    heading_font_size => 20,
	    heading_height  => 30,
	    background	    => [ 0.9, 0.95, 0.85 ],
	    color	    => [ 0, 0, 0.7 ],
	    heavy_color	    => [0, 0, 0.4],
	    mid_color	    => [0.6, 0.6, 1],
	    light_color	    => 0.8,
	    heavy_width	    => 1,
	    mid_width	    => 0.8,
	    light_width	    => 0.25,
	    no_drawing      => 0,
	},

	x_axis => {
	    low		=> 74.25,
	    high	=> 74.9,
	    width	=> 200,
	    height	=> 450,
	    label_gap	=> 50,
	    labels	=> [qw(this that other)],
	    labels_req	=> 7,
	    font	=> 'Helvetica',
	    font_color	=> 0,
	    font_size	=> 10,
	    title	=> 'X axis',
	    color	=> 0.5,
	    heavy_color	=> [0, 0, 0.4],
	    mid_color	=> [0.6, 0.6, 1],
	    light_color => 0.8,
	    heavy_width => 1,
	    mid_width	=> 0.8,
	    light_width => 0.25,
	    mark_min	=> 2,
	    mark_max	=> 8,
	    smallest	=> 8,
	    center	=> 1,
	    offset	=> 1,
	    rotate	=> 1,
	    draw_fn     => "myxdraw",
	},

	y_axis => {
	    # as x_axis
	},
    );

=head1 DESCRIPTION

This module is designed as a supporting part of the PostScript::Graph suite.  For top level modules that output
something useful, see

    PostScript::Graph::Bar
    PostScript::Graph::Stock
    PostScript::Graph::XY

An area of graph paper is created on a postscript page.  X and Y axes are labelled and there are facilities to add
a title and key.  This is written to a PostScript::File object (automatically created if not supplied)
which can then be output.  It is intended to be a static object - once the parameters are set there is little
point in changing them - so all options are set in the contructor.
   
=head1 CONSTRUCTOR

=cut

sub new {
    my $class = shift;
    my $opt = {};
    if (@_ == 1) {
	$opt = $_[0];
    } else {
	%$opt = @_;
    }
   
    my $o = {};
    bless( $o, $class );
    
    ## note or initialize PostScript::File object
    if (ref($opt->{file}) eq "PostScript::File") {
	$o->{ps} = $opt->{file};
    } else {
	my $fileopts = (defined $opt->{file}) ? $opt->{file} : {};
	$fileopts->{left}   = 36 unless (defined $fileopts->{left});
	$fileopts->{right}  = 36 unless (defined $fileopts->{right});
	$fileopts->{top}    = 36 unless (defined $fileopts->{top});
	$fileopts->{bottom} = 36 unless (defined $fileopts->{bottom});
	$fileopts->{errors} = 1 unless (defined $fileopts->{errors});
	$o->{ps} = new PostScript::File($fileopts);
    }

    ## handle options
    $o->init_layout($opt);
    $o->init_scale_options("x", $opt->{x_axis});
    $o->init_scale_options("y", $opt->{y_axis});
    
    if (defined $o->{x}{labels}) {
	$o->init_bars("x", $opt->{x_axis});
    } else {
	$o->init_scale("x", $opt->{x_axis});
    }
    if (defined $o->{y}{labels}) {
	$o->init_bars("y", $opt->{y_axis});
    } else {
	$o->init_scale("y", $opt->{y_axis});
    }
    
    PostScript::Graph::Paper->ps_functions($o->{ps});
    $o->draw_scales() unless ($opt->{layout}{no_drawing});
    
    return $o;
}

=head2 new( [options] )

The labelling and layout of the graph is quite flexible, but that level of control inevitably requires many
options.  If no options are given, graph paper labelled 0 to 100 along each axis fills an A4 page (apart from
a half-inch border all round).  It is up to the user how much this is altered.  Either labels or high and low
values will probably need to be given for each axis, with titles, a heading and perhaps some space for
a key.

C<options> can either be a list of hash keys and values or a hash reference.  In either case, the hash is expected
to have the same structure.  There are a few primary keys, each of which point to sub-hashes which hold options for
that group.

For every option listed here there is a corresponding function returning its value.  For example, the label
printed at the top of the y axis is set with the option C<x_axis => { title => '...' }>.  C<x_axis_title()> would
return the string given and the option would be documented as C<axis_title>.

Example 1

    my $gp = new PostScript::Graph::Paper(
	    layout  => {
		title  => "Bar chart",
		right_edge => 500,
		key_width  => 100,
	    },
	    x_axis => {
		labels => [ "First bar",
			    "Second bar",
			    "Third bar" ],
	    },
	    y_axis => {
		low    => 123,
		high   => 456.7,
		title  => "Readings",
	    },
	);

    This would prepare graph paper for a
    bar chart with 3 vertical bars and a key.

Example 2
    
    my $gp = new PostScript::Graph::Paper(
	    file => {
		landscape => 1,
		errors => 1,
	    },
	    layout => {
		font_color => 1,
		heading_height => 0,
		left_axis_font_size => 0,
		bottom_axis_height => 0,
		left_axis_width => 0,
		mark_min => 0,
		mark_max => 0,
	    },
	    x_axis => {
		smallest => 72,
	    },
	    y_axis => {
		smallest => 72,
	    },
	);
    
    This fills an A4 page with a plain grid of
    squares no smaller than 1 inch big, with 
    no axes, marks, labels, heading or key.

=cut

sub file { 
    return shift()->{ps}; 
}

=head2 PostScript Options

The PostScript::File object which recieves the grid may either be an existing one or the module can create one for
you.  Use C<file> to declare a pre-existing object, or C<file> to control how the new one is created.

=head3 file

This may be either a PostScript::File object or a options in hash key/value format.  If options are given, a new
PostScript::File object is created.

    Example 1

    $psf = new PostScript::File();
    
    $pg  = new PostScript::Graph::Paper(
		file => $psf );

    Then $psf == $pg->file();

    Example 2
    
    my $ch = new PostScript::Graph::Paper(
		file => {
		    landscape => 1,
		    clipping => 1,
		    clipcmd => "stroke",
		    debug => 2,
		    errors => 1,
		} );

=cut

### Chart options

 sub layout_left_edge        { shift()->{ch}{left}; }
 sub layout_bottom_edge      { shift()->{ch}{bottom}; }
 sub layout_right_edge       { shift()->{ch}{right}; }
 sub layout_top_edge         { shift()->{ch}{top}; }
 sub layout_right_margin     { shift()->{ch}{rmargin}; }
 sub layout_top_margin       { shift()->{ch}{tmargin}; }
 sub layout_spacing          { shift()->{ch}{spc}; }
 sub layout_dots_per_inch    { shift()->{ch}{dpi}; }
 sub layout_heading          { shift()->{ch}{title}; }
 sub layout_heading_height   { shift()->{ch}{head}; }
 sub layout_key_width        { shift()->{ch}{keyw}; }
 sub layout_background       { color_as_array( shift()->{ch}{bgnd} ); }
 sub layout_color            { color_as_array( shift()->{ch}{color} ); }
 sub layout_heavy_color      { color_as_array( shift()->{ch}{heavycol} ); }
 sub layout_mid_color        { color_as_array( shift()->{ch}{midcol} ); }
 sub layout_light_color      { color_as_array( shift()->{ch}{lightcol} ); }
 sub layout_heavy_width      { shift()->{ch}{heavyw}; }
 sub layout_mid_width        { shift()->{ch}{midw}; }
 sub layout_light_width      { shift()->{ch}{lightw}; }
 sub layout_font             { shift()->{ch}{font}; }
 sub layout_font_size        { shift()->{ch}{fontsize}; }
 sub layout_font_color       { color_as_array( shift()->{ch}{fontcol} ); }
 sub layout_heading_font     { shift()->{ch}{hfont}; }
 sub layout_heading_font_size { shift()->{ch}{hsize}; }
 sub layout_heading_font_color { color_as_array( shift()->{ch}{hcol} ); }

=head2 Chart Options

These are all set within a C<layout> option given to the constructor.  Remove the initial C<layout_> to get the
option name.  All values are in PostScript native units (72 = 1 inch).

    Example

    $pg = new PostScript::Graph::Paper(
	    layout => { right_edge   => 600, 
			heavy_color  => [0, 0, 0.8],
			light_color  => 0.6,
			font         => "Courier",
			title_font_size => 14,
			right_margin => 20,
			spacing	     => 4 } );

    $pg->layout_font() would return "Courier".
		    
=head3 layout_bottom_edge

The bottom boundary of the whole chart area.

=head3 layout_background

Background color.

=head3 layout_color

Default colour for all grid lines.  All colours can be either a greyscale value or an array of RGB values.  All
values vary from 0 = black to 1 = brightest.  (Default: 0.5)

    Example

    layout => {	background  => [ 0.95, 0.95, 0.85 ],
		color	    => [ 0, 0.2, 0.8 ],
		light_color => 0.85 }

    Grid lines will be a blue shade on a beige background, 
    except the lightest lines which will be light grey.

=head3 layout_dots_per_inch

Marks are spaced at a multiple of this value.  If this does not match the physical output device, the appearance
can be somewhat ragged.  (Default: 300)

=head3 layout_font

Default font for everything except titles.  (Default: "Helvetica")

=head3 layout_font_color

Default colour for all fonts.  (Default: 0)

=head3 layout_font_size

Default font size for everything except the title font.  (Default: 10)

=head3 layout_heading

The title above the grid.  (Default: "")

=head3 layout_heading_font

Font for the main heading above the graph.  (Default: "Helvetica-Bold")

=head3 layout_heading_font_color

Colour for main heading.  (Defaults to C<font_color>)

=head3 layout_heading_font_size

Size for main heading.  (Default: 12)

=head3 layout_heading_height

Size of area above the graph holding the main title and the y axis title.  (Defaults to just enough space)

=head3 layout_heavy_color

The colour of the major, labelled, lines.  (Defaults to C<color>)

=head3 layout_heavy_width

Width of the labelled lines.  (Default: 0.75)

=head3 layout_key_width

Width of box at the right of the graph, allocated for the key.  If this is 0, no key box is drawn.  (Default: 0)

The key is drawn by a seperate PostScript::Graph::Key object.  This merely allocates space within the chart edges.

=head3 layout_left_edge

The left boundary of the whole paper area.

=head3 layout_light_color

Colour of the minor, unlabelled, lines. (Defaults to C<color>)

=head3 layout_light_width

Width of the lightest lines.  (Default: 0.25)

=head3 layout_mid_color

A scale of 10 will be divided into two lots of 5 seperated by a slightly heavier line at the 5 mark.  This is the
'mid' line.  (Defaults to C<color>)

=head3 layout_mid_width

Width of the mid-lines, see </mid_color>.  (Default: 0.75)

=head3 no_drawing

If true, the call to C<draw_scales> is not carried out in the constructor, allowing some tinkering with labels
etc. before comitting to postscript.  The only way to do this is to access the objects data directly.  Use with
caution.  (Default: 0)

=head3 layout_right_edge

The right boundary of the whole chart area.

=head3 layout_right_margin

Space at the right hand side of the graph area, taken up by part of the last label.  (Default: 15)

=head3 layout_spacing

Increasing this value seperates out the various parts of the chart, like leading added to text.  (Default: 0)

=head3 layout_sub_divisons

Used by PostScript::Graph::Bar to signal the number of series per label.  Not appropriate for anything else.

=head3 layout_top_edge

The top boundary of the whole chart area.

=head3 layout_top_margin

Space above the graph area taken up by part of the topmost y label.  (Default: 5)

=cut

sub init_layout {
    my ($o, $opt) = @_;
    $opt->{layout} = {} unless (defined $opt->{layout});
    my $r = $opt->{layout};
    $o->{ch}{left} = 0;
    my $ch = $o->{ch};

    my $ps          = $o->{ps};
    my @bbox        = $ps->get_page_bounding_box();
    $ch->{left}     = defined($r->{left_edge})              ? $r->{left_edge}              : $bbox[0]+1;
    $ch->{bottom}   = defined($r->{bottom_edge})            ? $r->{bottom_edge}            : $bbox[1]+1;
    $ch->{right}    = defined($r->{right_edge})             ? $r->{right_edge}             : $bbox[2]-1;
    $ch->{top}      = defined($r->{top_edge})               ? $r->{top_edge}               : $bbox[3]-1;
    $ch->{tmargin}  = defined($r->{top_margin})             ? $r->{top_margin}             : 5;
    $ch->{rmargin}  = defined($r->{right_margin})           ? $r->{right_margin}           : 15;
    $ch->{bottom}   = defined($r->{bottom_edge})            ? $r->{bottom_edge}            : $bbox[1]+1;
    $ch->{spc}      = defined($r->{spacing})                ? $r->{spacing}                : 0;
    $ch->{dpi}      = defined($r->{dots_per_inch})          ? $r->{dots_per_inch}          : 300;
    
    $ch->{color}    = defined($r->{color})                  ? str($r->{color})             : 0.5;
    $ch->{fgnd}     = defined($r->{outline})                ? str($r->{outline})           : 0;
    $ch->{bgnd}     = defined($r->{background})             ? str($r->{background})        : 1;
    $ch->{heavycol} = defined($r->{heavy_color})            ? str($r->{heavy_color})       : $ch->{color};
    $ch->{midcol}   = defined($r->{mid_color})              ? str($r->{mid_color})         : $ch->{color};
    $ch->{lightcol} = defined($r->{light_color})            ? str($r->{light_color})       : $ch->{color};
    $ch->{heavyw}   = defined($r->{heavy_width})            ? str($r->{heavy_width})       : 0.75;
    $ch->{midw}     = defined($r->{mid_width})              ? $r->{mid_width}              : 0.5;
    $ch->{lightw}   = defined($r->{light_width})            ? $r->{light_width}            : 0.25;

    $ch->{font}     = defined($r->{font})                   ? $r->{font}                   : "Helvetica";
    $ch->{fontsize} = defined($r->{font_size})              ? $r->{font_size}              : 10;
    $ch->{fontcol}  = defined($r->{font_color})             ? str($r->{font_color})        : 0;
    $ch->{hfont}    = defined($r->{heading_font})           ? $r->{heading_font}           : "Helvetica-Bold";
    $ch->{hsize}    = defined($r->{heading_font_size})      ? $r->{heading_font_size}      : 12;
    $ch->{hcol}     = defined($r->{heading_font_color})     ? str($r->{heading_font_color}) : $ch->{fontcol};
    $ch->{title}    = defined($r->{heading})                ? $r->{heading}                : "";

    $o->init_scale_sizes("y", $opt->{"y_axis"});
    
    # both y axis and key block are full height
    $ch->{yx0}      = $ch->{left}   + $ch->{spc};
    $ch->{yx1}      = $ch->{yx0}    + $o->{y}{width};
    $ch->{yy0}      = $ch->{bottom} + $ch->{spc};
    $ch->{yy1}      = $ch->{top}    - $ch->{spc};
    
    $ch->{keyw}     = defined($r->{key_width})              ? $r->{key_width}              : 0;
   
    # heading and x axis fit within side borders
    $o->init_scale_sizes("x", $opt->{"x_axis"});  # x width depends on y width and key width
    
    $ch->{head}     = defined($r->{heading_height})         ? $r->{heading_height}         : $ch->{hsize};
    $ch->{head}    += 1.5 * $o->{y}{fsize};		    # y label goes in heading space 
    $ch->{hx0}      = $ch->{yx1};
    $ch->{hx1}      = $ch->{yx1} + $o->{x}{width};
    $ch->{hy1}      = $ch->{top} - $ch->{spc};
    $ch->{hy0}      = $ch->{hy1} - $ch->{head} - $ch->{spc};

    $ch->{xx0}      = $ch->{yx1};
    $ch->{xx1}      = $ch->{hx1};
    $ch->{xy0}      = $ch->{bottom} + $ch->{spc};
    $ch->{xy1}      = $ch->{xy0} + $o->{x}{height};
    
    # graph area
    $ch->{gx0}      = $ch->{xx0};
    $ch->{gy0}      = $ch->{xy1};
    $ch->{gx1}      = $ch->{xx1};
    $ch->{gy1}      = $ch->{hy0} - $ch->{tmargin} - $ch->{spc};
} 
# Internal method, intializing whole chart area

### Axis options

 sub x_axis_color	    { color_as_array( shift()->{x}{color} ); }
 sub x_axis_low		    { shift()->{x}{llo}; }
 sub x_axis_high	    { shift()->{x}{lhi}; }
 sub x_axis_width	    { shift()->{x}{width}; }
 sub x_axis_height	    { shift()->{x}{height}; }
 sub x_axis_label_gap	    { shift()->{x}{labelgap}; }
 sub x_axis_si_shift	    { shift()->{x}{si}; }
 sub x_axis_smallest	    { shift()->{x}{smallest}; }
 sub x_axis_title	    { shift()->{x}{title}; }
 sub x_axis_font	    { shift()->{x}{font}; }
 sub x_axis_font_color	    { shift()->{x}{fcol}; }
 sub x_axis_font_size	    { shift()->{x}{fsize}; }
 sub x_axis_heavy_color	    { color_as_array( shift()->{x}{heavycol} ); }
 sub x_axis_mid_color	    { color_as_array( shift()->{x}{midcol} ); }
 sub x_axis_light_color	    { color_as_array( shift()->{x}{lightcol} ); }
 sub x_axis_heavy_width	    { shift()->{x}{heavyw}; }
 sub x_axis_mid_width	    { shift()->{x}{midw}; }
 sub x_axis_light_width	    { shift()->{x}{lightw}; }
 sub x_axis_mark_min	    { shift()->{x}{markmin}; }
 sub x_axis_mark_max	    { shift()->{x}{markmax}; }
 sub x_axis_mark_gap	    { shift()->{x}{markgap}; }
 sub x_axis_labels_req	    { shift()->{x}{labsreq}; }
 sub x_axis_rotate	    { shift()->{x}{rotate} != 0; }
 sub x_axis_center	    { shift()->{x}{center} != 0; }
 sub x_axis_show_lines	    { shift()->{x}{show}; }
 sub y_axis_color	    { color_as_array( shift()->{y}{color} ); }
 sub y_axis_low		    { shift()->{y}{llo}; }
 sub y_axis_high	    { shift()->{y}{lhi}; }
 sub y_axis_width	    { shift()->{y}{width}; }
 sub y_axis_height	    { shift()->{y}{height}; }
 sub y_axis_label_gap	    { shift()->{y}{labelgap}; }
 sub y_axis_si_shift	    { shift()->{y}{si}; }
 sub y_axis_smallest	    { shift()->{y}{smallest}; }
 sub y_axis_title	    { shift()->{y}{title}; }
 sub y_axis_font	    { shift()->{y}{font}; }
 sub y_axis_font_color	    { shift()->{y}{fcol}; }
 sub y_axis_font_size	    { shift()->{y}{fsize}; }
 sub y_axis_heavy_color	    { color_as_array( shift()->{y}{heavycol} ); }
 sub y_axis_mid_color	    { color_as_array( shift()->{y}{midcol} ); }
 sub y_axis_light_color	    { color_as_array( shift()->{y}{lightcol} ); }
 sub y_axis_heavy_width	    { shift()->{y}{heavyw}; }
 sub y_axis_mid_width	    { shift()->{y}{midw}; }
 sub y_axis_light_width	    { shift()->{y}{lightw}; }
 sub y_axis_mark_min	    { shift()->{y}{markmin}; }
 sub y_axis_mark_max	    { shift()->{y}{markmax}; }
 sub y_axis_mark_gap	    { shift()->{y}{markgap}; }
 sub y_axis_labels_req	    { shift()->{y}{labsreq}; }
 sub y_axis_rotate	    { shift()->{y}{rotate} != 0; }
 sub y_axis_center	    { shift()->{y}{center} != 0; }
 sub y_axis_show_lines	    { shift()->{y}{show}; }

=head2 Axis Options

The C<axis_> entries below refer to four things: x_axis and y_axis options and x_axis_ and y_axis_ functions
which return those values.  Remove the C<axis_> prefix to get the option name, and prepend C<x_> or C<y_> to get
the relevant function name.  The options belong within hashes indexed by either C<x_axis> or C<y_axis>.

    Example

    Options documentated as:

	axis_low
	axis_high
	
    Would be set by:
    
    $pg  = new PostScript::Graph::Paper(
	    x_axis => { low => 1,
			high => 12,
		      },
	    y_axis => { low => 247,
			high => 980,
		      } );

    And inspected by:
    
	$pg->x_axis_low()  == 1
	$pg->x_axis_high() == 14
	$pg->y_axis_low()  == 200
	$pg->y_axis_high() == 1000

    Note that the original values have been 
    adjusted as the scales were calculated.

=head3 axis_center

By default, any labels given to C<axis_labels> are placed centrally between the lines.  Setting this to 0 puts the
labels in the normal 'number' position, next to the major lines.

=head3 axis_color

Colour for grid lines on one axis.  See L</layout_color>.  (Defaults to C<layout_color>).

=head3 axis_draw_fn

The string given here should be the name of a PostScript function which will draw the axis, lines and labels.  See
the code for the C</xdraw> and C</ydraw> functions which provide the defaults.

=head3 axis_font

Font for labels and title on the axis.  (Defaults to C<font>)

=head3 axis_font_color

Colour for axis title and labels.  (Defaults to C<font_color>)

=head3 axis_font_size

Size for title and labels on the axis.  (Defaults to C<font_size>)

=head3 axis_heavy_color

The colour of the major, labelled, lines.  (Defaults to C<layout_heavy_color>)

=head3 axis_heavy_width

Width of the labelled lines.  (Defaults to C<layout_heavy_width>)

=head3 axis_height

For x: space beneath the x axis.  (Defaults to just enough space for the labels and x axis title)

For y: should not be changed.  (Defaults to full height of chart area, baring top and bottom space)

=head3 axis_high

The highest number required to appear on the axis.  This will be rounded up to suit the chosen scale.  (Default:
100)

=head3 axis_label_gap

The space between the start of each label.  The effect is for the program to choose more or fewer labels on the
x axis.  Although available to the y axis, the spacing between labels is rarely an issue.  (Default: 30)

=head3 axis_labels

This should be a reference to a list of strings.  If a list of labels is provided, the axes uses these, ignoring
C<axis_high> and C<axis_low>.  

The functions C<x_axis_labels> and C<y_axis_labels> are unusual in that they set as well as return their value.
Note that any alterations made after C<new> and before C<draw_scales>, must have all strings enclosed in '()' for
postscript.  The number of labels must NOT be changed.

=head3 axis_labels_req

An indication of the number of major (labelled) marks wanted along the axis.  The program overrides this if it is
not suitable. (Default derived from C<axis_label_gap>)

=head3 axis_light_color

Colour of the minor, unlabelled, lines. (Defaults to C<layout_light_color>)

=head3 axis_light_width

Width of the lightest lines.  (Defaults to C<layout_light_width>)

=head3 axis_low

The lowest number required to appear on the axis.  This will be rounded down to suit the chosen scale.  (Default:
0)

=head3 axis_mid_color

A scale of 10 will be divided into two lots of 5 seperated by a slightly heavier line at the 5 mark.  This is the
'mid' line.  (Defaults to C<layout_mid_color>)

=head3 axis_mid_width

Width of the mid-lines, see </axis_mid_color>.  (Defaults to C<layout_mid_width>)

=head3 axis_mark_gap

The gap between smallest marks.  This is a calculated value and cannot be set, although it may be controlled with
B<axis_smallest>.

=head3 axis_mark_min

The smallest mark on the axis.  (Defaults to C<layout_mark_min>)

=head3 axis_mark_max

The tallest mark on the axis.  (defaults to C<layout_mark_max>)

=head3 axis_rotate

Setting this to 1 rotates the axis labels 90 degrees right.  (Defaults to 1 on the x axis when labels are
provided, 0 otherwise)

=head3 axis_smallest

This is the smallest allowable gap between axis marks.  Setting this controls how many subdivisions the program
generates.  It would be wise to set this as a multiple of C<layout_dots_per_inch>.  (Defaults to 3 dots)

=head3 axis_si_shift

The number of 0's removed at a time when adjusting the axis labels, e.g. 3 for thousands, 2 for hundreds or 0 for
no adjustment.  (Default: 3)

=head3 axis_title

The text printed at the top of the y axis and below the right of the x axis.  (Default: "")

=head3 axis_width

For x: should not be changed.  (Defaults to width between y axis and key area)

For y: width allocated for y axis marks and labels.  (Default: 36)

=cut

sub x_axis_labels {
    my ($o, $ar) = @_;
    $o->{x}{labels} = $ar if (defined $ar);
    return $o->{x}{labels}; 
}

sub y_axis_labels {
    my ($o, $ar) = @_;
    $o->{y}{labels} = $ar if (defined $ar);
    return $o->{y}{labels}; 
}

sub init_scale_sizes {
    my ($o, $axis, $r) = @_;
    $r = {} unless (defined $r);
    $o->{$axis}{markmin} = 0 unless (defined $o->{$axis}{markmin});
    my $sc = $o->{$axis};
    my $ch = $o->{ch};
    $r = {} unless (defined $r);
    
    $sc->{markmin} = defined($r->{mark_min})      ? $r->{mark_min}          : 0.5;
    $sc->{markmax} = defined($r->{mark_max})      ? $r->{mark_max}          : 8;
    $sc->{font}    = defined($r->{font})          ? $r->{font}              : $ch->{font};
    $sc->{fsize}   = defined($r->{font_size})     ? $r->{font_size}         : $ch->{fontsize};
    $sc->{fcol}    = defined($r->{font_color})    ? str($r->{font_color})   : $ch->{fontcol};

    $sc->{labels}  = $r->{labels};
    my $bar        = defined($r->{labels})        ? 1			    : 0;
    my $offset     = defined($r->{offset})        ? ($r->{offset} != 0)     : 0;
    $sc->{offset}  = $bar			  ? $offset		    : 0;
    $sc->{rotate}  = defined($r->{rotate})	  ? ($r->{rotate} != 0)     : $bar;
    $sc->{center}  = defined($r->{center})	  ? ($r->{center} != 0)     : $bar;
    $sc->{show}    = defined($r->{show_lines})    ? ($r->{show_lines})      : not $bar;
    $sc->{flags}   = $bar          * $fl_bar;
    $sc->{flags}  |= $sc->{rotate} * $fl_rotate;
    $sc->{flags}  |= $sc->{center} * $fl_center;
    $sc->{flags}  |= $sc->{offset} * $fl_offset;
    $sc->{flags}  |= $sc->{show}   * $fl_show;
    #warn sprintf '%s axis flags=%o, bar=%o, show_lines=%o%s', $axis, $sc->{flags}, $bar, $r->{show_lines} || 0,"\n";
    #warn "rotate=$sc->{rotate}, center=$sc->{center}, offset=$sc->{offset}, show=$sc->{show}\n";
    
    my $maxlen = 0;
    if (defined $sc->{labels}) {
	foreach my $label (@{$sc->{labels}}) {
	    my $len = length($label);
	    $maxlen = $len if ($len > $maxlen);
	}
    }
    my ($width, $height);
    if ($axis eq "x") {
	$width      = $ch->{right} - 1 - $ch->{keyw} - $ch->{rmargin} - $ch->{yx1};
	if (defined($sc->{labels}) and ($sc->{flags} & 1 == 1)) {
	    my $ratio = defined $r->{glyph_ratio} ? $r->{glyph_ratio} : 0.5;
	    $height = $sc->{markmax} + (1 + $maxlen * $ratio) * $sc->{fsize};
	} else {
	    $height = $sc->{markmax} + 2.5 * $sc->{fsize};
	}
    } elsif ($axis eq "y") {
	if (defined($sc->{labels}) and ($sc->{flags} & 1 == 0)) {
	    $width = $sc->{markmax} + $maxlen * 0.8 * $sc->{fsize};
	} else {
	    $width  = 30;
	}
	$height     = $ch->{top} - $ch->{bottom} - 2 * $ch->{spc};
    }
    $sc->{width}    = defined($r->{width})         ? $r->{width}           : $width;
    $sc->{height}   = defined($r->{height})        ? $r->{height}          : $height;
}
# Internal method, setting axis sizes required for chart dimensions
# Requires layout fonts to have been initialized
# Called from within initlayout, before all other axis inits

sub init_scale_options {
    my ($o, $axis, $r) = @_;
    $o->{$axis}{llo} = 0;
    my $sc = $o->{$axis};
    my $ch = $o->{ch};
    $r = {} unless (defined $r);
    
    # collect options and set defaults
    undef $r->{label_gap} if defined($r->{label_gap}) and ($r->{label_gap} <= 0);
    $sc->{llo}       = defined($r->{low})           ? $r->{low}           : 0;
    $sc->{lhi}       = defined($r->{high})          ? $r->{high}          : 100;
    $sc->{labelgap}  = defined($r->{label_gap})     ? $r->{label_gap}     : 30;	    # gap between labels
    $sc->{smallest}  = defined($r->{smallest})      ? $r->{smallest}      : 3 * 72/$ch->{dpi};	# 3 dots
    $sc->{title}     = defined($r->{title})         ? $r->{title}         : ($sc->{title} || "");
    $sc->{si}        = defined($r->{si_shift})      ? $r->{si_shift}      : 3;
    
    my $x = ($axis eq "x");
    my $y = ($axis eq "y");
    if ($x) {
	$sc->{phi}   = $ch->{gx1};
	$sc->{plo}   = $ch->{gx0};
	$sc->{draw}  = defined($r->{draw_fn})       ? $r->{draw_fn}       : "xdraw";
    } elsif ($y) {
	$sc->{phi}   = $ch->{gy1};
	$sc->{plo}   = $ch->{gy0};
	$sc->{draw}  = defined($r->{draw_fn})       ? $r->{draw_fn}       : "ydraw";
    } else {
	die "init_scale(): axis not x or y\nStopped";
    }

    my $bar  = (($sc->{flags} & $fl_bar) == $fl_bar);
    my $show = (($sc->{flags} & $fl_show) == $fl_show);
    if ($x and $bar) {
	#print "using background\n";
	if ($show) {
	    $sc->{heavycol} = defined($r->{heavy_color}) ? str($r->{heavy_color}) : $ch->{heavycol};
	    $sc->{midcol}   = defined($r->{mid_color})   ? str($r->{mid_color})   : $ch->{midcol};
	} else {
	    $sc->{heavycol} = $ch->{bgnd};
	    $sc->{midcol}   = $ch->{bgnd};
	}
	$sc->{lightcol} = defined($r->{light_color}) ? str($r->{light_color}) : $ch->{bgnd};
    } else {
	#print "using colours\n";
	$sc->{heavycol} = defined($r->{heavy_color}) ? str($r->{heavy_color}) : $ch->{heavycol};
	$sc->{midcol}   = defined($r->{mid_color})   ? str($r->{mid_color})   : $ch->{midcol};
	$sc->{lightcol} = defined($r->{light_color}) ? str($r->{light_color}) : $ch->{lightcol};
    }
    $sc->{heavyw}   = defined($r->{heavy_width}) ? str($r->{heavy_width}) : $ch->{heavyw};
    $sc->{midw}     = defined($r->{mid_width})   ? $r->{mid_width}        : $ch->{midw};
    $sc->{lightw}   = defined($r->{light_width}) ? $r->{light_width}      : $ch->{lightw};
}
# Internal method, reading scale options
# Called within new, after initlayout (and init_scale_sizes) but before init_bars or init_scale 

sub init_bars {
    my ($o, $axis, $r) = @_;
    my $sc = $o->{$axis};
    my $ch = $o->{ch};
    $r = {} unless (defined $r);

    #print join(",", @{$sc->{labels}}) . "\n";
    my @labels;
    foreach my $label (@{$sc->{labels}}) {
	push @labels, "($label)";
    }
    unless ($labels[$#labels] eq "()") {
	push @labels, "()";
    }
    # kludge to avoid postscript divide-by-zero error I can't be bothered to trace
    while ($#labels < 2) {
	push @labels, "()";
    }
    
    my $subdivs    = defined($r->{sub_divisions}) ? $r->{sub_divisions} : 1;
    my $markmul    = ($sc->{markmax} - $sc->{markmin})/$subdivs;
    $sc->{markmul} = defined($r->{mark_mul})      ? $r->{mark_mul}      : $markmul;
    $sc->{markgap} = ($sc->{phi} - $sc->{plo})/($#labels * $subdivs);
    $sc->{markcen} = $subdivs > 1 ? ($sc->{markgap} - 0.5) * $subdivs : $sc->{markgap} * 2;
    my $n = ($sc->{flags} & $fl_offset) ? $#labels - 1 : $#labels; 
    $sc->{factors} = [ ($n, $subdivs) ];
    $sc->{labels}  = [ @labels ];
    $sc->{ldepth}  = 0;
    #print "$axis labels   = $sc->{labels}\n";

    $sc->{labsreq} = $#labels;
    $sc->{llo}     = 0;
    $sc->{lhi}     = $#labels;
    $sc->{l2pm}    = ($sc->{phi} - $sc->{plo})/($sc->{lhi} - $sc->{llo});
    $sc->{l2pc}    = $sc->{plo} - $sc->{l2pm} * $sc->{llo};
    $sc->{p2lm}    = ($sc->{lhi} - $sc->{llo})/($sc->{phi} - $sc->{plo});
    $sc->{p2lc}    = $sc->{llo} - $sc->{p2lm} * $sc->{plo};
    #print "$axis logical  = $sc->{p2lm} * physical + $sc->{p2lc}\n";
    #print "$axis physical = $sc->{l2pm} * logical  + $sc->{l2pc}\n\n";

}
# Internal method, intializing one barchart axis

sub init_scale {
    my ($o, $axis, $r) = @_;
    my $sc = $o->{$axis};
    my $ch = $o->{ch};
    $r = {} unless (defined $r);

    # kludge to better handle -ve scales
    ($sc->{llo}, $sc->{lhi}) = ($sc->{lhi}, $sc->{llo}) unless $sc->{llo} <= $sc->{lhi};
    my ($sclrange, $scprange);
    if ($sc->{llo} < 0 and $sc->{lhi} > 0) {
	my $negrange = 0 - $sc->{llo};
	my $posrange = $sc->{lhi} - 0;
	my $physrange = $sc->{phi} - $sc->{plo};
	if ($posrange > $negrange) {
	    $sclrange = $posrange;
	    $scprange = $physrange * $posrange/($posrange + $negrange);
	} else {
	    $sclrange = $negrange;
	    $scprange = $physrange * $negrange/($posrange + $negrange);
	}
    } else {
	$sclrange = $sc->{lhi} - $sc->{llo};
	$scprange = $sc->{phi} - $sc->{plo};
    }
    $sc->{labsreq} = int($scprange/$sc->{labelgap});
    $sc->{labsreq} = defined($r->{labels_req}) ? $r->{labels_req} : $sc->{labsreq}; # allow override
    #warn "$axis, labsreq=$sc->{labsreq} labelgap=$sc->{labelgap} scprange=$scprange\n";
    $sc->{labsreq} = 1 if $sc->{labsreq} < 1;

    ## calculate number of major marks to use
    my $lbase10 = $sclrange > 0 ? log($sclrange)/log(10) : 0;
    my $mult = 10 ** int($lbase10);
    my $mant = $sclrange/$mult;
    my @scale  = (0.2, 0.5, 1, 2, 5);
    my @subdiv = (  2,   5, 2, 5, 2);
    my ($best, $scale, $subdivs) = (99, 1, 1);
    for (my $i = 0; $i <= $#scale; $i++) {
	my $smant = $mant*$scale[$i];
	my $smult = $mult/$scale[$i];
	my $score = abs($smant - $sc->{labsreq});
	if ($score < $best) {
	    $best = $score;
	    $scale = $smult;
	    $subdivs = $subdiv[$i];
	}
    }
    $sclrange = $sc->{lhi} - $sc->{llo};
    $scprange = $sc->{phi} - $sc->{plo};
    #warn "$axis requested: physical $sc->{plo} to $sc->{phi}, logical $sc->{llo} to $sc->{lhi}\n";
    #warn "$axis            lrange=$sclrange, prange=$scprange, labelsreq=$sc->{labsreq}, smallest=$sc->{smallest}\n";
    
    ## include outer marks as required
    my $lhi = int($sc->{lhi}/$scale) * $scale;
    my $llo = int($sc->{llo}/$scale) * $scale;
    $llo -= $scale while ($llo > $sc->{llo});
    $sc->{llo} = $llo;
    $lhi += $scale while ($lhi < $sc->{lhi});
    $lhi = $llo + $scale if $lhi == $llo;
    $sc->{lhi} = $lhi;
    my $nmarks = ($lhi - $llo)/$scale;
    #warn "$axis            nmarks=$nmarks, scale=$scale, llo=$sc->{llo}, lhi=$sc->{lhi}\n";
    
    ## calculate subdivisions of subdivisions ...
    my @factor = ($nmarks);
    my @spread = ($scale);
    my $nphys = int($scprange/$sc->{smallest});
    my $rem = $nphys/$nmarks;
    while ($rem > $subdivs) {
	$rem /= $subdivs;
	$nmarks *= $subdivs;
	$scale /= $subdivs;
	push @factor, $subdivs;
	push @spread, $scale;
	$subdivs = ($subdivs == 2) ? 5 : 2;
    }
    if ($rem/5 > 1) {
	$nmarks *= 5;
	$scale /= 5;
	push @factor, 5;
	push @spread, $scale;
    } elsif ($rem/2 > 1) {
	$nmarks *= 2;
	$scale /= 2;
	push @factor, 2;
	push @spread, $scale;
    }
    $sc->{factors} = [ @factor ];	    # nesting of (sub)divisions
    $sc->{spreads} = [ @spread ];	    # logical size of those (sub)divisions
    $sc->{markgap} = $scprange/$nmarks;	    # physical size between smallest marks
    $sc->{markcen} = $sc->{markgap};
    #warn "$axis factors  = [", join(", ", @factor), "],   markgap=$sc->{markgap}, subdivs=$subdivs\n";

    ## calculate physical width of all the marks 
    my $marks = 1;
    foreach my $factor (@factor) { $marks *= $factor; }
    $sc->{phi} = $sc->{plo} + $marks * $sc->{markgap};

    ## calculate depth for printed labels
    my $nlabels = 1;
    my $last = 0;
    $sc->{ldepth} = 0;
    for (my $depth = 0; $depth <= $#factor; $depth++) {
	$last = $nlabels;
	$nlabels *= $factor[$depth];
	if ($nlabels >= $sc->{labsreq}) {
	    if (abs($last - $sc->{labsreq}) < abs($nlabels - $sc->{labsreq})) {
		$nlabels = $last;
		$sc->{ldepth} = $depth - 1;
	    } else {
		$sc->{ldepth} = $depth;
	    }
	    last;
	}
    }
    $sc->{ldepth} = 0 if $sc->{ldepth} < 0;
    #warn "$axis spreads  = [", join(", ", @spread), "],   depth=$sc->{ldepth}\n";
    $sc->{markmul} = ($#factor >= 0) ? ($sc->{markmax} - $sc->{markmin})/($#factor + 1) : 0;
    
    ## calculate any SI adjustment to labels
    my $lhi10 = $sc->{lhi} != 0 ? log(abs($sc->{lhi}))/log(10) : 0;
    my $si10 = $sc->{si} ? ($sc->{si} * int($lhi10/$sc->{si})) : 0;
    my $si = 10 ** $si10;
    if ($si != 1) {
	$sc->{title} = '' unless (defined $sc->{title});
	my $groups = $si10/$sc->{si};
	my $zeroes = '|' x $sc->{si};
	my $extra  = $groups > 1 ? (' ' . "$zeroes " x ($groups-1)) : '';
	$extra = " (in 1$extra${zeroes}'s)";
	$extra =~ tr/|/0/;
	$sc->{title} .= $extra;
    }
    
    ## now for the actual labels
    my @count = ();
    foreach my $f (@factor) { push @count, 0; }
    my $depth = $sc->{ldepth};
    my $value = $sc->{llo};
    my @labels = ($value/$si);
    while ($depth >= 0) {
	for ($depth = $sc->{ldepth}; $depth >= 0; $depth--) {
	    ++$count[$depth];
	    last if ($count[$depth] < $factor[$depth]);
	    $count[$depth] = 0;
	}
	$value = $sc->{llo};
	for (my $i = 0; $i <= $sc->{ldepth}; $i++) {
	    $value += $count[$i] * $spread[$i];
	}
	push @labels, $value/$si;
    }
    pop @labels;
    push @labels, $sc->{lhi}/$si;
    $sc->{labels} = [ @labels ];
    #warn "$axis produced : physical $sc->{plo} to $sc->{phi}, logical $sc->{llo} to $sc->{lhi}, si=$si\n";

    ## y = mx + c values
    $sc->{l2pm} = ($sc->{phi} - $sc->{plo})/($sc->{lhi} - $sc->{llo});
    $sc->{l2pc} = $sc->{plo} - $sc->{l2pm} * $sc->{llo};
    $sc->{p2lm} = ($sc->{lhi} - $sc->{llo})/($sc->{phi} - $sc->{plo});
    $sc->{p2lc} = $sc->{llo} - $sc->{p2lm} * $sc->{plo};
    #warn "$axis logical  = $sc->{p2lm} * physical + $sc->{p2lc}\n";
    #warn "$axis physical = $sc->{l2pm} * logical  + $sc->{l2pc}\n\n";
}
## Internal method, initializing one scale
# expects either ("x", $opts{x_axis}) or ("y", $opts{y_axis})
# $o->{ch}{...} must already exist

=head1 OBJECT METHODS

Methods are provided which access the option values given to the constructor.  Those are B<file>, and all B<layout_>,
B<x_axis_> and B<y_axis_> methods documented under L</CONSTRUCTOR>.

The most common PostScript::File methods are also provided as members of this class.

However, the most useful methods are those which give access to the layout calculations including conversion
functions.

=head2 Convenience methods

A few methods of the underlying PostScript::File object are provided for convenience.  The others can be called
via the B<file()> function.  The following both do the same thing.

    $pg->newpage();
    $pg->file()->newpage();

=cut

sub output {
    my ($o, @params) = @_; 
    $o->{ps}->output( @params );
}

=head3 output( file [, dir] )

Output the chart as a file.  See L<PostScript::File/output>.

=cut

sub newpage { 
    my ($o, @params) = @_; 
    $o->{ps}->newpage( @params );
}

=head3 newpage( [page] )

Start a new page in the underlying PostScript::File object.  See L<PostScript::File/newpage> and
L<PostScript::File/set_page_label>.

=cut

sub add_function {
    my ($o, @params) = @_; 
    $o->{ps}->add_function( @params );
}

=head3 add_function( name, code )

Add functions to the underlying PostScript::File object.  See L<PostScript::File/add_function> for details.

=cut

sub add_to_page {
    my ($o, @params) = @_; 
    $o->{ps}->add_to_page( @params );
}

=head3 add_to_page( [page], code )

Add postscript code to the underlying PostScript::File object.  See L<PostScript::File/add_to_page> for details.

=cut

sub graph_area { 
    my $o = shift; 
    return ($o->{ch}{gx0}, $o->{ch}{gy0}, $o->{ch}{gx1}, $o->{ch}{gy1}); 
}
    
=head2 Result methods

These fall into three groups according to their return value.  B<_area> methods return an array of four values
representing the physical coordinates of (left, bottom, right, top).  B<_point> methods return an array again, but
this time representing an (x, y) value.  The underlying constants are also accessable.

=head3 graph_area

Return an array holding (x0, y0, x1, y1), the bounding box of the graph area.

=cut

sub key_area { 
    my $o = shift; 
    my $left = $o->{ch}{gx1} + $o->{ch}{rmargin};
    my $right = $o->{ch}{right} - $o->{ch}{spc} - 1;
    my $top = $o->{ch}{gy1};
    my $bottom = $o->{ch}{bottom} + $o->{ch}{spc};
    return ($left, $bottom, $right, $top); 
}
    
=head3 key_area

Return an array holding (x0, y0, x1, y1), the bounding box of the area allocated for the key, if any. 

=cut

sub vertical_bar_area {
    my ($o, $bar, $y) = @_;
    my ($left, $bottom, $right, $top);
    if (defined $o->{x}{labels}) {
	$left = $o->{ch}{gx0} + ($bar + 0.5) * $o->{x}{markgap};
	$right = $left + $o->{x}{markgap};
    } else {
	$left = $o->{ch}{gx0} + $bar * $o->{x}{markgap};
	$right = $left + $o->{x}{markgap};
    }
    if (defined $y) {
	$bottom = $o->{y}{l2pc};
	$top = $y * $o->{y}{l2pm} + $o->{y}{l2pc};
	# reverse if y < 0
	if ($top < $bottom) {
	    my $temp = $top;
	    $top = $bottom;
	    $bottom = $temp;
	}
	# clip if out of graph area
	my $gy0 = $o->{ch}{gy0};
	my $gy1 = $o->{ch}{gy1};
	$top    = $gy0 if ($top    < $gy0);
	$bottom = $gy0 if ($bottom < $gy0);
	$top    = $gy1 if ($top    > $gy1);
	$bottom = $gy1 if ($bottom > $gy1);
    } else {
    $bottom = $o->{ch}{gy0};
    $top = $o->{ch}{gy1};
    }
    return ($left, $bottom, $right, $top);
}

=head3 vertical_bar_area

Return the physical coordinates of a barchart bar.  Use as:

    @area = vertical_bar_area( $bar )
    @area = vertical_bar_area( $bar, $y )

Where C<$bar> is the 0 based number of the bar and C<$y> is an optional coordinate indicating the top of the bar.

=cut

sub horizontal_bar_area {
    my ($o, $bar, $x) = @_;
    $x = $o->{x}{lhi} unless (defined $x);
    my $left = $o->{ch}{gx0};
    my $bottom = $o->{ch}{gy0} + $bar * $o->{y}{markgap};
    my $right = $x * $o->{x}{l2pm} + $o->{x}{l2pc};
    my $top = $bottom + $o->{y}{markgap};
    return ($left, $bottom, $right, $top);
}

=head3 horizontal_bar_area

Return the physical coordinates of a barchart bar.  Use as:

    @area = horizontal_bar_area( $bar )
    @area = horizontal_bar_area( $bar, $x )

Where C<$bar> is the 0 based number of the bar and C<$x> is an optional coordinate indicating the 'top' of the bar.

=cut

sub physical_point { 
    my ($o, $x, $y) = @_; 
    return ($x * $o->{x}{l2pm} + $o->{x}{l2pc}, $y * $o->{y}{l2pm} + $o->{y}{l2pc});
}

=head3 physical_point( x, y )

Return the physical, native postscript, coordinates corresponding to the logical point (x, y) on the graph.

=cut

sub logical_point { 
    my ($o, $x, $y) = @_; 
    return ($x * $o->{x}{p2lm} + $o->{x}{p2lc}, $y * $o->{y}{p2lm} + $o->{y}{p2lc});
}

=head3 logical_point( px, py )

Return the logical, graph, coordinates corresponding to a point on the postscript page.

=cut

sub px { 
    my ($o, $v) = @_; 
    return $v * $o->{x}{l2pm} + $o->{x}{l2pc}; 
}

=head3 px

Use as physical_x = $gp->ps( logical_x )

=cut

sub py { 
    my ($o, $v) = @_; 
    return $v * $o->{y}{l2pm} + $o->{y}{l2pc}; 
}

=head3 py

Use as physical_y = $gp->ps( logical_y )

=cut

sub lx { 
    my ($o, $v) = @_; 
    return $v * $o->{x}{p2lm} + $o->{x}{p2lc}; 
}

=head3 lx

Use as logical_x = $gp->ps( physical_x )

=cut

sub ly { 
    my ($o, $v) = @_; 
    return $v * $o->{y}{p2lm} + $o->{y}{p2lc}; 
}

=head3 py

Use as logical_y = $gp->ps( physical_y )

=cut

sub color_as_array ($) {
    my $col = shift;
    my ($r, $g, $b) = ($col =~ /\[\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)/);
    $col = [ $r, $g, $b ] if (defined $b);
    return $col;
}
    
=head1 POSTSCRIPT CODE

There should be no reason to access this under normal use.  However, as the purpose of this module is to make
drawing graphs for postscript easier.  Therefore the main graph-drawing function is documented here, along with
the variables and functions that may be useful elsewhere.

=head3 drawgpaper

The principal function requires 62 settings.  To make this more manageable there are a number of functions which
merely accept and store a small group of these.  After these have been executed, B<drawgpaper> is then called with
no parameters.  

Usage is given below with the functions indented after their parameters.  Each function remove all its parameters
from the stack.   All functions and variables are within the B<gpaperdict> dictionary.   It is written out as it
would appear within a perl 'here' document, with perl variables for each parameter.  The '/' in front of font
names, and  '()' around text are required by postscript. 

    gpaperdict begin
    
	$graph_left
	$graph_bottom
	$graph_right
	$graph_top
	    graph_area

	$heavy_width
	$heavy_color
	$mid_width
	$mid_color
	$light_width
	$light_color
	    graph_colors

	$heading_left
	$heading_bottom
	$heading_right
	$heading_top
	    heading_area

	/$heading_font
	$heading_font_size
	$heading_font_color
	($heading_text)
	    heading_labels
	    
	$x_axis_left
	$x_axis_bottom
	$x_axis_right
	$x_axis_top
	    x_axis_area

	$x_axis_mark_min
	$x_axis_mark_multiplier
	$x_axis_mark_max
	$x_axis_mark_gap
	    xaxis_marks
	    
	$x_axis_factors_array_as_string
	$x_axis_labels_array_as_string
	$x_axis_label_depth
	$x_axis_flags
	/$x_axis_font
	$x_axis_font_size
	$x_axis_font_color
	($x_axis_text)
	    xaxis_labels
	    
	$y_axis_left
	$y_axis_bottom
	$y_axis_right
	$y_axis_top
	    y_axis_area

	$y_axis_mark_min
	$y_axis_mark_multiplier
	$y_axis_mark_max
	$y_axis_mark_gap
	    yaxis_marks
	    
	$y_axis_factors_array_as_string
	$y_axis_labels_array_as_string
	$y_axis_label_depth
	$y_axis_flags
	/$y_axis_font
	$y_axis_font_size
	$y_axis_font_color
	($y_axis_text)
	    yaxis_labels

	drawgpaper

    end % gpaperdict
    
Most of these are self explanatory or relate to options documented elsewhere, but a few might need some
explanation.  

C<x_axis_flags> indicate how the labels are to be printed.

    Bit	    Action if true
    0	    rotate text
    1	    centre text between marks

C<x_axis_labels_array_as_string> means a list of all the labels to be printed on the x axis, written out as
a postscript array, such as:

    "[ (label1) (label2) (label3) ]"
    "[ 0 0.5 1 1.5 2 ]"

C<x_axis_factors_array_as_string> has the same format.  However, the contents refer to the nesting of the axis
marks.  For example, the x axis goes from 400 to 800 in units of 100.  Each 100 is subdivided into
2 and then 5, so the smallest divisions are worth 10 each.  Labels are placed at the 100 and 50 marks.  The factor
array would be as follows.

    [ 4 2 5 ]

C<x_axis_label_depth> would be 1 in the previous example (postscript arrays are zero based).
    
C<x_axis_mark_min> is the size of the smallest mark - the 10's above.

C<x_axis_mark_max> is the size of the largest mark - the 100's above.

C<x_axis_mark_multiplier> is the size added for each decreas in factor depth.

=head3 px

Convert a logical x value to a postscript x value.  It is probably faster to use B<physical_point()> to do any
conversions and write postscript values into the postscript code.  PostScript interpreters seem to use much slower
processors.

=head3 py

Convert a logical y value to a postscript y value.

=head3 gpapercolor

Set the drawing color.  This expects a single parameter which may be an array of RGB values or a grayscale value.

    0.5 gpapercolor
    [ 1 0.8 0 ] gpapercolor

=head3 gpaperfont

Select a font for subsequent text.  It expects three parameters - a font name, size and colour.  The font name
should evaluate to a literal name as used by C<findfont>.  The size is stored in the variable C<fontsize> for
reference later, and the color is just passed to C<gpapercolor>.

    /Helvetica 12 0 gpaperfont
    /$fontname $fontsize [ $r $g $b ] gpaperfont

=head3 fillbox

Fill and outlines a box.  Use as follows.  The colours are passed to C<gpapercolor>.

    $left $bottom $right $top
    $fill_color 
    $outline_color $outline_width
	fillbox

=head3 drawbox

Draw an unfilled box.  Use as follows.  The colours are passed to C<gpapercolor>.

    $left $bottom $right $top
    $outline_color $outline_width
	drawbox

=head3 centered

Show text horizontally centred about the coordinated given.  Use as:

    $message $x $y centered

=head3 rjustify

Show right justified text, ending at the point given.  Use as:

    $message $x $y rjustified

=head3 rotated

Show text rotated 90 degrees right, starting at the point given.  Use as:

    $message $x $y rotated

=head3 copy_array

Do a deep copy of an array so that one can be changed without affecting the other.  This works differently from
the others.  It requires an array, and exits leaving both copies on the stack.  The variable C<array_max> is also
set to the highest index allowed.

=head2 gpaperdict variables

Here are some of the variables in the gpaperdict dictionary which might need to be accessed directly.

    array_max	largest index into copied array
    bgnd	background colour for grid
    boxc	colour of box outline
    boxw	width of box outline
    fillc	fill colour of box
    fontsize	height of most recent gpaperfont
    gx0		graph left (same as xx0)
    gy0		graph bottom (same as yy0)
    gx1		graph right (same as xx1)
    gy1		graph top
    hcol	font colour used on heading
    hfont	font name used on heading
    hsize	font size used on heading
    hx0		head left
    hx1		head right
    hy0		head bottom
    hy1		head top
    xlc		constant for logical x
    xlm		multiplier for logical x
    xmarkcen	width for centering label
    ylc		constant for logical y
    ylm		multiplier for logical y
    ymarkcen	width for centering label

=cut

 
sub ps_functions {
    my ($class, $ps) = @_;

    my $name = "GraphPaper";
    $ps->add_function( $name, <<END_COMMON_FUNCTIONS ) unless ($ps->has_function($name));
	/gpaperdict 120 dict def
	gpaperdict begin
	/finish 0 def
	/labelbuf 80 string def

	/gpapercolor {
	    gpaperdict begin
	    dup type (arraytype) eq {
		aload pop 
		setrgbcolor
	    }{
		dup 0 le { neg } if
		setgray
	    } ifelse
	    end
	} bind def
	% _ array|int => _

	/gpaperfont {
	    gpaperdict begin
	    gpapercolor
	    /fontsize exch def 
	    findfont fontsize scalefont setfont
	    end
	} bind def
	% _ font size color => _

	/centered {
	    3 2 roll labelbuf cvs 3 1 roll
	    2 index stringwidth pop 2 div neg
	    3 2 roll add exch
	    moveto show
	} bind def
	% _ str x y => _

	/rjustified {
	    3 2 roll labelbuf cvs 3 1 roll
	    2 index stringwidth pop neg
	    3 2 roll add exch
	    moveto show
	} bind def
	% _ str x y => _

	/rotated {
	    3 2 roll labelbuf cvs 3 1 roll
	    gsave
	    translate
	    -90 rotate
	    0 0 moveto show
	    grestore
	} bind def
	% _str x y => _

	/init_xy {
	    /setstrokeadjust where { pop true setstrokeadjust } if
	    newpath
	    moveto
	    store_xy
	    stroke
	} bind def
	% _ x y => _

	/store_xy {
	    gpaperdict begin
	    currentpoint
	    /y exch def
	    /x exch def
	    end
	} bind def
	% _ x y => _

	/copy_array {
	    gpaperdict begin
	    mark 1 index aload pop
	    /array_max counttomark 2 sub def
	    ]
	    end
	} bind def
	% _ array => _ array array
	% make deep copy of array and set array_max

	/drawonegrid {
	    gpaperdict begin
	    /label 0 def
	    /drawline exch cvx def
	    copy_array
	    0 drawline
	    /finish 0 def
	    {
		% dec counters in array
		array_max -1 0
		{   
		    2 copy 2 copy get 1 sub put
		    dup /factor exch def
		    2 copy get 0 gt { pop exit } if
		    dup 0 eq {
			2 copy get 0 eq {
			    /finish 1 def
			} if
		    } if
		    2 copy dup 5 index
		    exch get put
		    pop
		} for
		factor drawline
		finish 1 eq { exit } if
	    } loop
	    pop pop
	    end
	} def
	% Requires an array of scales
	% and a suitable fn for drawing each line
	% _ factor_array fn_name => _

	/setlines {
	    dup 0 eq {
		heavyw setlinewidth
		heavyc gpapercolor
	    }{
		dup 1 eq {
		    midw setlinewidth
		    midc gpapercolor
		}{
		    lightw setlinewidth
		    lightc gpapercolor
		} ifelse
	    } ifelse
	} bind def
	% _ depth => _ depth

	/drawbox {
	    7 dict begin
	    gsave
	    /boxw exch def /boxc exch def 
	    /y1 exch def /x1 exch def /y0 exch def /x0 exch def
	    newpath
	    x0 y0 moveto x0 y1 lineto x1 y1 lineto x1 y0 lineto
	    closepath 
	    boxc gpapercolor boxw setlinewidth
	    stroke
	    grestore
	    end
	} bind def
	% x0 y0 x1 y1 outline_col outline_width => _

	/fillbox {
	    7 dict begin
	    gsave
	    /boxw exch def /boxc exch def /fillc exch def 
	    /y1 exch def /x1 exch def /y0 exch def /x0 exch def
	    newpath
	    x0 y0 moveto x0 y1 lineto x1 y1 lineto x1 y0 lineto
	    closepath 
	    gsave fillc gpapercolor fill grestore
	    boxc gpapercolor boxw setlinewidth
	    stroke
	    grestore
	    end
	} bind def
	% x0 y0 x1 y1 fill_col outline_col outline_width => _

	/graph_area {
	    gpaperdict begin
	    /fgnd exch def
	    /bgnd exch def
	    /gy1 exch def
	    /gx1 exch def
	    /gy0 exch def
	    /gx0 exch def
	    /width gx1 gx0 sub def
	    /height gy1 gy0 sub def
	    end
	} bind def
	% _ x0 y0 x1 y1 bgnd boxcol => _

	/set_xaxis_colors {
	    gpaperdict begin
	    /lightc xlightc def
	    /lightw xlightw def
	    /midc xmidc def
	    /midw xmidw def
	    /heavyc xheavyc def
	    /heavyw xheavyw def
	    end
	} bind def
	% _ => _

	/set_yaxis_colors {
	    gpaperdict begin
	    /lightc ylightc def
	    /lightw ylightw def
	    /midc ymidc def
	    /midw ymidw def
	    /heavyc yheavyc def
	    /heavyw yheavyw def
	    end
	} bind def
	% _ => _

	/xaxis_colors {
	    gpaperdict begin
	    /xlightc exch def
	    /xlightw exch def
	    /xmidc exch def
	    /xmidw exch def
	    /xheavyc exch def
	    /xheavyw exch def
	    end
	} bind def
	% _ heavyw heavyc midw midc lightw lightc => _

	/yaxis_colors {
	    gpaperdict begin
	    /ylightc exch def
	    /ylightw exch def
	    /ymidc exch def
	    /ymidw exch def
	    /yheavyc exch def
	    /yheavyw exch def
	    end
	} bind def
	% _ heavyw heavyc midw midc lightw lightc => _

	/xaxis_area {
	    gpaperdict begin
	    /xy1 exch def
	    /xx1 exch def
	    /xy0 exch def
	    /xx0 exch def
	    end
	} bind def
	% _ x0 y0 x1 y1 => _

	/xaxis_labels {
	    gpaperdict begin
	    /xtitle exch def
	    /xcol exch def
	    /xsize exch def
	    /xfont exch def
	    /xflags exch def
	    /xldepth exch def
	    /xlabels exch def
	    /xfactors exch def
	    end
	} bind def
	% _ factors labels flags font size color title => _

	/xaxis_marks {
	    gpaperdict begin
	    /xdrawfn exch def
	    /xmarkcen exch def
	    /xmarkgap exch def
	    /xmarkmax exch def
	    /xmarkmul exch def
	    /xmarkmin exch def
	    end
	} bind def
	% _ xmarkmin xmarkmul xmarkmax xmarkgap xmarkcen /xdrawfn => _ 

	/yaxis_area {
	    gpaperdict begin
	    /yy1 exch def
	    /yx1 exch def
	    /yy0 exch def
	    /yx0 exch def
	    end
	} bind def
	% _ x0 y0 x1 y1 => _

	/yaxis_labels {
	    gpaperdict begin
	    /ytitle exch def
	    /ycol exch def
	    /ysize exch def
	    /yfont exch def
	    /yflags exch def
	    /yldepth exch def
	    /ylabels exch def
	    /yfactors exch def
	    end
	} bind def
	% _ factors labels flags font size color title => _

	/yaxis_marks {
	    gpaperdict begin
	    /ydrawfn exch def
	    /ymarkcen exch def
	    /ymarkgap exch def
	    /ymarkmax exch def
	    /ymarkmul exch def
	    /ymarkmin exch def
	    end
	} bind def
	% _ ymarkmin ymarkmul ymarkmax ymarkgap ymarkcen /ydrawfn => _ 

	/heading_area {
	    gpaperdict begin
	    /hy1 exch def
	    /hx1 exch def
	    /hy0 exch def
	    /hx0 exch def
	    end
	} bind def
	% _ x0 y0 x1 y1 => _

	/heading_labels {
	    gpaperdict begin
	    /htitle exch def
	    /hcol exch def
	    /hsize exch def
	    /hfont exch def
	    end
	} bind def
	% _ hfont hsize hcol title => _

	/conv_consts {
	    gpaperdict begin
	    /ylc exch def
	    /ylm exch def
	    /xlc exch def
	    /xlm exch def
	    end
	} bind def
	% _ xlm xlc ylm ylc => _

	/px { 
	    xlm mul xlc add 
	} bind def
		
	% _ int => int
	/py { 
	    ylm mul ylc add 
	} bind def
	
	% _ => _
	/drawgpaper {
	    gpaperdict begin
		gx0 gy0 gx1 gy1 bgnd bgnd 0.25 fillbox
		hfont hsize hcol gpaperfont
		htitle hx1 hx0 add 2 div hy1 hsize sub centered
	
		xfont xsize xcol gpaperfont
		xtitle xx1 xy0 rjustified
		xflags $fl_offset and $fl_offset eq {
		    gx0 xmarkgap add gy0 init_xy
		}{
		    gx0 gy0 init_xy
		} ifelse
		set_xaxis_colors
		xfactors xdrawfn drawonegrid
		
		yfont ysize ycol gpaperfont
		ytitle yx0 hy0 ysize 0.5 mul add moveto show
		gx0 gy0 init_xy
		set_yaxis_colors
		yfactors ydrawfn drawonegrid
		
		gx0 gy0 gx1 gy1 fgnd heavyw drawbox
	    end
	} bind def
	% _ int => int

	/xdraw {
	    gpaperdict begin
		dup xldepth le {
		    gsave
			xcol gpapercolor
			xlabels label get
			/xx x def /yy y def
			xflags $fl_center and $fl_center eq {
			    /xx xx xmarkcen 0.5 mul add def
			} if
			xflags $fl_rotate and $fl_rotate eq {
			    xx fontsize 0.33 mul sub
			    yy xmarkmax 1.25 mul sub
			    rotated
			}{
			    xx yy xmarkmax sub fontsize sub
			    centered
			} ifelse
		    grestore
		    /label label 1 add def
		} if
		setlines
		newpath
		x y moveto
		dup xmarkmul mul xmarkmin add
		xmarkmax exch sub
		dup neg 0 exch rlineto
		0 exch rmoveto
		dup 2 le {
		    0 height rlineto
		    0 height neg rmoveto
		} if
		xmarkgap 0 rmoveto
		store_xy
		stroke
		pop
	    end
	} bind def
	% _ depth => _
	% draw one vertical line

	/ydraw {
	    gpaperdict begin
		dup yldepth le {
		    gsave
			ycol gpapercolor
			ylabels label get
			yflags 1 and 1 eq {
			    yflags 2 and 2 eq {
				% rotate and centre
				x ymarkmax sub fontsize sub
				1 index labelbuf cvs stringwidth pop 2 div 
				y add ymarkcen 0.5 mul add
			    }{
				% rotate and not centre
				x ymarkmax sub fontsize sub
				1 index labelbuf cvs stringwidth pop 2 div
				y add
			    } ifelse
			    rotated
			}{
			    yflags 2 and 2 eq {
				% not rotate and centre
				x ymarkmax sub 2 sub
				y fontsize 0.33 mul sub ymarkcen 0.6 mul add
			    }{
				% not rotate and not centre
				x ymarkmax sub 2 sub
				y fontsize 0.33 mul sub
			    } ifelse
			    rjustified
			} ifelse
		    grestore
		    /label label 1 add def
		} if
		setlines
		newpath
		x y moveto
		dup ymarkmul mul ymarkmin add
		ymarkmax exch sub
		dup neg 0 rlineto
		0 rmoveto
		dup 2 le {
		    width 0 rlineto
		    width neg 0 rmoveto
		} if
		0 ymarkgap rmoveto
		store_xy
		stroke
		pop
	    end
	} bind def
	% _ depth => _
	% draw one horizontal line

	/xdrawstock {
	    gpaperdict begin
		dup xldepth le {
		    gsave
			xcol gpapercolor
			xlabels label get
			dup length 0 ne {
			    x fontsize 0.33 mul sub
			    y xmarkmax 1.5 mul sub
			    rotated
			    pop 0
			}{
			    pop pop 1
			} ifelse
		    grestore
		    /label label 1 add def
		}{
		    pop 2
		} ifelse
		setlines
		newpath
		x y moveto
		dup xmarkmul mul xmarkmin add
		xmarkmax exch sub
		dup neg 0 exch rlineto
		0 exch rmoveto
		dup 2 le {
		    0 height rlineto
		    0 height neg rmoveto
		} if
		xmarkgap 0 rmoveto
		store_xy
		stroke
		pop
	    end
	} bind def
	% _ depth => _
	% draw one vertical line
	% label if depth > 0

	end % gpaperdict
END_COMMON_FUNCTIONS
}
# Internal method 
# Postscript functions common to all axes
#
# This list is to ensure that enough space is allowed in gpaperdict
# for Level 1 interpreters.
#
## gpaperdict functions:
# centered	show text centred horizontally
# gpapercolor   select colour or greyscale
# gpaperfont	select font, noting size
# conv_consts   setup conversion constants
# copy_array    deep copy of array, sets array_max
# drawbox	draw unfilled box
# drawgpaper    main function drawing all areas
# drawonegrid   draw all vertical or horizontal lines
# fillbox	draw and fill box
# graph_area    setup graph area
# graph_colors  setup colours for lines
# heading_area  setup heading area
# heading_labels setup title for heading
# init_xy	set starting position
# rjustified    show text right justified
# rotated	show text rotated 90 degrees right
# setlines	determine colour of graph lines
# store_xy	mark end of current path
# xaxis_area    setup x axis area
# xaxis_labels  setup labels and title for x axis
# xaxis_marks   setup mark data for x axis
# xdraw		draw vertical mark according to array index
# xdrawstock    custom fn drawing marks for stock chart
# yaxis_area    setup y axis area
# yaxis_labels  setup labels and title for y axis
# yaxis_marks   setup mark data for y axis
# ydraw		draw horizontal mark line according to array index
# 
## gpaperdict variables:
# array_max	largest index into copied array
# bgnd		background colour for grid
# boxc		colour of box outline
# boxw		width of box outline
# drawline	place holder in drawonegrid for xdraw/ydraw
# factor	array index in drawonegrid indicating the factor changed 
# fgnd		colour of grid outline
# fillc		fill colour of box
# finish	flag used by drawgpaper
# fontsize	height of most recent gpaperfont
# gx0		graph left (same as xx0)
# gy0		graph bottom (same as yy0)
# gx1		graph right (same as xx1)
# gy1		graph top
# hcol		font colour used on heading
# hfont		font name used on heading
# hsize		font size used on heading
# height	height of graph area
# htitle	title for heading
# hx0		head left
# hx1		head right
# hy0		head bottom
# hy1		head top
# label		label counter used by drawonegrid
# labelbuf	buffer for string conversion
# width		width of graph area
# x		current position between paths
# x0		temp left
# x1		temp right
# xcol		font colour uses on x axis
# xdrawfn	the function to use for drawing x axis
# xfactors	array holding mark info
# xflags	1=rotate, 2=centre
# xfont		font name used on x axis
# xheavyc	colour for heavy lines
# xheavyw	width of heavy lines
# xlabels	array of labels for x axis
# xlc		constant for logical x
# xldepth	print labels up to this depth
# xlightc	colour for light lines
# xlightw	width of light lines
# xlm		multiplier for logical x
# xmarkcen	width for centering labels
# xmarkgap	gap between adjacent marks 
# xmarkmax	tallest mark
# xmarkmin	smallest mark	    
# xmarkmul	step added for each depth
# xmidc		colour for mid lines
# xmidw		width of mid lines
# xsize		font size used on x axis
# xtitle	title for x axis
# xx		temp x used by xdraw
# xx0		x axis left 
# xx1		x axis right
# xy0		x axis bottom
# xy1		x axis top (same as yy0)
# y		current position between paths
# y0		temp bottom
# y1		temp top
# ycol		font colour used on y axis
# ydrawfn	the function to use for drawing y axis
# yfactors	array of scale info for drawonegrid
# yflags	1=rotate, 2=centre
# yfont		font name used on y axis
# yheavyc	colour for heavy lines
# yheavyw	width of heavy lines
# ylabels	array of labels for y axis
# ylc		constant for logical y
# yldepth	print labels up to this depth
# ylightc	colour for light lines
# ylightw	width of light lines
# ylm		multiplier for logical y
# ymarkcen	width for centering labels
# ymarkgap	gap between adjacent marks 
# ymarkmax	tallest mark
# ymarkmin	smallest mark	    
# ymarkmul	step added for each depth
# ymidc		colour for mid lines
# ymidw		width of mid lines
# ysize		font size used on y axis
# ytitle	title for y axis
# yx0		y axis left
# yx1		y axis right (same as xx0)
# yy		temp y used by xdraw
# yy0		y axis bottom
# yy1		y axis top

sub draw_scales {
    my ($o) = @_;
    my $ch = $o->{ch};
    my $x = $o->{x};
    my $y = $o->{y};
    my $xfactors = array_as_string( @{$x->{factors}} );
    my $yfactors = array_as_string( @{$y->{factors}} );
    my $xlabels = array_as_string( @{$x->{labels}} );
    my $ylabels = array_as_string( @{$y->{labels}} );

    $o->{ps}->add_to_page( <<END_SCALES );
	gpaperdict begin
	$ch->{gx0} $ch->{gy0} $ch->{gx1} $ch->{gy1} $ch->{bgnd} $ch->{fgnd} graph_area
	$ch->{hx0} $ch->{hy0} $ch->{hx1} $ch->{hy1} heading_area
	/$ch->{hfont} $ch->{hsize} $ch->{hcol} ($ch->{title}) heading_labels
	$ch->{xx0} $ch->{xy0} $ch->{xx1} $ch->{xy1} xaxis_area
	$ch->{yx0} $ch->{yy0} $ch->{yx1} $ch->{yy1} yaxis_area
	$x->{heavyw} $x->{heavycol} $x->{midw} $x->{midcol} $x->{lightw} $x->{lightcol} xaxis_colors
	$y->{heavyw} $y->{heavycol} $y->{midw} $y->{midcol} $y->{lightw} $y->{lightcol} yaxis_colors
	$x->{markmin} $x->{markmul} $x->{markmax} $x->{markgap} $x->{markcen} /$x->{draw} xaxis_marks
	$y->{markmin} $y->{markmul} $y->{markmax} $y->{markgap} $y->{markcen} /$y->{draw} yaxis_marks
	$xfactors $xlabels $x->{ldepth} $x->{flags}
	    /$x->{font} $x->{fsize} $x->{fcol} ($x->{title}) xaxis_labels
	$yfactors $ylabels $y->{ldepth} $y->{flags}
	    /$y->{font} $y->{fsize} $y->{fcol} ($y->{title}) yaxis_labels
	drawgpaper
	$x->{l2pm} $x->{l2pc} $y->{l2pm} $y->{l2pc} conv_consts
	end
END_SCALES
}

=head3 draw_scales()

Commits to postscript the settings collected and calculted by C<new>.  Under normal circumstances this should not
need to be called.  It is only necessary if the layout option C<no_drawing> has been specified.

=head1 BUGS

Very likely.  This is still alpha software and has been tested in fairly limited conditions.

=head1 AUTHOR

Chris Willmot, chris@willmot.org.uk

=head1 SEE ALSO

L<PostScript::File>, L<PostScript::Graph::Style> and L<PostScript::Graph::Key> for the other modules in this suite.

L<PostScript::Graph::Bar>, L<PostScript::Graph::XY> and L<Finance::Shares::Chart> for modules that use this one.

=cut


1;
