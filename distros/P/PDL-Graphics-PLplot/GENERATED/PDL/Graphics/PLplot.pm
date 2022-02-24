#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Graphics::PLplot;

our @EXPORT_OK = qw(PL_PARSE_PARTIAL PL_PARSE_FULL PL_PARSE_QUIET PL_PARSE_NODELETE PL_PARSE_SHOWALL PL_PARSE_OVERRIDE PL_PARSE_NOPROGRAM PL_PARSE_NODASH PL_PARSE_SKIP PL_NOTSET DRAW_LINEX DRAW_LINEY DRAW_LINEXY MAG_COLOR BASE_CONT TOP_CONT SURF_CONT DRAW_SIDES FACETED MESH PL_FCI_SANS PL_FCI_MONO PLK_BackSpace PLK_Tab PLK_Linefeed PLK_Return PLK_Escape PLK_Delete PLK_Clear PLK_Pause PLK_Scroll_Lock PLK_Home PLK_Left PLK_Up PLK_Right PLK_Down PLK_Prior PLK_Next PLK_End PLK_Begin PLK_Select PLK_Print PLK_Execute PLK_Insert PLK_Undo PLK_Redo PLK_Menu PLK_Find PLK_Cancel PLK_Help PLK_Break PLK_Mode_switch PLK_script_switch PLK_Num_Lock PLK_KP_Space PLK_KP_Tab PLK_KP_Enter PLK_KP_F1 PLK_KP_F2 PLK_KP_F3 PLK_KP_F4 PLK_KP_Equal PLK_KP_Multiply PLK_KP_Add PLK_KP_Separator PLK_KP_Subtract PLK_KP_Decimal PLK_KP_Divide PLK_KP_0 PLK_KP_1 PLK_KP_2 PLK_KP_3 PLK_KP_4 PLK_KP_5 PLK_KP_6 PLK_KP_7 PLK_KP_8 PLK_KP_9 PLK_F1 PLK_F2 PLK_F3 PLK_F4 PLK_F5 PLK_F6 PLK_F7 PLK_F8 PLK_F9 PLK_F10 PLK_F11 PLK_L1 PLK_F12 PLK_L2 PLK_F13 PLK_L3 PLK_F14 PLK_L4 PLK_F15 PLK_L5 PLK_F16 PLK_L6 PLK_F17 PLK_L7 PLK_F18 PLK_L8 PLK_F19 PLK_L9 PLK_F20 PLK_L10 PLK_F21 PLK_R1 PLK_F22 PLK_R2 PLK_F23 PLK_R3 PLK_F24 PLK_R4 PLK_F25 PLK_R5 PLK_F26 PLK_R6 PLK_F27 PLK_R7 PLK_F28 PLK_R8 PLK_F29 PLK_R9 PLK_F30 PLK_R10 PLK_F31 PLK_R11 PLK_F32 PLK_R12 PLK_R13 PLK_F33 PLK_F34 PLK_R14 PLK_F35 PLK_R15 PLK_Shift_L PLK_Shift_R PLK_Control_L PLK_Control_R PLK_Caps_Lock PLK_Shift_Lock PLK_Meta_L PLK_Meta_R PLK_Alt_L PLK_Alt_R PLK_Super_L PLK_Super_R PLK_Hyper_L PLK_Hyper_R GRID_CSA GRID_DTLI GRID_NNI GRID_NNIDW GRID_NNLI GRID_NNAIDW PL_X_AXIS PL_Y_AXIS PL_Z_AXIS PL_COLORBAR_SHADE PL_COLORBAR_SHADE_LABEL PL_COLORBAR_IMAGE PL_COLORBAR_GRADIENT PL_COLORBAR_CAP_NONE PL_COLORBAR_CAP_LOW PL_COLORBAR_CAP_HIGH PL_COLORBAR_LABEL_LEFT PL_COLORBAR_LABEL_RIGHT PL_COLORBAR_LABEL_TOP PL_COLORBAR_LABEL_BOTTOM PL_LEGEND_BACKGROUND PL_LEGEND_BOUNDING_BOX PL_LEGEND_COLOR_BOX PL_LEGEND_LINE PL_LEGEND_NONE PL_LEGEND_ROW_MAJOR PL_LEGEND_SYMBOL PL_LEGEND_TEXT_LEFT PL_POSITION_BOTTOM PL_POSITION_INSIDE PL_POSITION_LEFT PL_POSITION_OUTSIDE PL_POSITION_RIGHT PL_POSITION_SUBPAGE PL_POSITION_TOP PL_POSITION_VIEWPORT plplot_use_standard_argument_order pladv plaxes plbin plbop plbox plbox3 plclear plcol0 plcol1 plcpstrm pldid2pc pldip2dc plend plend1 plenv plenv0 pleop plerrx plerry plfamadv plfill3 plflush plfont plfontld plgchr plgcompression plgdidev plgdiori plgdiplt plgfam plglevel plgpage plgra plgspa plgvpd plgvpw plgxax plgyax plgzax plinit pljoin pllab pllightsource pllsty plmtex plmtex3 plpat plprec plpsty plptex plptex3 plreplot plschr plscmap0n plscmap1n plscol0 plscolbg plscolor plscompression plsdev plgDevs plgFileDevs plsdidev plsdimap plsdiori plsdiplt plsdiplz pl_setcontlabelparam pl_setcontlabelformat plsfam plsfnam plsmaj plsmin plsori plspage plspause plsstrm plssub plssym plstar plstart plstripa plstripd plsvpa plsxax plsxwin plsyax plszax pltext plvasp plvpas plvpor plvsta plw3d plwidth plwind plsetopt plP_gpixmm plscolbga plscol0a plline plpath plcolorpoints plsmem plfbox plfbox1 plunfbox plunfbox1 plParseOpts plpoin plpoin3 plline3 plpoly3 plhist plfill plgradient plsym plsurf3d plsurf3dl plstyl plseed plrandd pltr0 pltr1 pltr2 plAllocGrid plFreeGrid plAlloc2dGrid plFree2dGrid init_pltr plmap plstring plstring3 plmeridians plshades plcont plmesh plmeshc plot3d plot3dc plscmap1l plshade1 plimage plimagefr plxormod plGetCursor plgstrm plgdev plgfnam plmkstrm plgver plstripc plgriddata plarc plstransform plslabelfunc pllegend plspal0 plspal1 plbtime plconfigtime plctime pltimefmt plsesc plvect plsvect plhlsrgb plgcol0 plgcolbg plscmap0 plscmap1 plgcol0a plgcolbga plscmap0a plscmap1a plscmap1la plgfont plsfont plcalc_world plgfci plsfci pl_cmd pl_setCairoCtx );
our %EXPORT_TAGS = (Func=>\@EXPORT_OK);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;


   
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Graphics::PLplot ;






#line 6 "plplot.pd"


use Carp qw(confess);

our $VERSION;
BEGIN {
$VERSION = '0.81'
};

=head1 NAME

PDL::Graphics::PLplot - Object-oriented interface from perl/PDL to the PLPLOT plotting library

=head1 SYNOPSIS

  use PDL;
  use PDL::Graphics::PLplot;

  my $pl = PDL::Graphics::PLplot->new (DEV => "png", FILE => "test.png");
  my $x  = sequence(10);
  my $y  = $x**2;
  $pl->xyplot($x, $y);
  $pl->close;

Only version 5.15.0+ of PLplot is fully supported, due to a C-level API change
that is invisible at PDL-level. However, the library does support installation
with PLplot 5.13.0+.

For more information on PLplot, see

 http://www.plplot.org/

Also see the test file, F<t/plplot.t> in this distribution for some working examples.

=head1 LONG NAMES

If you are annoyed by the long constructor call, consider installing the
L<aliased|aliased> CPAN package. Using C<aliased>, the above example
becomes

  use PDL;
  use aliased 'PDL::Graphics::PLplot';

  my $pl = PLplot->new (DEV => "png", FILE => "test.png");
  my $x  = sequence(10);
  # etc, as above

=head1 DESCRIPTION

This is the PDL interface to the PLplot graphics library.  It provides
a familiar 'perlish' Object Oriented interface as well as access to
the low-level PLplot commands from the C-API.

=head1 OPTIONS

The following options are supported.  Most options can be used
with any function.  A few are only supported on the call to 'new'.

=head2 Options used upon creation of a PLplot object (with 'new'):

=head3 BACKGROUND

Set the color for index 0, the plot background

=head3 DEV

Set the output device type.  To see a list of allowed types, try:

  PDL::Graphics::PLplot->new();

=for example

   PDL::Graphics::PLplot->new(DEV => 'png', FILE => 'test.png');

=head3 FILE

Set the output file or display.  For file output devices, sets
the output file name.  For graphical displays (like C<'xwin'>) sets
the name of the display, eg (C<'hostname.foobar.com:0'>)

=for example

   PDL::Graphics::PLplot->new(DEV => 'png',  FILE => 'test.png');
   PDL::Graphics::PLplot->new(DEV => 'xwin', FILE => ':0');

=head3 OPTS

Set plotting options.  See the PLplot documentation for the complete
listing of available options.  The value of C<'OPTS'> must be a hash
reference, whose keys are the names of the options.  For instance, to obtain
PostScript fonts with the ps output device, use:

=for example

   PDL::Graphics::PLplot->new(DEV => 'ps', OPTS => {drvopt => 'text=1'});

=head3 MEM

This option is used in conjunction with C<< DEV => 'mem' >>.  This option
takes as input a PDL image and allows one to 'decorate' it using PLplot.
The 'decorated' PDL image can then be written to an image file using,
for example, L<PDL::IO::Pic|PDL::IO::Pic>.  This option may not be available if
plplot does not include the 'mem' driver.

=for example

  # read in Earth image and draw an equator.
  my $pl = PDL::Graphics::PLplot->new (MEM => $earth, DEV => 'mem');
  my $x  = pdl(-180, 180);
  my $y  = zeroes(2);
  $pl->xyplot($x, $y,
              BOX => [-180,180,-90,90],
              VIEWPORT => [0.0, 1.0, 0.0, 1.0],
              XBOX => '', YBOX => '',
              PLOTTYPE => 'LINE');
  $pl->close;

=head3 FRAMECOLOR

Set color index 1, the frame color

=head3 JUST

A flag used to specify equal scale on the axes.  If this is
not specified, the default is to scale the axes to fit best on
the page.

=for example

  PDL::Graphics::PLplot->new(DEV => 'png',  FILE => 'test.png', JUST => 1);

=head3 ORIENTATION

The orientation of the plot:

  0 --   0 degrees (landscape mode)
  1 --  90 degrees (portrait mode)
  2 -- 180 degrees (seascape mode)
  3 -- 270 degrees (upside-down mode)

Intermediate values (0.2) are acceptable if you are feeling daring.

=for example

  # portrait orientation
  PDL::Graphics::PLplot->new(DEV => 'png',  FILE => 'test.png', ORIENTATION => 1);

=head3 PAGESIZE

Set the size in pixels of the output page.

=for example

  # PNG 500 by 600 pixels
  PDL::Graphics::PLplot->new(DEV => 'png',  FILE => 'test.png', PAGESIZE => [500,600]);

=head3 SUBPAGES

Set the number of sub pages in the plot, [$nx, $ny]

=for example

  # PNG 300 by 600 pixels
  # Two subpages stacked on top of one another.
  PDL::Graphics::PLplot->new(DEV => 'png',  FILE => 'test.png', PAGESIZE => [300,600],
                                              SUBPAGES => [1,2]);

=head2 Options used after initialization (after 'new')

=head3 BOX

Set the plotting box in world coordinates.  Used to explicitly
set the size of the plotting area.

=for example

 my $pl = PDL::Graphics::PLplot->new(DEV => 'png',  FILE => 'test.png');
 $pl->xyplot ($x, $y, BOX => [0,100,0,200]);

=head3 CHARSIZE

Set the size of text in multiples of the default size.
C<< CHARSIZE => 1.5 >> gives characters 1.5 times the normal size.

=head3 COLOR

Set the current color for plotting and character drawing.
Colors are specified not as color indices but as RGB triples.
Some pre-defined triples are included:

  BLACK        GREEN        WHEAT        BLUE
  RED          AQUAMARINE   GREY         BLUEVIOLET
  YELLOW       PINK         BROWN        CYAN
  TURQUOISE    MAGENTA      SALMON       WHITE
  ROYALBLUE    DEEPSKYBLUE  VIOLET       STEELBLUE1
  DEEPPINK     MAGENTA      DARKORCHID1  PALEVIOLETRED2
  TURQUOISE1   LIGHTSEAGREEN SKYBLUE     FORESTGREEN
  CHARTREUSE3  GOLD2        SIENNA1      CORAL
  HOTPINK      LIGHTCORAL   LIGHTPINK1   LIGHTGOLDENROD

=for example

 # These two are equivalent:
 $pl->xyplot ($x, $y, COLOR => 'YELLOW');
 $pl->xyplot ($x, $y, COLOR => [0,255,0]);

=head3 CONTOURLABELS

Control of labels for contour plots.

Must either be 0 (turn off contour labels), 1 (turn on default contour labels)
or a five element array:

 offset:  Offset of label from contour line (if set to 0.0, labels are printed on the lines). Default value is 0.006.
 size:    Font height for contour labels (normalized). Default value is 0.3.
 spacing: Spacing parameter for contour labels. Default value is 0.1.
 lexp:    If the contour numerical label is greater than 10^(lexp) or less than 10^(-lexp),
          then the exponential format is used. Default value of lexp is 4.
 sigdig:  Number of significant digits. Default value is 2";

=for example

 $pl->shadeplot ($z, $nsteps, BOX => [-1, 1, -1, 1], PLOTTYPE => 'CONTOUR', CONTOURLABELS => [0.004, 0.2, 0.2, 4, 2]);
 $pl->shadeplot ($z, $nsteps, BOX => [-1, 1, -1, 1], PLOTTYPE => 'CONTOUR', CONTOURLABELS => 0); # turn off labels
 $pl->shadeplot ($z, $nsteps, BOX => [-1, 1, -1, 1], PLOTTYPE => 'CONTOUR', CONTOURLABELS => 1); # use default labels

=head3 GRIDMAP

Set a user-defined grid map.  This is an X and Y vector that
tells what are the world coordinates for each pixel in $z
It is used in 'shadeplot' for non-standard mappings between the
input 2D surface to plot and the world coordinates.  For example
if your surface does not completely fill up the plotting window.

=for example

 my $z = $surface; # 2D PDL to plot (generated elsewhere)
 my $nlevels = 20;
 my ($nx, $ny) = $z->dims;
 my @zbounds = ($minx, $maxx, $miny, $maxy);

 # Map X coords linearly to X range, Y coords linearly to Y range
 my $xmap = ((sequence($nx)*(($zbounds[1] - $zbounds[0])/($nx - 1))) + $zbounds[0]);
 my $ymap = ((sequence($ny)*(($zbounds[3] - $zbounds[2])/($ny - 1))) + $zbounds[2]);
 $pl->shadeplot ($z, $nlevels, PALETTE => 'GREENRED', GRIDMAP => [$xmap, $ymap]);

=head3 GRIDMAP2

Set a user-defined two dimensional grid map.  These are 2D X and Y matrices that
tell what are the world coordinates for each pixel in $z
It is used in 'shadeplot' for non-standard mappings between the
input 2D surface to plot and the world coordinates, for example
irregular grids like polar projections.

=for example

 my $r_pts     = 40;
 my $theta_pts = 40;
 my $pi        = 4*atan2(1,1);
 my $nlevels   = 20;

 my $r     = ((sequence ($r_pts)) / ($r_pts - 1))->dummy (1, $theta_pts);
 my $z     = $r;  # or any other 2D surface to plot...
 my $theta = ((2 * $pi / ($theta_pts - 2)) * sequence ($theta_pts))->dummy (0, $r_pts);
 my $xmap  = $r * cos ($theta);
 my $ymap  = $r * sin ($theta);

 $pl->shadeplot ($z, $nlevels, PLOTTYPE => 'CONTOUR',
                               JUST     => 1,
                               BOX      => [-1,1,-1,1],
                               PALETTE  => 'GREENRED',
                               GRIDMAP2 => [$xmap, $ymap]);

=head3 LINEWIDTH

Set the line width for plotting.  Values range from 1 to a device dependent maximum.

=head3 LINESTYLE

Set the line style for plotting.  Pre-defined line styles use values 1 to 8, one being
a solid line, 2-8 being various dashed patterns.

=head3 MAJTICKSIZE

Set the length of major ticks as a fraction of the default setting.
One (default) means leave these ticks the normal size.

=head3 MINTICKSIZE

Set the length of minor ticks (and error bar terminals) as a fraction of the default setting.
One (default) means leave these ticks the normal size.

=head3 NXSUB

The number of minor tick marks between each major tick mark on the X axis.
Specify zero (default) to let PLplot compute this automatically.

=head3 NYSUB

The number of minor tick marks between each major tick mark on the Y axis.
Specify zero (default) to let PLplot compute this automatically.

=head3 PALETTE

Load pre-defined color map 1 color ranges.  Currently, values include:

  RAINBOW   -- from Red to Violet through the spectrum
  REVERSERAINBOW   -- Violet through Red
  GREYSCALE -- from black to white via grey.
  REVERSEGREYSCALE -- from white to black via grey.
  GREENRED  -- from green to red
  REDGREEN  -- from red to green

=for example

 # Plot x/y points with the z axis in color
 $pl->xyplot ($x, $y, PALETTE => 'RAINBOW', PLOTTYPE => 'POINTS', COLORMAP => $z);

=head3 PLOTTYPE

Specify which type of XY or shade plot is desired:

  LINE       -- A line
  POINTS     -- A bunch of symbols
  LINEPOINTS -- both

  or, for 'shadeplot':
  CONTOUR    -- A contour plot of 2D data
  SHADE      -- A shade plot of 2D data

=head3 STACKED_BAR_COLORS

For 'bargraph', request a stacked bar chart.
Must contain a reference to a perl list of color names or RGB triples.

=for example

 # $labels is a reference to a perl array with N x-axis labels
 # $values is an NxM PDL where M is the number of stacked bars (in this case 2,
 # since STACKED_BAR_COLORS contains two colors).
 $pl->bargraph($labels, $values, STACKED_BAR_COLORS => ['GREEN', [128,0,55]);

=head3 SUBPAGE

Set which subpage to plot on.  Subpages are numbered 1 to N.
A zero can be specified meaning 'advance to the next subpage' (just a call to
L<pladv()|/pladv>).

=for example

  my $pl = PDL::Graphics::PLplot->new(DEV      => 'png',
                                        FILE     => 'test.png',
                                        SUBPAGES => [1,2]);
  $pl->xyplot ($x, $y, SUBPAGE => 1);
  $pl->xyplot ($a, $b, SUBPAGE => 2);


=head3 SYMBOL

Specify which symbol to use when plotting C<< PLOTTYPE => 'POINTS' >>.
A large variety of symbols are available, see:
http://plplot.sourceforge.net/examples-data/demo07/x07.*.png, where * is 01 - 17.
You are most likely to find good plotting symbols in the 800s:
http://plplot.sourceforge.net/examples-data/demo07/x07.06.png

=head3 SYMBOLSIZE

Specify the size of symbols plotted in multiples of the default size (1).
Value are real numbers from 0 to large.

=head3 TEXTPOSITION

Specify the placement of text.  Either relative to border, specified as:

 [$side, $disp, $pos, $just]

Where

  side = 't', 'b', 'l', or 'r' for top, bottom, left and right
  disp is the number of character heights out from the edge
  pos  is the position along the edge of the viewport, from 0 to 1.
  just tells where the reference point of the string is: 0 = left, 1 = right, 0.5 = center.

or inside the plot window, specified as:

 [$x, $y, $dx, $dy, $just]

Where

  x  = x coordinate of reference point of string.
  y  = y coordinate of reference point of string.
  dx   Together with dy, this specifies the inclination of the string.
       The baseline of the string is parallel to a line joining (x, y) to (x+dx, y+dy).
  dy   Together with dx, this specifies the inclination of the string.
  just Specifies the position of the string relative to its reference point.
       If just=0, the reference point is at the left and if just=1,
       it is at the right of the string. Other values of just give
       intermediate justifications.

=for example

 # Plot text on top of plot
 $pl->text ("Top label",  TEXTPOSITION => ['t', 4.0, 0.5, 0.5]);

 # Plot text in plotting area
 $pl->text ("Line label", TEXTPOSITION => [50, 60, 5, 5, 0.5]);

=head3 TITLE

Add a title on top of a plot.

=for example

 # Plot text on top of plot
 $pl->xyplot ($x, $y, TITLE => 'X vs. Y');

=head3 UNFILLED_BARS

For 'bargraph', if set to true then plot the bars as outlines
in the current color and not as filled boxes

=for example

 # Plot text on top of plot
 $pl->bargraph($labels, $values, UNFILLED_BARS => 1);

=head3 VIEWPORT

Set the location of the plotting window on the page.
Takes a four element array ref specifying:

 xmin -- The coordinate of the left-hand edge of the viewport. (0 to 1)
 xmax -- The coordinate of the right-hand edge of the viewport. (0 to 1)
 ymin -- The coordinate of the bottom edge of the viewport. (0 to 1)
 ymax -- The coordinate of the top edge of the viewport. (0 to 1)

You will need to use this to make color keys or insets.

=for example

 # Make a small plotting window in the lower left of the page
 $pl->xyplot ($x, $y, VIEWPORT => [0.1, 0.5, 0.1, 0.5]);

 # Also useful in creating color keys:
 $pl->xyplot   ($x, $y, PALETTE => 'RAINBOW', PLOTTYPE => 'POINTS', COLORMAP => $z);
 $pl->colorkey ($z, 'v', VIEWPORT => [0.93, 0.96, 0.15, 0.85]);

 # Plot an inset; first the primary data and then the inset. In this
 # case, the inset contains a selection of the orignal data
 $pl->xyplot ($x, $y);
 $pl->xyplot (where($x, $y, $x < 1.2), VIEWPORT => [0.7, 0.9, 0.6, 0.8]);

=head3 XBOX

Specify how to label the X axis of the plot as a string of option letters:

  a: Draws axis, X-axis is horizontal line (y=0), and Y-axis is vertical line (x=0).
  b: Draws bottom (X) or left (Y) edge of frame.
  c: Draws top (X) or right (Y) edge of frame.
  d: Plot labels as date / time. Values are assumed to be seconds since the epoch (as used by gmtime).
  f: Always use fixed point numeric labels.
  g: Draws a grid at the major tick interval.
  h: Draws a grid at the minor tick interval.
  i: Inverts tick marks, so they are drawn outwards, rather than inwards.
  l: Labels axis logarithmically. This only affects the labels, not the data,
     and so it is necessary to compute the logarithms of data points before
     passing them to any of the drawing routines.
  m: Writes numeric labels at major tick intervals in the
     unconventional location (above box for X, right of box for Y).
  n: Writes numeric labels at major tick intervals in the conventional location
     (below box for X, left of box for Y).
  s: Enables subticks between major ticks, only valid if t is also specified.
  t: Draws major ticks.

The default is C<'BCNST'> which draws lines around the plot, draws major and minor
ticks and labels major ticks.

=for example

 # plot two lines in a box with independent X axes labeled
 # differently on top and bottom
 $pl->xyplot($x1, $y, XBOX  => 'bnst',  # bottom line, bottom numbers, ticks, subticks
	              YBOX  => 'bnst'); # left line, left numbers, ticks, subticks
 $pl->xyplot($x2, $y, XBOX => 'cmst', # top line, top numbers, ticks, subticks
	              YBOX => 'cst',  # right line, ticks, subticks
	              BOX => [$x2->minmax, $y->minmax]);

=head3 XERRORBAR

Used only with L</xyplot>.  Draws horizontal error bars at all points (C<$x>, C<$y>) in the plot.
Specify a PDL containing the same number of points as C<$x> and C<$y>
which specifies the width of the error bar, which will be centered at (C<$x>, C<$y>).

=head3 XLAB

Specify a label for the X axis.

=head3 XTICK

Interval (in graph units/world coordinates) between major x axis tick marks.
Specify zero (default) to allow PLplot to compute this automatically.

=head3 YBOX

Specify how to label the Y axis of the plot as a string of option letters.
See L</XBOX>.

=head3 YERRORBAR

Used only for xyplot.  Draws vertical error bars at all points (C<$x>, C<$y>) in the plot.
Specify a PDL containing the same number of points as C<$x> and C<$y>
which specifies the width of the error bar, which will be centered at (C<$x>, C<$y>).

=head3 YLAB

Specify a label for the Y axis.

=head3 YTICK

Interval (in graph units/world coordinates) between major y axis tick marks.
Specify zero (default) to allow PLplot to compute this automatically.

=head3 ZRANGE

For L</xyplot> (when C<COLORMAP> is specified), for
L</shadeplot> and for L</colorkey>.
Normally, the range of the Z variable (color) is taken as
C<< $z->minmax >>.  If a different range is desired,
specify it in C<ZRANGE>, like so:

  $pl->shadeplot ($z, $nlevels, PALETTE => 'GREENRED', ZRANGE => [0,100]);

or

  $pl->xyplot ($x, $y, PALETTE  => 'RAINBOW', PLOTTYPE => 'POINTS',
	               COLORMAP => $z,        ZRANGE => [-90,-20]);
  $pl->colorkey  ($z, 'v', VIEWPORT => [0.93, 0.96, 0.13, 0.85],
                       ZRANGE => [-90,-20]);

=head1 METHODS

These are the high-level, object oriented methods for PLplot.

=head2 new

=for ref

Create an object representing a plot.

=for usage

 Arguments:
 none.

 Supported options:
 BACKGROUND
 DEV
 FILE
 FRAMECOLOR
 JUST
 PAGESIZE
 SUBPAGES

=for example

  my $pl = PDL::Graphics::PLplot->new(DEV => 'png',  FILE => 'test.png');


=head2 setparm

=for ref

Set options for a plot object.

=for usage

 Arguments:
 none.

 Supported options:
 All options except:

 BACKGROUND
 DEV
 FILE
 FRAMECOLOR
 JUST
 PAGESIZE
 SUBPAGES

(These must be set in call to 'new'.)

=for example

  $pl->setparm (TEXTSIZE => 2);

=head2 xyplot

=for ref

Plot XY lines and/or points.  Also supports color scales for points.
This function works with bad values.  If a bad value is specified for
a points plot, it is omitted.  If a bad value is specified for a line
plot, the bad value makes a gap in the line.  This is useful for
drawing maps; for example C<$x> and C<$y> can be the continent boundary
latitude and longitude.

=for usage

 Arguments:
 $x, $y

 Supported options:
 All options except:

 BACKGROUND
 DEV
 FILE
 FRAMECOLOR
 JUST
 PAGESIZE
 SUBPAGES

(These must be set in call to 'new'.)

=for example

  $pl->xyplot($x, $y, PLOTTYPE => 'POINTS', COLOR => 'BLUEVIOLET', SYMBOL => 1, SYMBOLSIZE => 4);
  $pl->xyplot($x, $y, PLOTTYPE => 'LINEPOINTS', COLOR => [50,230,30]);
  $pl->xyplot($x, $y, PALETTE => 'RAINBOW', PLOTTYPE => 'POINTS', COLORMAP => $z);

=head2 stripplots

=for ref

Plot a set of strip plots with a common X axis, but with different Y axes.
Looks like a stack of long, thin XY plots, all line up on the same X axis.

=for usage

 Arguments:
 $xs -- 1D PDL with common X axis values, length = N
 $ys -- reference to a list of 1D PDLs with Y-axis values, length = N
        or 2D PDL with N x M elements
 -- OR --
 $xs -- reference to a list of 1D PDLs with X-axis values
 $ys -- reference to a list of 1D PDLs with Y-axis values
 %opts -- Options hash

 Supported options:
 All options except:

 BACKGROUND
 DEV
 FILE
 FRAMECOLOR
 JUST
 PAGESIZE
 SUBPAGES

(These must be set in call to 'new'.)

=for example

  my $x  = sequence(20);
  my $y1  = $x**2;
  my $y2  = sqrt($x);
  my $y3  = $x**3;
  my $y4  = sin(($x/20) * 2 * $pi);
  $ys  = cat($y1, $y2, $y3, $y4);
  $pl->stripplots($x, $ys, PLOTTYPE => 'LINE', TITLE => 'functions',
                           YLAB     => ['x**2', 'sqrt(x)', 'x**3', 'sin(x/20*2pi)'],
                           COLOR    => ['GREEN', 'DEEPSKYBLUE', 'DARKORCHID1', 'DEEPPINK'], XLAB => 'X label');
  # Equivalent to above:
  $pl->stripplots($x, [$y1, $y2, $y3, $y4],
                           PLOTTYPE => 'LINE', TITLE => 'functions',
                           YLAB     => ['x**2', 'sqrt(x)', 'x**3', 'sin(x/20*2pi)'],
                           COLOR    => ['GREEN', 'DEEPSKYBLUE', 'DARKORCHID1', 'DEEPPINK'], XLAB => 'X label');

  # Here's something a bit different. Notice that different xs have
  # different lengths.
  $x1  = sequence(20);
  $y1  = $x1**2;

  $x2  = sequence(18);
  $y2  = sqrt($x2);

  $x3  = sequence(24);
  $y3  = $x3**3;

  my $x4  = sequence(27);
  $a  = ($x4/20) * 2 * $pi;
  my $y4  = sin($a);

  $xs  = [$x1, $x2, $x3, $x4];
  $ys  = [$y1, $y2, $y3, $y4];
  $pl->stripplots($xs, $ys, PLOTTYPE => 'LINE', TITLE => 'functions',
                YLAB => ['x**2', 'sqrt(x)', 'x**3', 'sin(x/20*2pi)'],
                         COLOR => ['GREEN', 'DEEPSKYBLUE', 'DARKORCHID1', 'DEEPPINK'], XLAB => 'X label');

In addition, COLOR may be specified as a reference to a list of colors.  If
this is done, the colors are applied separately to each plot.

Also, the options Y_BASE and Y_GUTTER can be specified.  Y_BASE gives the Y offset
of the bottom of the lowest plot (0-1, specified like a VIEWPORT, defaults to 0.1) and Y_GUTTER
gives the gap between the graphs (0-1, default = 0.02).

=head2 colorkey

=for ref

Plot a color key showing which color represents which value

=for usage

 Arguments:
 $range   : A PDL which tells the range of the color values
 $orientation : 'v' for vertical color key, 'h' for horizontal

 Supported options:
 All options except:

 BACKGROUND
 DEV
 FILE
 FRAMECOLOR
 JUST
 PAGESIZE
 SUBPAGES

(These must be set in call to 'new'.)

=for example

  # Plot X vs. Y with Z shown by the color.  Then plot
  # vertical key to the right of the original plot.
  $pl->xyplot ($x, $y, PALETTE => 'RAINBOW', PLOTTYPE => 'POINTS', COLORMAP => $z);
  $pl->colorkey ($z, 'v', VIEWPORT => [0.93, 0.96, 0.15, 0.85]);


=head2 shadeplot

=for ref

Create a shaded contour plot of 2D PDL 'z' with 'nsteps' contour levels.
Linear scaling is used to map the coordinates of Z(X, Y) to world coordinates
via the L</BOX> option.

=for usage

 Arguments:
 $z : A 2D PDL which contains surface values at each XY coordinate.
 $nsteps : The number of contour levels requested for the plot.

 Supported options:
 All options except:

 BACKGROUND
 DEV
 FILE
 FRAMECOLOR
 JUST
 PAGESIZE
 SUBPAGES

(These must be set in call to 'new'.)

=for example

  # vertical key to the right of the original plot.
  # The BOX must be specified to give real coordinate values to the $z array.
  $pl->shadeplot ($z, $nsteps, BOX => [-1, 1, -1, 1], PALETTE => 'RAINBOW', ZRANGE => [0,100]);
  $pl->colorkey  ($z, 'v', VIEWPORT => [0.93, 0.96, 0.15, 0.85], ZRANGE => [0,100]);

=head2 histogram

=for ref

Create a histogram of a 1-D variable.

=for usage

 Arguments:
 $x : A 1D PDL
 $nbins : The number of bins to use in the histogram.

 Supported options:
 All options except:

 BACKGROUND
 DEV
 FILE
 FRAMECOLOR
 JUST
 PAGESIZE
 SUBPAGES

(These must be set in call to 'new'.)

=for example

  $pl->histogram ($x, $nbins, BOX => [$min, $max, 0, 100]);

=head2 histogram1

=for ref

Create a histogram of a 1-D variable.  This alternative to 'histogram'
creates filled boxes and also handles Y-axis scaling better.

=for usage

 Arguments:
 $x : A 1D PDL
 $nbins : The number of bins to use in the histogram.

 Supported options:
 All options except:

 BACKGROUND
 DEV
 FILE
 FRAMECOLOR
 JUST
 PAGESIZE
 SUBPAGES

(These must be set in call to 'new'.)

=for example

  $pl->histogram1 ($x, $nbins, COLOR => 'GREEN');

=head2 bargraph

=for ref

Simple utility to plot a bar chart with labels on the X axis.
The usual options can be specified, plus one other:  MAXBARLABELS
specifies the maximum number of labels to allow on the X axis.
The default is 20.  If this value is exceeded, then every other
label is plotted.  If twice MAXBARLABELS is exceeded, then only
every third label is printed, and so on.

if UNFILLED_BARS is set to true, then plot the bars as outlines
and not as filled rectangles.

A stacked bar graph can be created if the STACKED_BAR_COLORS
option is set.  The option takes a reference to a perl list of
color names or RGB triplets.  If this option is set, then $x should
not be a 1-D PDL of N bar heights, but a 2D PDL of NxM where N is the
number of bars and M is the number of colors in STACKED_BAR_COLORS.

=for usage

 Arguments:
 $labels -- A reference to a perl list of strings.
 $values -- A PDL of values to be plotted.

 Supported options:
 All options except:

 BACKGROUND
 DEV
 FILE
 FRAMECOLOR
 JUST
 PAGESIZE
 SUBPAGES

(These must be set in call to 'new'.)

=for example

  $labels = ['one', 'two', 'three'];
  $values = pdl(1, 2, 3);

  # Note if TEXTPOSITION is specified, it must be in 4 argument mode (border mode):
  # [$side, $disp, $pos, $just]
  #
  # Where side = 't', 'b', 'l', or 'r' for top, bottom, left and right
  #              'tv', 'bv', 'lv' or 'rv' for top, bottom, left or right perpendicular to the axis.
  #
  #     disp is the number of character heights out from the edge
  #     pos  is the position along the edge of the viewport, from 0 to 1.
  #     just tells where the reference point of the string is: 0 = left, 1 = right, 0.5 = center.
  #
  # The '$pos' entry will be ignored (computed by the bargraph routine)
  $pl->bargraph($labels, $values, MAXBARLABELS => 30, TEXTPOSITION => ['bv', 0.5, 1.0, 1.0]);

  # A stacked bar chart:
  $labels = ['label1', 'label2', 'label3'];
  $values = pdl([[50,40,60],   # green bars
                 [20,10,30]]); # purple ([128, 0, 56]) bars
  $pl->bargraph ($labels, $values, STACKED_BAR_COLORS => ['GREEN', [128, 0, 56]])

=head2 text

=for ref

Write text on a plot.  Text can either be written
with respect to the borders or at an arbitrary location and angle
(see the L</TEXTPOSITION> entry).

=for usage

 Arguments:
 $t : The text.

 Supported options:
 All options except:

 BACKGROUND
 DEV
 FILE
 FRAMECOLOR
 JUST
 PAGESIZE
 SUBPAGES

(These must be set in call to 'new'.)

=for example

  $pl->text("Count", COLOR => 'PINK',
	    TEXTPOSITION => ['t', 3, 0.5, 0.5]); # top, 3 units out, string ref. pt in
                                                 # center of string, middle of axis

=head2 close

=for ref

Close a PLplot object, writing out the file and cleaning up.

=for usage

Arguments:
None

Returns:
Nothing

This closing of the PLplot object can be done explicitly though the
'close' method.  Alternatively, a DESTROY block does an automatic
close whenever the PLplot object passes out of scope.

=for example

  $pl->close;

=cut

# Colors (from rgb.txt) are stored as RGB triples
# with each value from 0-255
sub cc2t { [map {hex} split ' ', shift] }
our %_constants = (
	       BLACK          => [  0,  0,  0],
	       RED            => [240, 50, 50],
	       YELLOW         => [255,255,  0],
	       GREEN          => [  0,255,  0],
	       AQUAMARINE     => [127,255,212],
	       PINK           => [255,192,203],
	       WHEAT          => [245,222,179],
	       GREY           => [190,190,190],
	       BROWN          => [165, 42, 42],
	       BLUE           => [  0,  0,255],
	       BLUEVIOLET     => [138, 43,226],
	       CYAN           => [  0,255,255],
	       TURQUOISE      => [ 64,224,208],
	       MAGENTA        => [255,  0,255],
	       SALMON         => [250,128,114],
	       WHITE          => [255,255,255],
               ROYALBLUE      => cc2t('2B 60 DE'),
               DEEPSKYBLUE    => cc2t('3B B9 FF'),
               VIOLET         => cc2t('8D 38 C9'),
               STEELBLUE1     => cc2t('5C B3 FF'),
               DEEPPINK       => cc2t('F5 28 87'),
               MAGENTA        => cc2t('FF 00 FF'),
               DARKORCHID1    => cc2t('B0 41 FF'),
               PALEVIOLETRED2 => cc2t('E5 6E 94'),
               TURQUOISE1     => cc2t('52 F3 FF'),
               LIGHTSEAGREEN  => cc2t('3E A9 9F'),
               SKYBLUE        => cc2t('66 98 FF'),
               FORESTGREEN    => cc2t('4E 92 58'),
               CHARTREUSE3    => cc2t('6C C4 17'),
               GOLD2          => cc2t('EA C1 17'),
               SIENNA1        => cc2t('F8 74 31'),
               CORAL          => cc2t('F7 65 41'),
               HOTPINK        => cc2t('F6 60 AB'),
               LIGHTCORAL     => cc2t('E7 74 71'),
               LIGHTPINK1     => cc2t('F9 A7 B0'),
               LIGHTGOLDENROD => cc2t('EC D8 72'),
	      );

# a hash of subroutines to invoke when certain keywords are specified
# These are called with arg(0) = $self (the plot object)
#                   and arg(1) = value specified for keyword
our %_actions =
  (


   # Set color for index 0, the plot background
   BACKGROUND => sub {
     my $self  = shift;
     my $color = _color(shift);
     $self->{COLORS}[0] = $color;
     plscolbg (@$color);
   },

   # set plotting box in world coordinates
   BOX        => sub {
     my $self  = shift;
     my $box   = shift;
     die "Box must be a ref to a four element array" unless (ref($box) =~ /ARRAY/ and @$box == 4);
     $self->{BOX} = $box;
   },

   CHARSIZE   => sub { my $self = shift;
                       $self->{CHARSIZE} = $_[0];
                       plschr (0, $self->{CHARSIZE}) unless ($self->{ISNEW}); # do not call plsch from the 'new' routine.
                     },

   # maintain color map, set to specified rgb triple
   COLOR => sub {
     my $self  = shift;
     my $color = _color(shift);

     # init.
     $self->{COLORS} = [] unless exists($self->{COLORS});

     my @idx = @{$self->{COLORS}}; # map of color index (0-15) to RGB triples
     my $found = 0;
     for (my $i=2;$i<@idx;$i++) {  # map entries 0 and 1 are reserved for BACKGROUND and FRAMECOLOR
       if (_coloreq ($color, $idx[$i])) {
	 $self->{CURRENT_COLOR_IDX} = $i;
	 $found = 1;
	 plscol0 ($self->{CURRENT_COLOR_IDX}, @$color);
       }
     }
     return if ($found);

     die "Too many colors used! (max 15)" if (@{$self->{COLORS}} > 14);

     # add this color as index 2 or greater (entries 0 and 1 reserved)
     my $idx = (@{$self->{COLORS}} > 1) ? @{$self->{COLORS}} : 2;
     $self->{COLORS}[$idx]      = $color;
     $self->{CURRENT_COLOR_IDX} = $idx;
     plscol0 ($self->{CURRENT_COLOR_IDX}, @$color);
   },

   # Contour plot label parameters (see setcontlabelparam and setcontlabelformat)
   CONTOURLABELS => sub { my $self  = shift;
                          my $parms = shift; # [offset, size, spacing, lexp, sigdig], or 0 (deactivate) or 1 (activate)
                          my $defaults = [0.006, 0.3, 0.1, 4, 2];
                          if ( (ref($parms) =~ /ARRAY/) && (@$parms == 5) ) {
                            $self->{CONTOURLABELS} = $parms;
                          } elsif ($parms == 0) {
                            $self->{CONTOURLABELS} = 0;
                          } elsif ($parms == 1) {
                            $self->{CONTOURLABELS} = $defaults;
                          } else {
                            die
"Illegal contour label parameters:  Must either be 0 (turn off contour labels), 1 (turn on default contour labels)
 or a five element array:
 offset:  Offset of label from contour line (if set to 0.0, labels are printed on the lines). Default value is 0.006.
 size:    Font height for contour labels (normalized). Default value is 0.3.
 spacing: Spacing parameter for contour labels. Default value is 0.1.
 lexp:    If the contour numerical label is greater than 10^(lexp) or less than 10^(-lexp),
          then the exponential format is used. Default value of lexp is 4.
 sigdig:  Number of significant digits. Default value is 2";
                          }
   },

   # set output device type
   DEV        => sub { my $self = shift;
                       my $dev  = shift;
                       $self->{DEV} = $dev;
                       plsdev   ($dev)
                     },   # this must be specified with call to new!

   # set PDL to plot into (alternative to specifying DEV)
   MEM        => sub { my $self = shift;
		       my $pdl  = shift;
		       my $x    = $pdl->getdim(1);
		       my $y    = $pdl->getdim(2);
		       plsmem   ($x, $y, $pdl);
		     },

   # set output file
   FILE       => sub { plsfnam  ($_[1]) },   # this must be specified with call to new!

   # set color for index 1, the plot frame and text
   # set color index 1, the frame color
   FRAMECOLOR => sub {
     my $self  = shift;
     my $color = _color(shift);
     $self->{COLORS}[1] = $color;
     plscol0 (1, @$color);
   },

   GRIDMAP => sub {
     # Use a user-defined grid map if requested.  This is an X and Y vector that
     # tells what are the world coordinates for each pixel in $z
     # It is used in 'shadeplot'.
     my $self = shift;
     my $map = shift;
     die "GRIDMAP must be an array reference"            if (ref($map) !~ /ARRAY/);
     die "GRIDMAP must be a two element array reference" if (@$map != 2);
     die "GRIDMAP must contain two PDLs"                 if ( (ref($$map[0]) !~ /PDL/) || (ref($$map[1]) !~ /PDL/) );
     die "GRIDMAP must contain two 1D PDLs"              if ( ($$map[0]->dims != 1) || ($$map[1]->dims != 1) );
     $self->{GRIDMAP} = $map;
   },

   GRIDMAP2 => sub {
     # Use a user-defined grid map if requested.  These are an X and Y matrices that
     # tells what are the world coordinates for each pixel in $z
     # They are used in 'shadeplot'.
     my $self = shift;
     my $map = shift;
     die "GRIDMAP2 must be an array reference"            if (ref($map) !~ /ARRAY/);
     die "GRIDMAP2 must be a two element array reference" if (@$map != 2);
     die "GRIDMAP2 must contain two PDLs"                 if ( (ref($$map[0]) !~ /PDL/) || (ref($$map[1]) !~ /PDL/) );
     die "GRIDMAP2 must contain two 2D PDLs"              if ( ($$map[0]->dims != 2) || ($$map[1]->dims != 2) );
     $self->{GRIDMAP2} = $map;
   },

   # Set flag for equal scale axes
   JUST => sub {
     my $self  = shift;
     my $just  = shift;
     die "JUST must be 0 or 1 (defaults to 0)" unless ($just == 0 or $just == 1);
     $self->{JUST} = $just;
   },

    LINEWIDTH  => sub {
      my $self = shift;
      my $wid  = shift;
      die "LINEWIDTH must range from 0 to LARGE8" unless ($wid >= 0);
      $self->{LINEWIDTH} = $wid;
    },

   LINESTYLE  => sub {
     my $self = shift;
     my $sty  = shift;
     die "LINESTYLE must range from 1 to 8" unless ($sty >= 1 and $sty <= 8);
     $self->{LINESTYLE} = $sty;
   },

   MAJTICKSIZE  => sub {
     my $self = shift;
     my $val  = shift;
     die "MAJTICKSIZE must be greater than or equal to zero"
       unless ($val >= 0);
     plsmaj (0, $val);
   },

   MINTICKSIZE  => sub {
     my $self = shift;
     my $val  = shift;
     die "MINTICKSIZE must be greater than or equal to zero"
       unless ($val >= 0);
     plsmin (0, $val);
   },

   NXSUB  => sub {
     my $self = shift;
     my $val  = shift;
     die "NXSUB must be an integer greater than or equal to zero"
       unless ($val >= 0 and int($val) == $val);
     $self->{NXSUB} = $val;
   },

   NYSUB  => sub {
     my $self = shift;
     my $val  = shift;
     die "NYSUB must be an integer greater than or equal to zero"
       unless ($val >= 0 and int($val) == $val);
     $self->{NYSUB} = $val;
   },

   # set driver options, example for ps driver, {text => 1} is accepted
   OPTS => sub {
     my $self = shift;
     my $opts = shift;

     foreach my $opt (keys %$opts) {
       plsetopt ($opt, $$opts{$opt});
     }
   },

   # set driver options, example for ps driver, {text => 1} is accepted
   ORIENTATION => sub {
     my $self   = shift;
     my $orient = shift;

     die "Orientation must be between 0 and 4" unless ($orient >= 0 and $orient <= 4);
     $self->{ORIENTATION} = $orient;
   },

   PAGESIZE   =>
     # set plot size in mm.  Only useful in call to 'new'
     sub {
       my $self = shift;
       my $dims = shift;

       die "plot size must be a 2 element array ref:  X size in pixels, Y size in pixels"
	 if ((ref($dims) !~ /ARRAY/) || @$dims != 2);
       $self->{PAGESIZE} = $dims;
     },

   # load some pre-done color map 1 setups
   PALETTE => sub {
     my $self = shift;
     my $pal  = shift;

     my %legal = (REVERSERAINBOW => 1, REVERSEGREYSCALE => 1, REDGREEN => 1, RAINBOW => 1, GREYSCALE => 1, GREENRED => 1);
     if ($legal{$pal}) {
       $self->{PALETTE} = $pal;
       if      ($pal eq 'RAINBOW') {
	 plscmap1l (0, PDL->new(0,1), PDL->new(0,300), PDL->new(0.5, 0.5), PDL->new(1,1), PDL->new(0,0));
       } elsif ($pal eq 'REVERSERAINBOW') {
	 plscmap1l (0, PDL->new(0,1), PDL->new(270,-30), PDL->new(0.5, 0.5), PDL->new(1,1), PDL->new(0,0));
       } elsif ($pal eq 'GREYSCALE') {
	 plscmap1l (0, PDL->new(0,1), PDL->new(0,0),   PDL->new(0,1), PDL->new(0,0), PDL->new(0,0));
       } elsif ($pal eq 'REVERSEGREYSCALE') {
	 plscmap1l (0, PDL->new(0,1), PDL->new(0,0),   PDL->new(1,0), PDL->new(0,0), PDL->new(0,0));
       } elsif ($pal eq 'GREENRED') {
	 plscmap1l (0, PDL->new(0,1), PDL->new(120,0), PDL->new(0.5, 0.5), PDL->new(1,1), PDL->new(1,1));
       } elsif ($pal eq 'REDGREEN') {
	 plscmap1l (0, PDL->new(0,1), PDL->new(0,120), PDL->new(0.5, 0.5), PDL->new(1,1), PDL->new(1,1));
       }
     } else {
       die "Illegal palette name.  Legal names are: " . join (" ", keys %legal);
     }
   },

   # specify plot type (LINE, POINTS, LINEPOINTS, CONTOUR, SHADE)
   PLOTTYPE => sub {
     my $self = shift;
     my $val  = shift;

     my %legal = (LINE => 1, POINTS => 1, LINEPOINTS => 1, CONTOUR => 1, SHADE => 1);
     if ($legal{$val}) {
       $self->{PLOTTYPE} = $val;
     } else {
       die "Illegal plot type.  Legal options are: " . join (" ", keys %legal);
     }
   },

   # Specify outline bars for bargraph
   STACKED_BAR_COLORS => sub {
     my $self = shift;
     my $val  = shift;
     my $err = "STACKED_BAR_COLORS must be a reference to a perl list of color names or RGB triples";
     die $err if (ref($val) !~ /ARRAY/);
     delete $self->{STACKED_BAR_COLORS};
     foreach my $e (@$val) {
       push @{$self->{STACKED_BAR_COLORS}}, _color($e);  # Will throw an exception if this is not a legal color
     }
   },

   # specify which subpage to plot on 1-N or 0 (meaning 'next')
   SUBPAGE => sub {
     my $self = shift;
     my $val  = shift;
     my $err  = "SUBPAGE = \$npage where \$npage = 1-N or 0 (for 'next subpage')";
     if ($val >= 0) {
       $self->{SUBPAGE} = $val;
     } else {
       die $err;
     }
   },

   # specify number of sub pages [nx, ny]
   SUBPAGES => sub {
     my $self = shift;
     my $val  = shift;
     my $err  = "SUBPAGES = [\$nx, \$ny] where \$nx and \$ny are between 1 and 127";
     if (ref($val) =~ /ARRAY/ and @$val == 2) {
       my ($nx, $ny) = @$val;
       if ($nx > 0 and $nx < 128 and $ny > 0 and $ny < 128) {
	 $self->{SUBPAGES} = [$nx, $ny];
       } else {
	 die $err;
       }
     } else {
       die $err;
     }
   },

   # specify type of symbol to plot
   SYMBOL => sub {
     my $self = shift;
     my $val  = shift;

     if ($val >= 0 && $val < 3000) {
       $self->{SYMBOL} = $val;
     } else {
       die "Illegal symbol number.  Legal symbols are between 0 and 3000";
     }
   },

   SYMBOLSIZE => sub {
     my ($self, $size) = @_;
     die "symbol size must be a real number from 0 to (large)" unless ($size >= 0);
     $self->{SYMBOLSIZE} = $size;
   },

   # specify placement of text.  Either relative to border, specified as:
   # [$side, $disp, $pos, $just]
   # or
   # inside plot window, specified as:
   # [$x, $y, $dx, $dy, $just] (see POD doc for details)
   TEXTPOSITION => sub {
     my $self = shift;
     my $val  = shift;
     die "TEXTPOSITION value must be an array ref with either:
          [$side, $disp, $pos, $just] or [$x, $y, $dx, $dy, $just]"
       unless ((ref($val) =~ /ARRAY/) and ((@$val == 4) || (@$val == 5)));
     if (@$val == 4) {
       $self->{TEXTMODE} = 'border';
     } else {
       $self->{TEXTMODE} = 'plot';
     }
     $self->{TEXTPOSITION} = $val;
   },

   # draw a title for the graph
   TITLE      => sub {
     my $self = shift;
     my $text = shift;
     $self->{TITLE} = $text;
   },

   # Specify outline bars for bargraph
   UNFILLED_BARS => sub {
     my $self = shift;
     my $val  = shift;
     $self->{UNFILLED_BARS} = $val;
   },

   # set the location of the plotting window on the page
   VIEWPORT => sub {
     my $self  = shift;
     my $vp    = shift;
     die "Viewport must be a ref to a four element array"
       unless (ref($vp) =~ /ARRAY/ and @$vp == 4);
     $self->{VIEWPORT} = $vp;
   },

   # set X axis label options.  See pod for definitions.
   XBOX       => sub {
     my $self = shift;
     my $opts = lc shift;
     my @opts = split '', $opts;
     map { 'abcdfghilmnst' =~ /$_/i || die "Illegal option $_.  Only abcdfghilmnst permitted" } @opts;
     $self->{XBOX} = $opts;
   },

   # draw an X axis label for the graph
   XLAB       => sub {
     my $self = shift;
     my $text = shift;
     $self->{XLAB} = $text;
   },

   XTICK  => sub {
     my $self = shift;
     my $val  = shift;
     die "XTICK must be greater than or equal to zero"
       unless ($val >= 0);
     $self->{XTICK} = $val;
   },

     # set Y axis label options.  See pod for definitions.
   YBOX       => sub {
     my $self = shift;
     my $opts = shift;
     my @opts = split '', $opts;
     map { 'abcfghilmnstv' =~ /$_/i || die "Illegal option $_.  Only abcfghilmnstv permitted" } @opts;
     $self->{YBOX} = $opts;
   },

   # draw an Y axis label for the graph
   YLAB       => sub {
     my $self = shift;
     my $text = shift;
     $self->{YLAB} = $text;
   },

   YTICK  => sub {
     my $self = shift;
     my $val  = shift;
     die "YTICK must be greater than or equal to zero"
       unless ($val >= 0);
     $self->{YTICK} = $val;
   },

   ZRANGE  => sub {
     my $self = shift;
     my $val  = shift;
     die "ZRANGE must be a perl array ref with min and max Z values"
       unless (ref($val) =~ /ARRAY/ && @$val == 2);
     $self->{ZRANGE} = $val;
   },

);


#
## Internal utility routines
#

# handle color as string in _constants hash or [r,g,b] triple
# Input:  either color name or [r,g,b] array ref
# Output: [r,g,b] array ref or exception
sub _color {
  my $c = shift;
  if      (ref($c) =~ /ARRAY/) {
    return $c;
  } elsif ($c = $_constants{$c}) {
    return $c;
  } else {
    die "Color $c not defined";
  }
}

# return 1 if input [r,g,b] triples are equal.
sub _coloreq {
  my ($a, $b) = @_;
  for (my $i=0;$i<3;$i++) { return 0 if ($$a[$i] != $$b[$i]); }
  return 1;
}

# Initialize plotting window given the world coordinate box and
# a 'justify' flag (for equal axis scales).
sub _setwindow {

  my $self = shift;

  # choose correct subwindow
  pladv ($self->{SUBPAGE}) if (exists ($self->{SUBPAGE}));
  delete ($self->{SUBPAGE});  # get rid of SUBPAGE so future plots will stay on same
                              # page unless user asks for specific page

  my $box  = $self->{BOX} || [0,1,0,1]; # default window

  sub MAX { ($_[0] > $_[1]) ? $_[0] : $_[1]; }

  # get subpage offsets from page left/bottom of image
  my ($spxmin, $spxmax, $spymin, $spymax) = (PDL->new(0),PDL->new(0),PDL->new(0),PDL->new(0));
  plgspa($spxmin, $spxmax, $spymin, $spymax);
  $spxmin = $spxmin->at(0);
  $spxmax = $spxmax->at(0);
  $spymin = $spymin->at(0);
  $spymax = $spymax->at(0);
  my $xsize = $spxmax - $spxmin;
  my $ysize = $spymax - $spymin;

  my @vp = @{$self->{VIEWPORT}};  # view port xmin, xmax, ymin, ymax in fraction of image size

  # if JUSTify is zero, set to the user specified (or default) VIEWPORT
  if ($self->{JUST} == 0) {
    plvpor(@vp);

  # compute viewport to allow the same scales for both axes
  } else {
    my $p_def = PDL->new(0);
    my $p_ht  = PDL->new(0);
    plgchr ($p_def, $p_ht);
    $p_def = $p_def->at(0);
    my $lb = 8.0 * $p_def;
    my $rb = 5.0 * $p_def;
    my $tb = 5.0 * $p_def;
    my $bb = 5.0 * $p_def;
    my $dx = $$box[1] - $$box[0];
    my $dy = $$box[3] - $$box[2];
    my $xscale = $dx / ($xsize - $lb - $rb);
    my $yscale = $dy / ($ysize - $tb - $bb);
    my $scale  = MAX($xscale, $yscale);
    my $vpxmin = MAX($lb, 0.5 * ($xsize - $dx / $scale));
    my $vpxmax = $vpxmin + ($dx / $scale);
    my $vpymin = MAX($bb, 0.5 * ($ysize - $dy / $scale));
    my $vpymax = $vpymin + ($dy / $scale);
    plsvpa($vpxmin, $vpxmax, $vpymin, $vpymax);
    $self->{VIEWPORT} = [$vpxmin/$xsize, $vpxmax/$xsize, $vpymin/$ysize, $vpymax/$ysize];
  }

  # set up world coords in window
  plwind (@$box);

}

# Add title and axis labels.
sub _drawlabels {

  my $self = shift;

  plcol0  (1); # set to frame color
  plmtex   (2.5, 0.5, 0.5, 't', $self->{TITLE}) if ($self->{TITLE});
  plmtex   (3.0, 0.5, 0.5, 'b', $self->{XLAB})  if ($self->{XLAB});
  plmtex   (3.5, 0.5, 0.5, 'l', $self->{YLAB})  if ($self->{YLAB});
  plcol0  ($self->{CURRENT_COLOR_IDX}); # set back

}


#
## user-visible routines
#

# Pool of PLplot stream numbers.  One of these stream numbers is taken when 'new' is called
# and when the corresponding 'close' is called, it is returned to the pool.  The pool is
# just a queue:  'new' shifts stream numbers from the top of the queue, 'close' pushes them
# back on the bottom of the queue.
my @plplot_stream_pool = (0..99);

# This routine starts out a plot.  Generally one specifies
# DEV and FILE (device and output file name) as options.
sub new {
  my $type = shift;
  my $self = {};

  # set up object
  $self->{PLOTTYPE} = 'LINE';
  # $self->{CURRENT_COLOR_IDX} = 1;
  $self->{COLORS} = [];

  bless $self, $type;

  # set stream number first
  $self->{STREAMNUMBER} = shift @plplot_stream_pool;
  die "No more PLplot streams left, too many open PLplot objects!" if (!defined($self->{STREAMNUMBER}));
  plsstrm($self->{STREAMNUMBER});

  # set background and frame color first
  $self->setparm(BACKGROUND => 'WHITE',
		 FRAMECOLOR => 'BLACK');

  # set defaults, allow input options to override
  my %opts = (
	      COLOR      => 'BLACK',
	      XBOX       => 'BCNST',
	      YBOX       => 'BCNST',
	      JUST       => 0,
	      SUBPAGES   => [1,1],
	      VIEWPORT   => [0.1, 0.87, 0.13, 0.82],
	      SUBPAGE    => 0,
	      PAGESIZE   => [600, 500],
	      LINESTYLE  => 1,
              LINEWIDTH  => 0,
              SYMBOL     => 751, # a small square
	      NXSUB      => 0,
	      NYSUB      => 0,
	      ORIENTATION=> 0,
	      XTICK      => 0,
	      YTICK      => 0,
	      CHARSIZE   => 1,
	      @_);


  # apply options
  $self->{ISNEW} = 1;
  $self->setparm(%opts);
  $self->{ISNEW} = 0;

  # Do initial setup
  plspage (0, 0, @{$self->{PAGESIZE}}, 0, 0) if (defined($self->{PAGESIZE}));
  plssub (@{$self->{SUBPAGES}});
  plsfam (0, -1, -1); # fix for plplot 5.11.0
  plfontld (1); # extented symbol pages
  plscmap0n (16);   # set up color map 0 to 16 colors.  Is this needed?
  plscmap1n (128);  # set map 1 to 128 colors (should work for devices with 256 colors)
  plinit ();

  # Now (as of plplot5.11) this must be done after plinit();
  plschr   (0, $self->{CHARSIZE});

  # set page orientation
  plsdiori ($self->{ORIENTATION});

  # set up plotting box
  $self->_setwindow;

  return $self;
}

# set parameters.  Called from user directly or from other routines.
sub setparm {
  my $self = shift;

  my %opts = @_;

  # Set PLplot to right output stream
  plsstrm($self->{STREAMNUMBER});

  # apply all options
 OPTION:
  foreach my $o (keys %opts) {
    unless (exists($_actions{$o})) {
      warn "Illegal option $o, ignoring";
      next OPTION;
    }
    &{$_actions{$o}}($self, $opts{$o});
  }
}

# handle 2D plots
sub xyplot {
  my $self = shift;
  my $x    = shift;
  my $y    = shift;

  my %opts = @_;

  # Set PLplot to right output stream
  plsstrm($self->{STREAMNUMBER});

  # only process COLORMAP entries once
  my $z = $opts{COLORMAP};
  delete ($opts{COLORMAP});

  # handle ERRORBAR options
  my $xeb = $opts{XERRORBAR};
  my $yeb = $opts{YERRORBAR};
  delete ($opts{XERRORBAR});
  delete ($opts{YERRORBAR});

  # apply options
  $self->setparm(%opts);

  unless (exists($self->{BOX})) {
    $self->{BOX} = [$x->minmax, $y->minmax];
  }

  # set up viewport, subpage, world coordinates
  $self->_setwindow;

  # draw labels
  $self->_drawlabels;

  # plot box
  plcol0  (1); # set to frame color
  plbox ($self->{XTICK}, $self->{NXSUB}, $self->{YTICK}, $self->{NYSUB},
	 $self->{XBOX}, $self->{YBOX}); # !!! note out of order call

  # set the color according to the color specified in the object
  # (we don't do this as an option, because then the frame might
  # get the color requested for the line/points
  plcol0  ($self->{CURRENT_COLOR_IDX});

  # set line style for plot only (not box)
  pllsty ($self->{LINESTYLE});

  # set line width for plot only (not box)
  plwidth  ($self->{LINEWIDTH});

  # Plot lines if requested
  if  ($self->{PLOTTYPE} =~ /LINE/) {
    plline ($x, $y);
  }

  # set line width back
  plwidth  (0);

  # plot points if requested
  if ($self->{PLOTTYPE} =~ /POINTS/) {
    my $c = $self->{SYMBOL};
    unless (defined($c)) {

      # the default for $c is a PDL of ones with shape
      # equal to $x with the first dimension removed
      my $z = PDL->zeroes($x->nelem);
      $c = PDL->ones($z->zcover) unless defined($c);
    }
    plssym   (0, $self->{SYMBOLSIZE}) if (defined($self->{SYMBOLSIZE}));

    if (defined($z)) {  # if a color range plot requested
      my ($min, $max) = exists ($self->{ZRANGE}) ? @{$self->{ZRANGE}} : $z->minmax;
      plcolorpoints ($x, $y, $z, $c, $min, $max);
    } else {
      plsym ($x, $y, $c);
    }
  }

  # Plot error bars, if requested
  if (defined($xeb)) {
    # horizontal (X) error bars
    plerrx ($x->nelem, $x - $xeb/2, $x + $xeb/2, $y);
  }

  if (defined($yeb)) {
    # vertical (Y) error bars
    plerry ($y->nelem, $x, $y - $yeb/2, $y + $yeb/2);
  }

  # Flush the PLplot stream.
  plflush();
}

sub stripplots {

  my $self    = shift;
  my $xs      = shift;
  my $yargs   = shift;

  my %opts = @_;

  # NYTICK => number of y axis ticks
  my $nytick = $opts{NYTICK} || 2;
  delete ($opts{NYTICK});

  # only process COLORMAP entries once
  my $zs = $opts{COLORMAP};
  delete ($opts{COLORMAP});

  # handle XLAB, YLAB and TITLE options
  my $title = $opts{TITLE} || '';
  my $xlab  = $opts{XLAB}  || '';
  my @ylabs = defined($opts{YLAB}) && (ref($opts{YLAB}) =~ /ARRAY/) ? @{$opts{YLAB}} : ();
  delete @opts{qw(TITLE XLAB YLAB)};

  # Ensure we're dealing with an array reference
  my $ys;
  if (ref ($yargs) eq 'ARRAY') {
    $ys = $yargs;
  }
  elsif (ref ($yargs) =~ /PDL/) {
    $ys = [dog $yargs];
  }
  else {
    barf("stripplots requires that its second argument be either a 2D ndarray or\na reference to a list of 1D ndarrays, but you provided neither.");
  }

# This doesn't work because $xs can be an anonymous array, too
#  # Let's be sure the user sent us what we expected:
#  foreach (@$ys) {
#    barf ("stripplots needs to have ndarrays for its y arguments!")
#      unless (ref =~ /PDL/);
#    barf("stripplots requires that the x and y dimensions agree!")
#      unless ($_->nelem == $xs->nelem);
#  }

  my $nplots = @$ys;

  # Use list of colors, or single color.  If COLOR not specified, default to BLACK for each graph
  my @colors = (defined ($opts{COLOR}) && ref($opts{COLOR}) =~ /ARRAY/) ? @{$opts{COLOR}}
             :  defined ($opts{COLOR})                                  ? ($opts{COLOR}) x $nplots
             : ('BLACK') x $nplots;
  delete @opts{qw(COLOR)};

  my $y_base   = defined($opts{Y_BASE})   ? $opts{Y_BASE}   : 0.1;  # Y offset to start bottom plot
  my $y_gutter = defined($opts{Y_GUTTER}) ? $opts{Y_GUTTER} : 0.02; # Y gap between plots
  delete @opts{qw(Y_BASE Y_GUTTER)};

  # apply options
  $self->setparm(%opts);

  my ($xmin, $xmax);
  if (ref ($xs) =~ /PDL/) {
    ($xmin, $xmax) = $xs->minmax;
  }
  else {
    $xmin = pdl(map { $_->min } @$xs)->min;
    $xmax = pdl(map { $_->max } @$xs)->max;
  }

  SUBPAGE:
    for (my $subpage=0;$subpage<$nplots;$subpage++) {

      my $y = $ys->[$subpage];
      my $x = ref ($xs) =~ /PDL/ ? $xs : $xs->[$subpage];
      my $mask = $y->isgood;
      $y = $y->where($mask);
      $x = $x->where($mask);
      my $z = $zs->slice(":,($subpage)")->where($mask)      if (defined($zs));
      my $yeb  = $yebs->slice(":,($subpage)")->where($mask) if (defined($yebs));
      my $ylab = $ylabs[$subpage];

      my $bottomplot = ($subpage == 0);
      my $topplot    = ($subpage == $nplots-1);

      my $xbox = 'bc';
      $xbox = 'cstnb' if ($bottomplot);

      my $box = $opts{BOX};
      my $yrange = defined($box) ? $$box[3] - $$box[2] : $y->max - $y->min;
      my $del = $yrange ? $yrange * 0.05 : 1;
      my @ybounds = ($y->min - $del, $y->max + $del);
      my $ytick = ($yrange/$nytick);
      my @COLORMAP  = (COLORMAP => $z)    if defined($z);
      $self->xyplot($x, $y,
		  COLOR     => $colors[$subpage],
		  BOX       => defined($box) ? $box : [$xmin, $xmax, @ybounds],
		  XBOX      => $xbox,
		  YBOX      => 'BCNT',
                  YTICK     => $ytick,
                  MAJTICKSIZE => 0.6,
		  CHARSIZE  => 0.4,
                  @COLORMAP,
		  VIEWPORT  => [
				0.15,
				0.9,
                                $y_base             + ($subpage     * (0.8/$nplots)),
                                $y_base - $y_gutter + (($subpage+1) * (0.8/$nplots)),
				],
		  );

      $self->text($ylab,  TEXTPOSITION => ['L', 4, 0.5, 0.5], COLOR => 'BLACK', CHARSIZE => 0.6) if (defined($ylab));
      $self->text($xlab,  TEXTPOSITION => ['B', 3, 0.5, 0.5], COLOR => 'BLACK', CHARSIZE => 0.6) if ($xlab && $bottomplot);
      $self->text($title, TEXTPOSITION => ['T', 2, 0.5, 0.5], COLOR => 'BLACK', CHARSIZE => 1.3) if ($title && $topplot);

    }

}


# Draw a color key or wedge showing the scale of map1 colors
sub colorkey {
  my $self = shift;
  my $var  = shift;
  my $orientation = shift; # 'v' (for vertical) or 'h' (for horizontal)

  my %opts = @_;

  # Set PLplot to right output stream
  plsstrm($self->{STREAMNUMBER});

  # apply options
  $self->setparm(%opts);

  # set up viewport, subpage, world coordinates
  $self->_setwindow;

  # draw labels
  $self->_drawlabels;

  # Allow user to set X, Y box type for color key scale.  D. Hunt 1/7/2009
  my $xbox = exists($self->{XBOX}) ? $self->{XBOX} : 'TM';
  my $ybox = exists($self->{YBOX}) ? $self->{YBOX} : 'TM';

  my @box;

  plcol0  (1); # set to frame color

  my ($min, $max) = exists ($self->{ZRANGE}) ? @{$self->{ZRANGE}} : $var->minmax;

  # plot box
  if      ($orientation eq 'v') {
    # set world coordinates based on input variable
    @box = (0, 1, $min, $max);
    plwind (@box);
    plbox (0, 0, 0, 0, '', $ybox);  # !!! note out of order call
  } elsif ($orientation eq 'h') {
    @box = ($min, $max, 0, 1);
    plwind (@box);
    plbox (0, 0, 0, 0, $xbox, '');  # !!! note out of order call
  } else {
    die "Illegal orientation value: $orientation.  Should be 'v' (vertical) or 'h' (horizontal)";
  }

  # restore color setting
  plcol0  ($self->{CURRENT_COLOR_IDX});

  # This is the number of colors shown in the color wedge.  Make
  # this smaller for gif images as these are limited to 256 colors total.
  # D. Hunt 8/9/2006
  my $ncols = ($self->{DEV} =~ /gif/) ? 32 : 128;

  if ($orientation eq 'v') {
    my $yinc = ($box[3] - $box[2])/$ncols;
    my $y0 = $box[2];
    for (my $i=0;$i<$ncols;$i++) {
      $y0 = $box[2] + ($i * $yinc);
      my $y1 = $y0 + $yinc;
      PDL::Graphics::PLplot::plcol1($i/$ncols);

      # Instead of using plfill (which is not supported on some devices)
      # use multiple calls to plline to color in the space. D. Hunt 8/9/2006
      foreach my $inc (0..9) {
        my $frac = $inc * 0.1;
        my $y = $y0 + (($y1 - $y0) * $frac);
        PDL::Graphics::PLplot::plline (PDL->new(0,1), PDL->new($y,$y));
      }

    }
  } else {
    my $xinc = ($box[1] - $box[0])/$ncols;
    my $x0 = $box[0];
    for (my $i=0;$i<$ncols;$i++) {
      $x0 = $box[0] + ($i * $xinc);
      my $x1 = $x0 + $xinc;
      PDL::Graphics::PLplot::plcol1($i/$ncols);

      # Instead of using plfill (which is not supported on some devices)
      # use multiple calls to plline to color in the space. D. Hunt 8/9/2006
      foreach my $inc (0..9) {
        my $frac = $inc * 0.1;
        my $x = $x0 + (($x1 - $x0) * $frac);
        PDL::Graphics::PLplot::plline (PDL->new($x,$x), PDL->new(0,1));
      }

    }
  }

  # Flush the PLplot stream.
  plflush();
}

sub shadeplot {
  my $self   = shift;
  my $z      = shift;
  my $nsteps = shift;

  my %opts = @_;

  # Set PLplot to right output stream
  plsstrm($self->{STREAMNUMBER});

  # apply options
  $self->setparm(%opts);

  my ($nx, $ny) = $z->dims;

  unless (exists($self->{BOX})) {
    $self->{BOX} = [0, $nx, 0, $ny];
  }

  # set up plotting box
  $self->_setwindow;

  # draw labels
  $self->_drawlabels;

  # plot box
  plcol0  (1); # set to frame color
  plbox ($self->{XTICK}, $self->{NXSUB}, $self->{YTICK}, $self->{NYSUB},
	 $self->{XBOX}, $self->{YBOX}); # !!! note out of order call

  my ($min, $max) = exists ($self->{ZRANGE}) ? @{$self->{ZRANGE}} : $z->minmax;
  my $clevel = ((PDL->sequence($nsteps)*(($max - $min)/($nsteps-1))) + $min);

  # may add as options later.  Now use constants
  my $fill_width = 2;
  my $cont_color = 0;
  my $cont_width = 0;

  my $rectangular = 1; # only false for non-linear coord mapping (not done yet in perl)

  # Use a user-defined grid map if requested.  This is an X and Y vector that
  # tells what are the world coordinates for each pixel in $z
  # It is also possible to specify a 2D mapping for non-linear transforms.  This is specified
  # in GRIDMAP2.
  my ($xmap, $ymap, $grid, $mapping_function);
  if (exists($self->{GRIDMAP})) {
    ($xmap, $ymap) = @{$self->{GRIDMAP}};
    $grid = plAllocGrid ($xmap, $ymap);
    $mapping_function = \&pltr1;
  } elsif (exists($self->{GRIDMAP2})) {
    ($xmap, $ymap) = @{$self->{GRIDMAP2}};
    $grid = plAlloc2dGrid ($xmap, $ymap);
    $mapping_function = \&pltr2;
  } else {
    # map X coords linearly to X range, Y coords linearly to Y range
    $xmap = ((PDL->sequence($nx)*(($self->{BOX}[1] - $self->{BOX}[0])/($nx - 1))) + $self->{BOX}[0]);
    $ymap = ((PDL->sequence($ny)*(($self->{BOX}[3] - $self->{BOX}[2])/($ny - 1))) + $self->{BOX}[2]);
    $grid = plAllocGrid ($xmap, $ymap);
    $mapping_function = \&pltr1;
  }

  # Choose shade plot or contour plot
  if (defined($self->{PLOTTYPE}) && ($self->{PLOTTYPE} eq 'CONTOUR') ) {

    if (defined($self->{CONTOURLABELS}) && $self->{CONTOURLABELS}) {
      my ($offset, $size, $spacing, $lexp, $sigdig) = @{$self->{CONTOURLABELS}};
      pl_setcontlabelparam ($offset, $size, $spacing, 1); # 1 = activate
      pl_setcontlabelformat ($lexp, $sigdig);
    } else { # == 0, set labels off
      pl_setcontlabelparam (0.006, 0.3, 0.1, 0); # 0 = deactivate
    }

    plcont ($z, 1, $nx-1, 1, $ny-1, $clevel, $mapping_function, $grid);

  } else {

    plshades($z, @{$self->{BOX}}, $clevel, $fill_width,
             $cont_color, $cont_width, $rectangular,
	     0, $mapping_function, $grid);

  }

  if (exists($self->{GRIDMAP2})) {
    plFree2dGrid ($grid);
  } else {
    plFreeGrid ($grid);
  }

  # Flush the PLplot stream.
  plflush();
}

sub histogram1 {
  my $self  = shift;
  my $x     = shift;
  my $nbins = shift;

  my $n = $x->nelem;

  my ($min, $max);
  if (exists($self->{BOX})) {
    ($min, $max) = @{$self->{BOX}}[0,1];
  } else {
    ($min, $max) = $x->minmax;
  }

  my $step = ($max - $min)/$nbins;
  my ($xvals, $yvals) = PDL::hist($x,$min,$max,$step);

  $self->{BOX} = [$min, $max, 0, $yvals->max] unless (exists($self->{BOX}));

  # apply options
  my %opts = @_;
  $self->setparm(%opts);

  # set up plotting box
  $self->_setwindow;

  # draw labels
  $self->_drawlabels;

  # plot box
  plcol0  (1); # set to frame color
  plbox ('', '', '', '', 'BNTI', 'BNTI'); # !!! note out of order call

  # draw colored histogram boxes
  plcol0  ($self->{CURRENT_COLOR_IDX});
  for (my $i=0;$i<$yvals->nelem;$i++) {
    my $y  = $yvals->at($i);
    next if ($y == 0); # don't bother plotting

    my $x  = $xvals->at($i);

    my $x0 = $x - ($step/2);
    my $x1 = $x + ($step/2);
    plfill (PDL->new($x0, $x1, $x1, $x0), PDL->new(0, 0, $y, $y));
  }

  # set color to frame color
  plcol0  (1);

  # draw outline for histogram blocks
  plbin ($xvals->nelem, $xvals, $yvals, 1);  # '1' is oldbins parm:  dont call plenv!

}

sub histogram {
  my $self   = shift;
  my $x      = shift;
  my $nbins  = shift;

  my %opts = @_;

  # Set PLplot to right output stream
  plsstrm($self->{STREAMNUMBER});

  # apply options
  $self->setparm(%opts);

  my ($min, $max);
  if (exists($self->{BOX})) {
    ($min, $max) = @{$self->{BOX}}[0,1];
  } else {
    ($min, $max) = $x->minmax;
    $self->{BOX} = [$min, $max, 0, $x->nelem]; # box probably too tall!
  }

  # set up plotting box
  $self->_setwindow;

  # draw labels
  $self->_drawlabels;

  # plot box
  plcol0  (1); # set to frame color
  plbox ($self->{XTICK}, $self->{NXSUB}, $self->{YTICK}, $self->{NYSUB},
	 $self->{XBOX}, $self->{YBOX}); # !!! note out of order call

  # set line style for plot only (not box)
  pllsty ($self->{LINESTYLE});

  # set line width for plot only (not box)
  plwidth  ($self->{LINEWIDTH});

  # set color for histograms
  plcol0  ($self->{CURRENT_COLOR_IDX});

  plhist ($x, $min, $max, $nbins, 1);  # '1' is oldbins parm:  dont call plenv!

  # set line width back
  plwidth  (0);

  # Flush the PLplot stream.
  plflush();
}

sub bargraph {
  my $self   = shift;
  my $labels = shift; # ref to perl list of labels for bars
  my $values = shift; # pdl of values for bars

  my %opts = @_;

  # max number of readable labels on x axis
  my $maxlab = defined($opts{MAXBARLABELS}) ? $opts{MAXBARLABELS} : 20;
  delete ($opts{MAXBARLABELS});

  # Set PLplot to right output stream
  plsstrm($self->{STREAMNUMBER});
  my $xmax = scalar(@$labels);

  # apply options
  $self->setparm(%opts);

  my $color_stack = $self->{STACKED_BAR_COLORS} // 0; # A list of colors for a stacked bar chart

  # ymax is either the largest value in bars, or the largest total of all stacked bars
  my ($ymin, $ymax);
  if ($color_stack) {
    $ymin = 0;
    $ymax = $values->xchg(0,1)->sumover->max;
  } else {
    ($ymin, $ymax) = $values->minmax;
  }

  unless (exists($self->{BOX})) {
    $self->{BOX} = [0, $xmax, $ymin, $ymax]; # box probably too tall!
  }

  # set up plotting box
  $self->_setwindow;

  # draw labels
  $self->_drawlabels;

  # plot box
  plcol0  (1); # set to frame color
  plbox ($self->{XTICK}, $self->{NXSUB}, $self->{YTICK}, $self->{NYSUB},
	 'bc', $self->{YBOX}); # !!! note out of order call

  # Now respect TEXTPOSITION setting if TEXTMODE eq 'border'
  # This allows the user to tweak the label placement.  D. Hunt 9/4/2007
  my ($side, $disp, $foo, $just) = ('BV', 0.2, 0, 1.0);
  if (defined($self->{TEXTMODE}) && $self->{TEXTMODE} eq 'border') {
    ($side, $disp, $foo, $just) = @{$self->{TEXTPOSITION}};
  }

  # plot labels
  plschr   (0, $self->{CHARSIZE} * 0.7); # use smaller characters
  my $pos = 0;
  my $skip   = int($xmax/$maxlab) + 1;
  for (my $i=0;$i<$xmax;$i+=$skip) {
    $pos = ((0.5+$i)/$xmax);
    my $lab = $$labels[$i];
    plmtex ($disp, $pos, $just, $side, $lab); # !!! out of order parms
  }

  plcol0  ($self->{CURRENT_COLOR_IDX}); # set back to line color

  # set line style for plot only (not box)
  pllsty ($self->{LINESTYLE});

  # set line width for plot only (not box)
  plwidth  ($self->{LINEWIDTH});

  #
  ## draw bars
  #

  # Stacked bar chart
  if ($color_stack) {

    my $idx = 0;
    my $bh  = zeroes($xmax); # base height
    my $w   = ones($xmax);   # bar width
    foreach my $color (@$color_stack) {
      $self->setparm(COLOR => $color);
      plcol0 ($self->{CURRENT_COLOR_IDX}); # set to current box color
      my $x = PDL->sequence($xmax)+0.5;
      my $y = $values->slice(":,($idx)");
      if ($self->{UNFILLED_BARS}) {
        plunfbox1 ($x, $y, $bh, $w);
      } else {
        plfbox1   ($x, $y, $bh, $w);
      }
      $bh += $y;  # Increment the base height by the height of the last set of bars
      $idx++;
    }

    plcol0 ($self->{CURRENT_COLOR_IDX}); # set back to line color

  } else { # Normal bar chart

    if ($self->{UNFILLED_BARS}) {
      plunfbox (PDL->sequence($xmax)+0.5, $values);
    } else {
      plfbox (PDL->sequence($xmax)+0.5, $values);
    }

  }

  # set line width back
  plwidth  (0);

  # set char size back
  plschr (0, $self->{CHARSIZE});

  # Flush the PLplot stream.
  plflush();
}

sub text {
  my $self = shift;
  my $text = shift;

  # Set PLplot to right output stream
  plsstrm($self->{STREAMNUMBER});

  # apply options
  $self->setparm(@_);

  # set up viewport, subpage, world coordinates
  $self->_setwindow;

  # set the color according to the color specified in the object
  plcol0  ($self->{CURRENT_COLOR_IDX});

  # plot either relative to border, or inside view port
  if      ($self->{TEXTMODE} eq 'border') {
    my ($side, $disp, $pos, $just) = @{$self->{TEXTPOSITION}};
    plmtex ($disp, $pos, $just, $side, $text); # !!! out of order parms
  } elsif ($self->{TEXTMODE} eq 'plot') {
    my ($x, $y, $dx, $dy, $just) = @{$self->{TEXTPOSITION}};
    plptex ($x, $y, $dx, $dy, $just, $text);
  }

  # Flush the PLplot stream.
  plflush();
}

# Clear the current page. This should only be used with interactive devices!
sub clear {
  my $self = shift;

  # Set PLplot to right output stream
  plsstrm($self->{STREAMNUMBER});

  plclear();
  return;
}

# Get mouse click coordinates (OO version). This should only be used with interactive devices!
sub cursor {
  my $self = shift;

  # Set PLplot to right output stream
  plsstrm($self->{STREAMNUMBER});

  # Flush the stream, to make sure the plot is visible & current
  plflush();

  # Get the cursor position
  my %gin = plGetCursor();

  # Return an array with the coordinates of the mouse click
  return ($gin{"wX"}, $gin{"wY"}, $gin{"pX"}, $gin{"pY"}, $gin{"dX"}, $gin{"dY"});
}

# Explicitly close a plot and free the object
sub close {
  my $self = shift;

  # Set PLplot to right output stream
  plsstrm($self->{STREAMNUMBER});

  plend1 ();

  # Return this stream number to the pool.
  push (@plplot_stream_pool, $self->{STREAMNUMBER});
  delete $self->{STREAMNUMBER};

  return;
}
#line 2318 "PLplot.pm"






=head1 FUNCTIONS

=cut




#line 2467 "plplot.pd"

my %REORDER = (
 plaxes       => [0,1,6,2,3,7,4,5],
 plbox        => [4,0,1,5,2,3], # 4th arg -> 0th arg, 0th arg -> 1st arg, etc
 plbox3       => [6,7,0,1,8,9,2,3,10,11,4,5],
 plmtex       => [3,0,1,2,4],
 plmtex3      => [3,0,1,2,4],
 plstart      => [2,0,1],
 plstripc     => [\13,14,15,0..12,16..19],
 plmap        => [4,5,0..3],
 plmeridians  => [6,0..5], # 6th PDL arg gets sent as 0th C arg
 plshades     => [0,10,1..9,11,12],
 plshade1     => [0,15,1..14,16,17],
);
sub _reorder {
  my ($name, $int_name, $need_reorder) = splice @_, 0, 3;
  my $ordering = $REORDER{$name};
  die "Cannot find argument reordering for $name" if !defined $ordering;
  my $missing = @_ != @$ordering;
  no strict 'refs';
  return $int_name->(@_) if !$missing and !$need_reorder;
  # either need to insert output ndarray, or reorder, or both
  my ($outarg_index) = map ref($_)?$$_:(), @$ordering;
  confess "$name: wrong number of args but no output arg\n"
    if $missing and !defined $outarg_index;
  my @pdl_args = @_;
  if (!$need_reorder) {
    # args in PDL order; by definition need insert output
    splice @pdl_args, $outarg_index, 0, my $out_ndarray = PDL->null;
    $int_name->(@pdl_args);
    return $out_ndarray;
  }
  # need to reorder, might need to insert output
  my $out_ndarray;
  if ($missing) {
    $out_ndarray = PDL->null;
    my $i = 0;
    @pdl_args = map ref($_) ? $out_ndarray : $pdl_args[$i++], @$ordering;
  }
  my @pdl_indices = map ref($_)?$$_:$_, @$ordering;
  my @input_indices = 0..$#$ordering;
  @pdl_args[@pdl_indices] = @pdl_args[@input_indices];
  $int_name->(@pdl_args);
  $missing ? $out_ndarray : ();
}

# Routine for users to set normal plplot argument order
sub plplot_use_standard_argument_order {
  $PDL::Graphics::PLplot::standard_order = shift;
}
#line 2383 "PLplot.pm"



#line 2523 "plplot.pd"


=pod

The PDL low-level interface to the PLplot library closely mimics the C API.
Users are referred to the PLplot User's Manual, distributed with the source
PLplot tarball.  This manual is also available on-line at the PLplot web
site (L<http://www.plplot.org/>).

There are three differences in the way the functions are called.  The first
one is due to a limitation in the pp_def wrapper of PDL, which forces all
the non-ndarray arguments to be at the end of the arguments list.  It is
the case of strings (C<char *>) arguments in the C API.  This affects the
following functions:

  plaxes
  plbox
  plbox3
  plmtex
  plmtex3
  plstart
  plstripc
  plmap
  plmeridians
  plshades
  plshade1

This difference can be got around by a call to

  plplot_use_standard_argument_order(1);

This re-arranges the string arguments to their proper/intuitive position
compared with the C plplot interface.  This can be restored to its default
by calling:

  plplot_use_standard_argument_order(0);

The second notable different between the C and the PDL APIs is that many of
the PDL calls do not need arguments to specify the size of the the vectors
and/or matrices being passed.  These size parameters are deduced from the
size of the ndarrays, when possible and are just omitted from the C call
when translating it to perl.

The third difference has to do with output parameters.  In C these are
passed in with the input parameters.  In the perl interface, they are omitted.
For example:

C:

  pllegend(&p_legend_width, &p_legend_height,
           opt, position, x, y, plot_width, bg_color, bb_color, bb_style, nrow, ncolumn, nlegend,
           opt_array,
           text_offset, text_scale, text_spacing, text_justification,
           text_colors, (const char **)text, box_colors, box_patterns, box_scales, box_line_widths,
           line_colors, line_styles, line_widths, symbol_colors, symbol_scales, symbol_numbers, (const char **)symbols);

perl:

  my ($legend_width, $legend_height) =
    pllegend ($position, $opt, $x, $y, $plot_width, $bg_color, $nlegend,
    \@opt_array,
    $text_offset, $text_scale, $text_spacing, $test_justification,
    \@text_colors, \@text, \@box_colors, \@box_patterns, \@box_scales, \@line_colors,
    \@line_styles, \@line_widths, \@symbol_colors, \@symbol_scales, \@symbol_numbers, \@symbols);

Some of the API functions implemented in PDL have other specificities in
comparison with the C API and will be discussed below.

=cut
#line 2457 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pladv

=for sig

  Signature: (int page())


=for ref

info not available


=for bad

pladv does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2484 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pladv = \&PDL::pladv;
#line 2491 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plaxes

=for sig

  Signature: (double xzero();double yzero();double xtick();int nxsub();double ytick();int nysub(); char *xopt;char *yopt)


=for ref

info not available


=for bad

plaxes does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2518 "PLplot.pm"



#line 1059 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::plaxes { _reorder('plaxes', 'PDL::_plaxes_int', $standard_order, @_) }
#line 2525 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plaxes = \&PDL::plaxes;
#line 2532 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plbin

=for sig

  Signature: (int nbin();double x(dima);double y(dima);int center())


=for ref

info not available


=for bad

plbin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2559 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plbin = \&PDL::plbin;
#line 2566 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plbox

=for sig

  Signature: (double xtick();int nxsub();double ytick();int nysub(); char *xopt;char *yopt)


=for ref

info not available


=for bad

plbox does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2593 "PLplot.pm"



#line 1059 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::plbox { _reorder('plbox', 'PDL::_plbox_int', $standard_order, @_) }
#line 2600 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plbox = \&PDL::plbox;
#line 2607 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plbox3

=for sig

  Signature: (double xtick();int nsubx();double ytick();int nsuby();double ztick();int nsubz(); char *xopt;char *xlabel;char *yopt;char *ylabel;char *zopt;char *zlabel)


=for ref

info not available


=for bad

plbox3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2634 "PLplot.pm"



#line 1059 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::plbox3 { _reorder('plbox3', 'PDL::_plbox3_int', $standard_order, @_) }
#line 2641 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plbox3 = \&PDL::plbox3;
#line 2648 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plcol0

=for sig

  Signature: (int icolzero())


=for ref

info not available


=for bad

plcol0 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2675 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plcol0 = \&PDL::plcol0;
#line 2682 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plcol1

=for sig

  Signature: (double colone())


=for ref

info not available


=for bad

plcol1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2709 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plcol1 = \&PDL::plcol1;
#line 2716 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plcpstrm

=for sig

  Signature: (int iplsr();int flags())


=for ref

info not available


=for bad

plcpstrm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2743 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plcpstrm = \&PDL::plcpstrm;
#line 2750 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pldid2pc

=for sig

  Signature: (double xmin(dima);double ymin(dima);double xmax(dima);double ymax(dima))


=for ref

info not available


=for bad

pldid2pc does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2777 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pldid2pc = \&PDL::pldid2pc;
#line 2784 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pldip2dc

=for sig

  Signature: (double xmin(dima);double ymin(dima);double xmax(dima);double ymax(dima))


=for ref

info not available


=for bad

pldip2dc does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2811 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pldip2dc = \&PDL::pldip2dc;
#line 2818 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plenv

=for sig

  Signature: (double xmin();double xmax();double ymin();double ymax();int just();int axis())


=for ref

info not available


=for bad

plenv does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2845 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plenv = \&PDL::plenv;
#line 2852 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plenv0

=for sig

  Signature: (double xmin();double xmax();double ymin();double ymax();int just();int axis())


=for ref

info not available


=for bad

plenv0 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2879 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plenv0 = \&PDL::plenv0;
#line 2886 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plerrx

=for sig

  Signature: (int n();double xmin(dima);double xmax(dima);double y(dima))


=for ref

info not available


=for bad

plerrx does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2913 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plerrx = \&PDL::plerrx;
#line 2920 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plerry

=for sig

  Signature: (int n();double x(dima);double ymin(dima);double ymax(dima))


=for ref

info not available


=for bad

plerry does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2947 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plerry = \&PDL::plerry;
#line 2954 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plfill3

=for sig

  Signature: (int n();double x(dima);double y(dima);double z(dima))


=for ref

info not available


=for bad

plfill3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 2981 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plfill3 = \&PDL::plfill3;
#line 2988 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plfont

=for sig

  Signature: (int ifont())


=for ref

info not available


=for bad

plfont does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3015 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plfont = \&PDL::plfont;
#line 3022 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plfontld

=for sig

  Signature: (int fnt())


=for ref

info not available


=for bad

plfontld does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3049 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plfontld = \&PDL::plfontld;
#line 3056 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgchr

=for sig

  Signature: (double [o]p_def();double [o]p_ht())


=for ref

info not available


=for bad

plgchr does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3083 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgchr = \&PDL::plgchr;
#line 3090 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgcompression

=for sig

  Signature: (int [o]compression())


=for ref

info not available


=for bad

plgcompression does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3117 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgcompression = \&PDL::plgcompression;
#line 3124 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgdidev

=for sig

  Signature: (double [o]p_mar();double [o]p_aspect();double [o]p_jx();double [o]p_jy())


=for ref

info not available


=for bad

plgdidev does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3151 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgdidev = \&PDL::plgdidev;
#line 3158 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgdiori

=for sig

  Signature: (double [o]p_rot())


=for ref

info not available


=for bad

plgdiori does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3185 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgdiori = \&PDL::plgdiori;
#line 3192 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgdiplt

=for sig

  Signature: (double [o]p_xmin();double [o]p_ymin();double [o]p_xmax();double [o]p_ymax())


=for ref

info not available


=for bad

plgdiplt does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3219 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgdiplt = \&PDL::plgdiplt;
#line 3226 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgfam

=for sig

  Signature: (int [o]p_fam();int [o]p_num();int [o]p_bmax())


=for ref

info not available


=for bad

plgfam does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3253 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgfam = \&PDL::plgfam;
#line 3260 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plglevel

=for sig

  Signature: (int [o]p_level())


=for ref

info not available


=for bad

plglevel does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3287 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plglevel = \&PDL::plglevel;
#line 3294 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgpage

=for sig

  Signature: (double [o]p_xp();double [o]p_yp();int [o]p_xleng();int [o]p_yleng();int [o]p_xoff();int [o]p_yoff())


=for ref

info not available


=for bad

plgpage does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3321 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgpage = \&PDL::plgpage;
#line 3328 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgspa

=for sig

  Signature: (double [o]xmin();double [o]xmax();double [o]ymin();double [o]ymax())


=for ref

info not available


=for bad

plgspa does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3355 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgspa = \&PDL::plgspa;
#line 3362 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgvpd

=for sig

  Signature: (double [o]p_xmin();double [o]p_xmax();double [o]p_ymin();double [o]p_ymax())


=for ref

info not available


=for bad

plgvpd does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3389 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgvpd = \&PDL::plgvpd;
#line 3396 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgvpw

=for sig

  Signature: (double [o]p_xmin();double [o]p_xmax();double [o]p_ymin();double [o]p_ymax())


=for ref

info not available


=for bad

plgvpw does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3423 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgvpw = \&PDL::plgvpw;
#line 3430 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgxax

=for sig

  Signature: (int [o]p_digmax();int [o]p_digits())


=for ref

info not available


=for bad

plgxax does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3457 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgxax = \&PDL::plgxax;
#line 3464 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgyax

=for sig

  Signature: (int [o]p_digmax();int [o]p_digits())


=for ref

info not available


=for bad

plgyax does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3491 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgyax = \&PDL::plgyax;
#line 3498 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgzax

=for sig

  Signature: (int [o]p_digmax();int [o]p_digits())


=for ref

info not available


=for bad

plgzax does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3525 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgzax = \&PDL::plgzax;
#line 3532 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pljoin

=for sig

  Signature: (double xone();double yone();double xtwo();double ytwo())


=for ref

info not available


=for bad

pljoin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3559 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pljoin = \&PDL::pljoin;
#line 3566 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pllightsource

=for sig

  Signature: (double x();double y();double z())


=for ref

info not available


=for bad

pllightsource does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3593 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pllightsource = \&PDL::pllightsource;
#line 3600 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pllsty

=for sig

  Signature: (int lin())


=for ref

info not available


=for bad

pllsty does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3627 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pllsty = \&PDL::pllsty;
#line 3634 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plmtex

=for sig

  Signature: (double disp();double pos();double just(); char *side;char *text)


=for ref

info not available


=for bad

plmtex does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3661 "PLplot.pm"



#line 1059 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::plmtex { _reorder('plmtex', 'PDL::_plmtex_int', $standard_order, @_) }
#line 3668 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plmtex = \&PDL::plmtex;
#line 3675 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plmtex3

=for sig

  Signature: (double disp();double pos();double just(); char *side;char *text)


=for ref

info not available


=for bad

plmtex3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3702 "PLplot.pm"



#line 1059 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::plmtex3 { _reorder('plmtex3', 'PDL::_plmtex3_int', $standard_order, @_) }
#line 3709 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plmtex3 = \&PDL::plmtex3;
#line 3716 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plpat

=for sig

  Signature: (int nlin();int inc(dima);int del(dima))


=for ref

info not available


=for bad

plpat does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3743 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plpat = \&PDL::plpat;
#line 3750 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plprec

=for sig

  Signature: (int setp();int prec())


=for ref

info not available


=for bad

plprec does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3777 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plprec = \&PDL::plprec;
#line 3784 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plpsty

=for sig

  Signature: (int patt())


=for ref

info not available


=for bad

plpsty does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3811 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plpsty = \&PDL::plpsty;
#line 3818 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plptex

=for sig

  Signature: (double x();double y();double dx();double dy();double just(); char *text)


=for ref

info not available


=for bad

plptex does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3845 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plptex = \&PDL::plptex;
#line 3852 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plptex3

=for sig

  Signature: (double x();double y();double z();double dx();double dy();double dz();double sx();double sy();double sz();double just(); char *text)


=for ref

info not available


=for bad

plptex3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3879 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plptex3 = \&PDL::plptex3;
#line 3886 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plschr

=for sig

  Signature: (double def();double scale())


=for ref

info not available


=for bad

plschr does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3913 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plschr = \&PDL::plschr;
#line 3920 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscmap0n

=for sig

  Signature: (int ncolzero())


=for ref

info not available


=for bad

plscmap0n does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3947 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscmap0n = \&PDL::plscmap0n;
#line 3954 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscmap1n

=for sig

  Signature: (int ncolone())


=for ref

info not available


=for bad

plscmap1n does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 3981 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscmap1n = \&PDL::plscmap1n;
#line 3988 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscol0

=for sig

  Signature: (int icolzero();int r();int g();int b())


=for ref

info not available


=for bad

plscol0 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4015 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscol0 = \&PDL::plscol0;
#line 4022 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscolbg

=for sig

  Signature: (int r();int g();int b())


=for ref

info not available


=for bad

plscolbg does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4049 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscolbg = \&PDL::plscolbg;
#line 4056 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscolor

=for sig

  Signature: (int color())


=for ref

info not available


=for bad

plscolor does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4083 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscolor = \&PDL::plscolor;
#line 4090 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscompression

=for sig

  Signature: (int compression())


=for ref

info not available


=for bad

plscompression does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4117 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscompression = \&PDL::plscompression;
#line 4124 "PLplot.pm"



#line 3103 "plplot.pd"

=head2 plgDevs

=for sig

  $devices = plgDevs ()

=for ref

Returns a HashRef of all device names (key)
and their menu strings (value).

=cut
#line 4142 "PLplot.pm"



#line 3103 "plplot.pd"

=head2 plgFileDevs

=for sig

  $devices = plgFileDevs ()

=for ref

Returns a HashRef of file-oriented device names (key)
and their menu strings (value).

=cut
#line 4160 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsdidev

=for sig

  Signature: (double mar();double aspect();double jx();double jy())


=for ref

info not available


=for bad

plsdidev does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4187 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsdidev = \&PDL::plsdidev;
#line 4194 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsdimap

=for sig

  Signature: (int dimxmin();int dimxmax();int dimymin();int dimymax();double dimxpmm();double dimypmm())


=for ref

info not available


=for bad

plsdimap does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4221 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsdimap = \&PDL::plsdimap;
#line 4228 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsdiori

=for sig

  Signature: (double rot())


=for ref

info not available


=for bad

plsdiori does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4255 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsdiori = \&PDL::plsdiori;
#line 4262 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsdiplt

=for sig

  Signature: (double xmin();double ymin();double xmax();double ymax())


=for ref

info not available


=for bad

plsdiplt does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4289 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsdiplt = \&PDL::plsdiplt;
#line 4296 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsdiplz

=for sig

  Signature: (double xmin();double ymin();double xmax();double ymax())


=for ref

info not available


=for bad

plsdiplz does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4323 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsdiplz = \&PDL::plsdiplz;
#line 4330 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pl_setcontlabelparam

=for sig

  Signature: (double offset();double size();double spacing();int active())


=for ref

info not available


=for bad

pl_setcontlabelparam does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4357 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pl_setcontlabelparam = \&PDL::pl_setcontlabelparam;
#line 4364 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 pl_setcontlabelformat

=for sig

  Signature: (int lexp();int sigdig())


=for ref

info not available


=for bad

pl_setcontlabelformat does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4391 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*pl_setcontlabelformat = \&PDL::pl_setcontlabelformat;
#line 4398 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsfam

=for sig

  Signature: (int fam();int num();int bmax())


=for ref

info not available


=for bad

plsfam does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4425 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsfam = \&PDL::plsfam;
#line 4432 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsmaj

=for sig

  Signature: (double def();double scale())


=for ref

info not available


=for bad

plsmaj does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4459 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsmaj = \&PDL::plsmaj;
#line 4466 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsmin

=for sig

  Signature: (double def();double scale())


=for ref

info not available


=for bad

plsmin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4493 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsmin = \&PDL::plsmin;
#line 4500 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsori

=for sig

  Signature: (int ori())


=for ref

info not available


=for bad

plsori does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4527 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsori = \&PDL::plsori;
#line 4534 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plspage

=for sig

  Signature: (double xp();double yp();int xleng();int yleng();int xoff();int yoff())


=for ref

info not available


=for bad

plspage does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4561 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plspage = \&PDL::plspage;
#line 4568 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plspause

=for sig

  Signature: (int pause())


=for ref

info not available


=for bad

plspause does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4595 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plspause = \&PDL::plspause;
#line 4602 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsstrm

=for sig

  Signature: (int strm())


=for ref

info not available


=for bad

plsstrm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4629 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsstrm = \&PDL::plsstrm;
#line 4636 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plssub

=for sig

  Signature: (int nx();int ny())


=for ref

info not available


=for bad

plssub does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4663 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plssub = \&PDL::plssub;
#line 4670 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plssym

=for sig

  Signature: (double def();double scale())


=for ref

info not available


=for bad

plssym does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4697 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plssym = \&PDL::plssym;
#line 4704 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plstar

=for sig

  Signature: (int nx();int ny())


=for ref

info not available


=for bad

plstar does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4731 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plstar = \&PDL::plstar;
#line 4738 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plstart

=for sig

  Signature: (int nx();int ny(); char *devname)


=for ref

info not available


=for bad

plstart does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4765 "PLplot.pm"



#line 1059 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::plstart { _reorder('plstart', 'PDL::_plstart_int', $standard_order, @_) }
#line 4772 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plstart = \&PDL::plstart;
#line 4779 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plstripa

=for sig

  Signature: (int id();int pen();double x();double y())


=for ref

info not available


=for bad

plstripa does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4806 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plstripa = \&PDL::plstripa;
#line 4813 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plstripd

=for sig

  Signature: (int id())


=for ref

info not available


=for bad

plstripd does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4840 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plstripd = \&PDL::plstripd;
#line 4847 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsvpa

=for sig

  Signature: (double xmin();double xmax();double ymin();double ymax())


=for ref

info not available


=for bad

plsvpa does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4874 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsvpa = \&PDL::plsvpa;
#line 4881 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsxax

=for sig

  Signature: (int digmax();int digits())


=for ref

info not available


=for bad

plsxax does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4908 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsxax = \&PDL::plsxax;
#line 4915 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsxwin

=for sig

  Signature: (int window_id())


=for ref

info not available


=for bad

plsxwin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4942 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsxwin = \&PDL::plsxwin;
#line 4949 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsyax

=for sig

  Signature: (int digmax();int digits())


=for ref

info not available


=for bad

plsyax does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 4976 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsyax = \&PDL::plsyax;
#line 4983 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plszax

=for sig

  Signature: (int digmax();int digits())


=for ref

info not available


=for bad

plszax does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5010 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plszax = \&PDL::plszax;
#line 5017 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plvasp

=for sig

  Signature: (double aspect())


=for ref

info not available


=for bad

plvasp does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5044 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plvasp = \&PDL::plvasp;
#line 5051 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plvpas

=for sig

  Signature: (double xmin();double xmax();double ymin();double ymax();double aspect())


=for ref

info not available


=for bad

plvpas does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5078 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plvpas = \&PDL::plvpas;
#line 5085 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plvpor

=for sig

  Signature: (double xmin();double xmax();double ymin();double ymax())


=for ref

info not available


=for bad

plvpor does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5112 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plvpor = \&PDL::plvpor;
#line 5119 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plw3d

=for sig

  Signature: (double basex();double basey();double height();double xminzero();double xmaxzero();double yminzero();double ymaxzero();double zminzero();double zmaxzero();double alt();double az())


=for ref

info not available


=for bad

plw3d does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5146 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plw3d = \&PDL::plw3d;
#line 5153 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plwidth

=for sig

  Signature: (int width())


=for ref

info not available


=for bad

plwidth does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5180 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plwidth = \&PDL::plwidth;
#line 5187 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plwind

=for sig

  Signature: (double xmin();double xmax();double ymin();double ymax())


=for ref

info not available


=for bad

plwind does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5214 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plwind = \&PDL::plwind;
#line 5221 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plP_gpixmm

=for sig

  Signature: (double p_x(dima);double p_y(dima))


=for ref

info not available


=for bad

plP_gpixmm does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5248 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plP_gpixmm = \&PDL::plP_gpixmm;
#line 5255 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscolbga

=for sig

  Signature: (int r();int g();int b();double a())


=for ref

info not available


=for bad

plscolbga does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5282 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscolbga = \&PDL::plscolbga;
#line 5289 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscol0a

=for sig

  Signature: (int icolzero();int r();int g();int b();double a())


=for ref

info not available


=for bad

plscol0a does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5316 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscol0a = \&PDL::plscol0a;
#line 5323 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plline

=for sig

  Signature: (x(n); y(n))

=for ref

Draws line segments along (x1,y1)->(x2,y2)->(x3,y3)->...

=for bad

If the nth value of either x or y are bad, then it will be skipped, breaking
the line.  In this way, you can specify multiple line segments with a single
pair of x and y ndarrays.

The usage is straight-forward:

=for usage

 plline($x, $y);

For example:

=for example

 # Draw a sine wave
 $x = sequence(100)/10;
 $y = sin($x);

 # Draws the sine wave:
 plline($x, $y);

 # Set values above 3/4 to 'bad', effectively drawing a bunch of detached,
 # capped waves
 $y->setbadif($y > 3/4);
 plline($x, $y);



=for bad

plline processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5378 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plline = \&PDL::plline;
#line 5385 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plpath

=for sig

  Signature: (int n(); x1(); x2(); y1(); y2())


=for ref

info not available


=for bad

plpath ignores the bad-value flag of the input ndarrays.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5412 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plpath = \&PDL::plpath;
#line 5419 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plcolorpoints

=for sig

  Signature: (x(n); y(n); z(n); int sym(); minz(); maxz())

=for ref

PDL-specific: Implements what amounts to a threaded version of plsym.

=for bad

Bad values for z are simply skipped; all other bad values are not processed.

In the following usage, all of the ndarrays must have the same dimensions:

=for usage

 plcolorpoints($x, $y, $z, $symbol_index, $minz, $maxz)

For example:

=for example

 # Generate a parabola some points
 my $x = sequence(30) / 3;   # Regular sampling
 my $y = $x**2;              # Parabolic y
 my $z = 30 - $x**3;         # Cubic coloration
 my $symbols = floor($x);    # Use different symbols for each 1/3 of the plot
                             #  These should be integers.

 plcolorpoints($x, $y, $z, $symbols, -5, 20);  # Thread over everything
 plcolorpoints($x, $y, 1, 1, -1, 2);           # same color and symbol for all



=for bad

plcolorpoints processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5470 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plcolorpoints = \&PDL::plcolorpoints;
#line 5477 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsmem

=for sig

  Signature: (int maxx();int maxy();image(3,x,y))


=for ref

info not available


=for bad

plsmem does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5504 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsmem = \&PDL::plsmem;
#line 5511 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plfbox

=for sig

  Signature: (xo(); yo())

=for ref

Box drawing primitive, taken from PLPLOT bar graph example

=for bad

plfbox does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5536 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plfbox = \&PDL::plfbox;
#line 5543 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plfbox1

=for sig

  Signature: (xo(); yo(); bh(); w())

=for ref

Box drawing primitive that allows specifying base height and width in addition to offset and height

=for bad

plfbox1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5568 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plfbox1 = \&PDL::plfbox1;
#line 5575 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plunfbox

=for sig

  Signature: (xo(); yo())

=for ref

Similar box drawing primitive, but without fill (just draw outline of box)

=for bad

plunfbox does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5600 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plunfbox = \&PDL::plunfbox;
#line 5607 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plunfbox1

=for sig

  Signature: (xo(); yo(); bh(); w())

=for ref

Box drawing primitive that allows specifying base height and width in addition to offset and height

=for bad

plunfbox1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5632 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plunfbox1 = \&PDL::plunfbox1;
#line 5639 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plParseOpts

=for sig

  Signature: (int [o] retval(); SV* argv; int mode)

=for ref

Parse PLplot options given in @ARGV-like arrays

=for bad

plParseOpts does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5664 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plParseOpts = \&PDL::plParseOpts;
#line 5671 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plpoin

=for sig

  Signature: (x(n); y(n); int code())

=for ref

Plots a character at the specified points

=for bad

plpoin does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5696 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plpoin = \&PDL::plpoin;
#line 5703 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plpoin3

=for sig

  Signature: (x(n); y(n); z(n); int code())

=for ref

Plots a character at the specified points in 3 space

=for bad

plpoin3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5728 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plpoin3 = \&PDL::plpoin3;
#line 5735 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plline3

=for sig

  Signature: (x(n); y(n); z(n))

=for ref

Draw a line in 3 space

=for bad

plline3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5760 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plline3 = \&PDL::plline3;
#line 5767 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plpoly3

=for sig

  Signature: (x(n); y(n); z(n); int draw(m); int ifcc())

=for ref

Draws a polygon in 3 space

=for bad

plpoly3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5792 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plpoly3 = \&PDL::plpoly3;
#line 5799 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plhist

=for sig

  Signature: (data(n); datmin(); datmax(); int nbin(); int oldwin())

=for ref

Plot a histogram from unbinned data

=for bad

plhist does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5824 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plhist = \&PDL::plhist;
#line 5831 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plfill

=for sig

  Signature: (x(n); y(n))

=for ref

Area fill

=for bad

plfill does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5856 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plfill = \&PDL::plfill;
#line 5863 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgradient

=for sig

  Signature: (x(n); y(n); angle())

=for ref

Area fill with color gradient

=for bad

plgradient does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5888 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgradient = \&PDL::plgradient;
#line 5895 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsym

=for sig

  Signature: (x(n); y(n); int code())

=for ref

Plots a symbol at the specified points

=for bad

plsym does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5920 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsym = \&PDL::plsym;
#line 5927 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsurf3d

=for sig

  Signature: (x(nx); y(ny); z(nx,ny); int opt(); clevel(nlevel))

=for ref

Plot shaded 3-d surface plot

=for bad

plsurf3d does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5952 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsurf3d = \&PDL::plsurf3d;
#line 5959 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsurf3dl

=for sig

  Signature: (x(nx); y(ny); z(nx,ny); int opt(); clevel(nlevel); int indexxmin(); int indexxmax(); int indexymin(nx); int indexymax(nx))

=for ref

Plot shaded 3-d surface plot with limits

=for bad

plsurf3dl does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 5984 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsurf3dl = \&PDL::plsurf3dl;
#line 5991 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plstyl

=for sig

  Signature: (int mark(nms); int space(nms))

=for ref

Set line style

=for bad

plstyl does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6016 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plstyl = \&PDL::plstyl;
#line 6023 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plseed

=for sig

  Signature: (int seed())


=for ref

info not available


=for bad

plseed does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6050 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plseed = \&PDL::plseed;
#line 6057 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plrandd

=for sig

  Signature: (double [o]rand())


=for ref

info not available


=for bad

plrandd does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6084 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plrandd = \&PDL::plrandd;
#line 6091 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plAllocGrid

=for sig

  Signature: (double xg(nx); double yg(ny); indx [o] grid())

=for ref

Allocates a PLcGrid object for use in pltr1

=for bad

plAllocGrid does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6116 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plAllocGrid = \&PDL::plAllocGrid;
#line 6123 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plAlloc2dGrid

=for sig

  Signature: (double xg(nx,ny); double yg(nx,ny); indx [o] grid())

=for ref

Allocates a PLcGrid2 object for use in pltr2

=for bad

plAlloc2dGrid does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6148 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plAlloc2dGrid = \&PDL::plAlloc2dGrid;
#line 6155 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 init_pltr

=for sig

  Signature: (P(); C(); SV* p0; SV* p1; SV* p2)

Used internally to set the variables C<pltr{0,1,2}_iv> to the "pointers"
of the Perl subroutines C<pltr{1,2,3}>.  These variables are later used by
C<get_standard_pltrcb> to provide the pointers to the C function C<pltr{0,1,2}>.
This accelerates functions like plcont and plshades when those standard
transformation functions are used.


=for bad

init_pltr does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6183 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*init_pltr = \&PDL::init_pltr;
#line 6190 "PLplot.pm"



#line 3996 "plplot.pd"

init_pltr (\&pltr0, \&pltr1, \&pltr2);
#line 6197 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plmap

=for sig

  Signature: (minlong(); maxlong(); minlat(); maxlat(); SV* mapform; char* type)

=for ref

plot continental outline in world coordinates

=for bad

plmap does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6222 "PLplot.pm"



#line 1059 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::plmap { _reorder('plmap', 'PDL::_plmap_int', $standard_order, @_) }
#line 6229 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plmap = \&PDL::plmap;
#line 6236 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plstring

=for sig

  Signature: (x(na); y(na); char* string)

=for ref

plot a string along a line

=for bad

plstring does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6261 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plstring = \&PDL::plstring;
#line 6268 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plstring3

=for sig

  Signature: (x(na); y(na); z(na); char* string)

=for ref

plot a string along a 3D line

=for bad

plstring3 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6293 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plstring3 = \&PDL::plstring3;
#line 6300 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plmeridians

=for sig

  Signature: (dlong(); dlat(); minlong(); maxlong(); minlat(); maxlat(); SV* mapform)

=for ref

Plot the latitudes and longitudes on the background

=for bad

plmeridians does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6325 "PLplot.pm"



#line 1059 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::plmeridians { _reorder('plmeridians', 'PDL::_plmeridians_int', $standard_order, @_) }
#line 6332 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plmeridians = \&PDL::plmeridians;
#line 6339 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plshades

=for sig

  Signature: (z(x,y); xmin(); xmax(); ymin(); ymax();
                  clevel(l); int fill_width(); int cont_color();
                  int cont_width(); int rectangular(); SV* defined; SV* pltr; SV* pltr_data)

=for ref

Shade regions on the basis of value

=for bad

plshades does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6366 "PLplot.pm"



#line 1059 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::plshades { _reorder('plshades', 'PDL::_plshades_int', $standard_order, @_) }
#line 6373 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plshades = \&PDL::plshades;
#line 6380 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plcont

=for sig

  Signature: (f(nx,ny); int kx(); int lx(); int ky(); int ly(); clevel(nlevel); SV* pltr; SV* pltr_data)

=for ref

Plot contours

=for bad

plcont does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6405 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plcont = \&PDL::plcont;
#line 6412 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plmesh

=for sig

  Signature: (x(nx); y(ny); z(nx,ny); int opt())

=for ref

Surface mesh

=for bad

plmesh does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6437 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plmesh = \&PDL::plmesh;
#line 6444 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plmeshc

=for sig

  Signature: (x(nx); y(ny); z(nx,ny); int opt(); clevel(nlevel))

=for ref

Magnitude colored plot surface mesh with contour

=for bad

plmeshc does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6469 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plmeshc = \&PDL::plmeshc;
#line 6476 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plot3d

=for sig

  Signature: (x(nx); y(ny); z(nx,ny); int opt(); int side())

=for ref

3-d surface plot

=for bad

plot3d does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6501 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plot3d = \&PDL::plot3d;
#line 6508 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plot3dc

=for sig

  Signature: (x(nx); y(ny); z(nx,ny); int opt(); clevel(nlevel))

=for ref

Plots a 3-d representation of the function z[x][y] with contour

=for bad

plot3dc does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6533 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plot3dc = \&PDL::plot3dc;
#line 6540 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscmap1l

=for sig

  Signature: (int itype(); isty(n); coord1(n); coord2(n); coord3(n); int rev(nrev))

=for ref

Set color map1 colors using a piece-wise linear relationship

=for bad

plscmap1l does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6565 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscmap1l = \&PDL::plscmap1l;
#line 6572 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plshade1

=for sig

  Signature: (a(nx,ny); left(); right(); bottom(); top(); shade_min();shade_max(); sh_cmap(); sh_color(); sh_width();min_color(); min_width(); max_color(); max_width();rectangular(); SV* defined; SV* pltr; SV* pltr_data)

=for ref

Shade individual region on the basis of value

=for bad

plshade1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6597 "PLplot.pm"



#line 1059 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::plshade1 { _reorder('plshade1', 'PDL::_plshade1_int', $standard_order, @_) }
#line 6604 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plshade1 = \&PDL::plshade1;
#line 6611 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plimage

=for sig

  Signature: (idata(nx,ny); xmin(); xmax(); ymin(); ymax();zmin(); zmax(); Dxmin(); Dxmax(); Dymin(); Dymax())

=for ref

Plot gray-level image

=for bad

plimage does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6636 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plimage = \&PDL::plimage;
#line 6643 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plimagefr

=for sig

  Signature: (idata(nx,ny); xmin(); xmax(); ymin(); ymax();zmin(); zmax(); valuemin(); valuemax(); SV* pltr; SV* pltr_data)

=for ref

Plot image with transformation

=for bad

plimagefr does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6668 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plimagefr = \&PDL::plimagefr;
#line 6675 "PLplot.pm"



#line 4363 "plplot.pd"

=head2 plxormod

=for sig

  $status = plxormod ($mode)

=for ref

Set xor mode:
mode = 1-enter, 0-leave, status = 0 if not interactive device

See the PLplot manual for reference.

=cut
#line 6695 "PLplot.pm"



#line 4394 "plplot.pd"

=head2 plGetCursor

=for sig

  %gin = plGetCursor ()

=for ref

plGetCursor waits for graphics input event and translate to world
coordinates and returns a hash with the following keys:

    type:      of event (CURRENTLY UNUSED)
    state:     key or button mask
    keysym:    key selected
    button:    mouse button selected
    subwindow: subwindow (alias subpage, alias subplot) number
    string:    translated string
    pX, pY:    absolute device coordinates of pointer
    dX, dY:    relative device coordinates of pointer
    wX, wY:    world coordinates of pointer

Returns an empty hash if no translation to world coordinates is possible.

=cut
#line 6725 "PLplot.pm"



#line 4457 "plplot.pd"

=head2 plgstrm

=for sig

  $strm = plgstrm ()

=for ref

Returns the number of the current output stream.

=cut
#line 6742 "PLplot.pm"



#line 4484 "plplot.pd"

=head2 plgsdev

=for sig

  $driver = plgdev ()

=for ref

Returns the current driver name.

=cut
#line 6759 "PLplot.pm"



#line 4524 "plplot.pd"

=head2 plmkstrm

=for sig

  $strm = plmkstrm ()

=for ref

Creates a new stream and makes it the default.  Returns the number of
the created stream.

=cut
#line 6777 "PLplot.pm"



#line 4552 "plplot.pd"

=head2 plgver

=for sig

  $version = plgver ()

=for ref

Get the current library version number

See the PLplot manual for reference.

=cut
#line 6796 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plstripc

=for sig

  Signature: (xmin(); xmax(); xjump(); ymin(); ymax();xlpos(); ylpos(); int y_ascl(); int acc();int colbox(); int collab();int colline(n); int styline(n);int [o] id(); char* xspec; char* yspec; SV* legline;char* labx; char* laby; char* labtop)

=for ref

FIXME: documentation here!

=for bad

plstripc does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6821 "PLplot.pm"



#line 1059 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

sub PDL::plstripc { _reorder('plstripc', 'PDL::_plstripc_int', $standard_order, @_) }
#line 6828 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plstripc = \&PDL::plstripc;
#line 6835 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgriddata

=for sig

  Signature: (x(npts); y(npts); z(npts); xg(nptsx); yg(nptsy);int type(); data(); [o] zg(nptsx,nptsy))

=for ref

FIXME: documentation here!

=for bad

plgriddata does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 6860 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgriddata = \&PDL::plgriddata;
#line 6867 "PLplot.pm"



#line 4659 "plplot.pd"

=head2 plarc

=for sig

  plarc ($x, $y, $a, $b, $angle1, $angle2, $rotate, $fill);

=for ref

Draw a (possibly) filled arc centered at x, y with semimajor axis a and semiminor axis b, starting at angle1 and ending at angle2.
See the PLplot manual for reference.

=cut
#line 6885 "PLplot.pm"



#line 4691 "plplot.pd"

=head2 plstransform

=for sig

  plstransform ($subroutine_reference, $data);

=for ref

Sets the default transformation routine for plotting.

  sub mapform {
    my ($x, $y, $data) = @_;

    my $radius = 90.0 - $y;
    my $xp = $radius * cos ($x * pi / 180);
    my $yp = $radius * sin ($x * pi / 180);

    return ($xp, $yp);
  }
  plstransform (\&mapform, undef);

See the PLplot manual for more details.

=cut
#line 6915 "PLplot.pm"



#line 4732 "plplot.pd"

=head2 plslabelfunc

=for sig

  plslabelfunc ($subroutine_reference);

=for ref

  # A custom axis labeling function for longitudes and latitudes.
  sub geolocation_labeler {
    my ($axis, $value, $length) = @_;
    my ($direction_label, $label_val);
    if (($axis == PL_Y_AXIS) && $value == 0) {
        return "Eq";
      } elsif ($axis == PL_Y_AXIS) {
      $label_val = $value;
      $direction_label = ($label_val > 0) ? " N" : " S";
    } elsif ($axis == PL_X_AXIS) {
      my $times  = floor((abs($value) + 180.0 ) / 360.0);
      $label_val = ($value < 0) ? $value + 360.0 * $times : $value - 360.0 * $times;
      $direction_label = ($label_val > 0) ? " E"
                       : ($label_val < 0) ? " W"
                       :                    "";
    }
    return substr (sprintf ("%.0f%s", abs($label_val), $direction_label), 0, $length);
  }
  plslabelfunc(\&geolocation_labeler);

The PDL version of plslabelfunc only has one argument--the perl subroutine
to do the label translation:

  my $labeltext = perl_labelfunc($axis, $value, $length);

No 'data' argument is used, it is assumed that global data or a closure containing
necessary data can be used in 'perl_labelfunc'.

See the PLplot manual for more details.

=cut
#line 6960 "PLplot.pm"



#line 4787 "plplot.pd"

=head2 pllegend

=for sig

  my ($legend_width, $legend_height) =
      pllegend ($position, $opt, $x, $y, $plot_width, $bg_color, $nlegend,
      \@opt_array,
      $text_offset, $text_scale, $text_spacing, $test_justification,
      \@text_colors, \@text, \@box_colors, \@box_patterns, \@box_scales, \@line_colors,
      \@line_styles, \@line_widths, \@symbol_colors, \@symbol_scales, \@symbol_numbers, \@symbols);

=for ref

See the PLplot manual for more details.

=cut
#line 6982 "PLplot.pm"



#line 4965 "plplot.pd"

=head2 plspal0

=for sig

  plspal0($filename);

=for ref

Set color palette 0 from the input .pal file.  See the PLplot manual for more details.

=cut
#line 6999 "PLplot.pm"



#line 4990 "plplot.pd"

=head2 plspal1

=for sig

  plspal1($filename);

=for ref

Set color palette 1 from the input .pal file.  See the PLplot manual for more details.

=cut
#line 7016 "PLplot.pm"



#line 5014 "plplot.pd"

=head2 plbtime

=for sig

  my ($year, $month, $day, $hour, $min, $sec) = plbtime($ctime);

=for ref

Calculate broken-down time from continuous time for current stream.

=cut
#line 7033 "PLplot.pm"



#line 5050 "plplot.pd"

=head2 plconfigtime

=for sig

  plconfigtime($scale, $offset1, $offset2, $ccontrol, $ifbtime_offset, $year, $month, $day, $hour, $min, $sec);

=for ref

Configure transformation between continuous and broken-down time (and
vice versa) for current stream.

=cut
#line 7051 "PLplot.pm"



#line 5086 "plplot.pd"

=head2 plctime

=for sig

  my $ctime = plctime($year, $month, $day, $hour, $min, $sec);

=for ref

Calculate continuous time from broken-down time for current stream.

=cut
#line 7068 "PLplot.pm"



#line 5117 "plplot.pd"

=head2 pltimefmt

=for sig

  pltimefmt($fmt);

=for ref

Set format for date / time labels. Labels must be configured to treat values as
seconds since the epoch via the XBOX/YBOX flags. C<$fmt> is generally
consistent with the POSIX strpformat/strftime flags, but see the PLplot manual
for details.

=cut
#line 7088 "PLplot.pm"



#line 5143 "plplot.pd"

=head2 plsesc

=for sig

  plsesc($esc);

=for ref


Set the escape character for text strings.  See the PLplot manual for more details.

=cut
#line 7106 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plvect

=for sig

  Signature: (u(nx,ny); v(nx,ny); scale(); SV* pltr; SV* pltr_data)

=for ref

Vector field plots

=for bad

plvect does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7131 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plvect = \&PDL::plvect;
#line 7138 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsvect

=for sig

  Signature: (arrowx(npts); arrowy(npts); int fill())

=for ref

Give zero-length PDLs for arrowx and arrowy to pass NULL to PLplot func.

=for bad

plsvect does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7163 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsvect = \&PDL::plsvect;
#line 7170 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plhlsrgb

=for sig

  Signature: (double h();double l();double s();double [o]p_r();double [o]p_g();double [o]p_b())


=for ref

info not available


=for bad

plhlsrgb does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7197 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plhlsrgb = \&PDL::plhlsrgb;
#line 7204 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgcol0

=for sig

  Signature: (int icolzero(); int [o]r(); int [o]g(); int [o]b())


=for ref

info not available


=for bad

plgcol0 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7231 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgcol0 = \&PDL::plgcol0;
#line 7238 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgcolbg

=for sig

  Signature: (int [o]r(); int [o]g(); int [o]b())


=for ref

info not available


=for bad

plgcolbg does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7265 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgcolbg = \&PDL::plgcolbg;
#line 7272 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscmap0

=for sig

  Signature: (int r(n); int g(n); int b(n))


=for ref

info not available


=for bad

plscmap0 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7299 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscmap0 = \&PDL::plscmap0;
#line 7306 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscmap1

=for sig

  Signature: (int r(n); int g(n); int b(n))


=for ref

info not available


=for bad

plscmap1 does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7333 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscmap1 = \&PDL::plscmap1;
#line 7340 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgcol0a

=for sig

  Signature: (int icolzero(); int [o]r(); int [o]g(); int [o]b(); double [o]a())


=for ref

info not available


=for bad

plgcol0a does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7367 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgcol0a = \&PDL::plgcol0a;
#line 7374 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgcolbga

=for sig

  Signature: (int [o]r(); int [o]g(); int [o]b(); double [o]a())


=for ref

info not available


=for bad

plgcolbga does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7401 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgcolbga = \&PDL::plgcolbga;
#line 7408 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscmap0a

=for sig

  Signature: (int r(n); int g(n); int b(n); double a(n))


=for ref

info not available


=for bad

plscmap0a does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7435 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscmap0a = \&PDL::plscmap0a;
#line 7442 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscmap1a

=for sig

  Signature: (int r(n); int g(n); int b(n); double a(n))


=for ref

info not available


=for bad

plscmap1a does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7469 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscmap1a = \&PDL::plscmap1a;
#line 7476 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plscmap1la

=for sig

  Signature: (int itype(); isty(n); coord1(n); coord2(n); coord3(n); coord4(n); int rev(nrev))

=for ref

Set color map1 colors using a piece-wise linear relationship, include alpha channel

=for bad

plscmap1la does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7501 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plscmap1la = \&PDL::plscmap1la;
#line 7508 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plgfont

=for sig

  Signature: (int [o]p_family(); int [o]p_style(); int [o]p_weight())


=for ref

info not available


=for bad

plgfont does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7535 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plgfont = \&PDL::plgfont;
#line 7542 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plsfont

=for sig

  Signature: (int family(); int style(); int weight())


=for ref

info not available


=for bad

plsfont does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7569 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plsfont = \&PDL::plsfont;
#line 7576 "PLplot.pm"



#line 1058 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"



=head2 plcalc_world

=for sig

  Signature: (double rx(); double ry(); double [o]wx(); double [o]wy(); int [o]window())


=for ref

info not available


=for bad

plcalc_world does not process bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.


=cut
#line 7603 "PLplot.pm"



#line 1060 "/home/osboxes/.perlbrew/libs/perl-5.32.0@normal/lib/perl5/x86_64-linux/PDL/PP.pm"

*plcalc_world = \&PDL::plcalc_world;
#line 7610 "PLplot.pm"



#line 5355 "plplot.pd"

=head2 pl_cmd

=for sig

   pl_cmd($CMD, $data);

=for ref

   See the PLplot manual for reference.
   Gives access to low level driver. $CMD is an integer. $data opaque data.

=cut
#line 7628 "PLplot.pm"



#line 5380 "plplot.pd"

=head2 pl_setCairoCtx

=for sig

   pl_setCairoCtx($cairo_context);

=for ref

   Used with cairo external drivers to set the cairo context.
   $cairo_context should be a Cairo::Context object.
   Uses pl_cmd underneath, but extracts the real C struct pointer from the Cairo::Context.

=cut
#line 7647 "PLplot.pm"



#line 5406 "plplot.pd"


=pod

=head1 WARNINGS AND ERRORS

PLplot gives many errors and warnings.  Some of these are given by the
PDL interface while others are internal PLplot messages.  Below are
some of these messages, and what you need to do to address them:

=over

=item *
Box must be a ref to a four element array

When specifying a box, you must pass a reference to a
four-element array, or use an anonymous four-element array.

 # Gives trouble:
 $pl->xyplot($x, $y, BOX => (0, 0, 100, 200) );
 # What you meant to say was:
 $pl->xyplot($x, $y, BOX => [0, 0, 100, 200] );

=item *
Too many colors used! (max 15)


=back

=head1 AUTHORS

  Doug Hunt <dhunt@ucar.edu>
  Rafael Laboissiere <rlaboiss@users.sourceforge.net>
  David Mertens <mertens2@illinois.edu>

=head1 SEE ALSO

perl(1), PDL(1), L<http://www.plplot.org/>

The other common graphics packages include L<PDL::PGPLOT>
and L<PDL::TriD>.

=cut
#line 7695 "PLplot.pm"






# Exit with OK status

1;
