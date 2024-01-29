#!/usr/bin/perl
# exercise Content.pm's bspline call as much as possible
# outputs Bspline.pdf
# author: Phil M Perry

# notes on display:
#
# -debug settings: 0 = only black line of final Bezier spline (default)
#                  1 = draw filled green circles of given points (incl move-to)
#                  2 = draw thick green line of polyline between points
#                  3 = draw thin blue line of natural tangent at each point
#                  4 = draw red open circle control points if curve, with
#                       dashed red line connecting to associated point
#      Note that debug drawings are fixed in Content.pm's bspline() call and
#      only the black line output is handled here.
#
# -firstseg controls display and shape of first segment (from current point)
# -lastseg controls display and shape of last segment (to final point)
#    'curve'       = draw Bezier curve (default)
#    'line2'       = draw straight line between points, forcing new tangents
#    'line1'       = draw curve, but constrain at "end" point to be on polyline
#    'constraint2' = like 'line2', but not drawn
#    'constraint1' = like 'line1', but not drawn
#
# -ratio  value > 0 as distance of a curve's control point from its associated 
#           end point, as a fraction of the polyline distance to the next point
#
# -colinear 
#    'curve' = attempt to draw Bezier curve from or to a colinear point
#    'line'  = force a line segment (equals polyline segment) between adjacent
#                colinear points

use warnings;
use strict;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.021'; # manually update whenever code is changed

use Math::Trig;
use List::Util qw(min max);

#use constant in => 1 / 72;
#use constant cm => 2.54 / 72; 
#use constant mm => 25.4 / 72;
#use constant pt => 1;

use PDF::Builder;

my $PDFname = $0;
   $PDFname =~ s/\..*$//;  # remove extension
   $PDFname .= '.pdf';     # add new extension
my $globalX = 0; 
my $globalY = 0;
my $compress = 'none';
#my $compress = 'flate';

my $pdf = PDF::Builder->new(-compress => $compress);
my ($page, $grfx, $text); # objects for page, graphics, text
my (@points, $i);
my ($font);
my @axisOffset = (5, 5); # clear the edge of the cell

my $db = 4;  # debug level

my $pageNo = 0;
# ================ pg 1
nextPage();
# next (first) page of output, 595pt wide x 792pt high

my $fontR = $pdf->corefont('Times-Roman');
my $fontI = $pdf->corefont('Times-Italic');
my $fontC = $pdf->corefont('Courier');

# ---------------------------------------
my ($voffset, $hoffset, @pts);

$grfx->strokecolor('black');
$grfx->linewidth(1);
$grfx->linedash();

# @points includes first (move to) point
# ================ pg 1
# duplicate points removal row 1
@points = (10,10, 10,10, 10,10, 10,10); # all same point (no-op)
_movedraw(30,700, '1.1', 'show nothing, 1 pt total');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
@points = (10,10, 10,10, 50,50, 50,50); # line segment
_movedraw(100,700, '1.2', '2 pt, single line segment');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();

# degenerate cases row 2,3
@points = (10,10, 50,50); # line segment
_movedraw(30,600, '2.1', 'single line segment');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
@points = (10,10, 50,50, 90,90); # 2 colinear line segments
_movedraw(100,600, '2.2', 'straight line of 2 segments');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
@points = (10,10, 30,50, 90,20); # 3 points non-colinear
_movedraw(200,600, '2.3', '2 curves thru 3 pts');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
# loop-de-loop to a single point, repeating base point
@points = (10,10, 40,30, 70,60, 40,30, 60,10);
_movedraw(350,600, '2.4', 'tight loop');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
@points = (10,10, 30,50, 90,20); # 3 points non-colinear
_movedraw(200,600, '2.3', '2 curves thru 3 pts');
# line2 forced to line1 since only two segments
_movedraw(30,500, '3.1', '2 segments lineX forced to line1 both');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2');
$grfx->stroke();
# same as
_movedraw(140,500, '3.2', '2 segments lineX forced to line1 both');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line1', -lastseg=>'line1');
$grfx->stroke();
_movedraw(250,500, '3.3', '2 segments lineX forced to line1 both');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line1', -lastseg=>'line2');
$grfx->stroke();
_movedraw(360,500, '3.4', '2 segments lineX forced to line1 both');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();

# 3 colinear points beginning and end row 4
@points = (10,10, 30,30, 50,50, 90,50, 110,30, 130,10);
_movedraw(30,400, '4.1', 'ends 2 straight, arc between');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
@points = (10,10, 30,10, 50,10, 90,50, 110,50, 130,50);
_movedraw(180,400, '4.2', 'S-shaped curve, ends 2 straight');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
@points = (10,10, 30,10, 50,10, 30,50, 50,50, 70,50);
_movedraw(350,400, '4.3', 'more extreme S-shaped curve, ends 2 straight');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
_movedraw(480,400, '4.4', 'like 4.3 but longer control lines');
$grfx->bspline(\@pts, -debug=>$db, -ratio=>0.75);
$grfx->stroke();

# one simple curve row 5
@points = (10,10, 30,50, 90,20, 150,40);
_movedraw(30,300, '5.1', '3 curved segments');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
# force first and last to lines
_movedraw(230,300, '5.2', 'ends forced straight lines, center S-curve');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2');
$grfx->stroke();
_movedraw(400,280, '5.3', 'like 5.2 but longer control lines');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2', -ratio=>1);
$grfx->stroke();

# long end colinears row 6
@points = (10,10, 20,12, 30,14, 40,16, 50,18, 60,20, 70,22, 80,24);
_movedraw(30,230, '6.1', '7 straight segments in a row');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
# short interior colinears row 6
@points = (20,10, 30,30, 50,30, 70,30, 80,10);
_movedraw(120,200, '6.2', '4 curved, center 2 nearly flat');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 80,50);
_movedraw(235,200, '6.3', '4 curved, center 2 nearly flat');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
# longer interior colinears row 6
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,10);
_movedraw(340,200, '6.4', 'like 6.2 but 3 nearly flat in center');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,50);
_movedraw(470,200, '6.5', 'like 6.4 but 3 nearly flat in center');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();

# even longer interior colinears row 7
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,10);
_movedraw(30,100, '7.1', 'like 6.4 but 4 nearly flat in center');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,50);
_movedraw(170,100, '7.2', 'like 6.5 but 4 nearly flat in center');
$grfx->bspline(\@pts, -debug=>$db);
$grfx->stroke();
# shorter interior colinears with lines row 7
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,10);
_movedraw(340,100, '7.3', 'like 6.4 but center forced line');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,50);
_movedraw(470,100, '7.4', 'like 6.5 but center forced line');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line');
$grfx->stroke();

# even longer interior colinears row 8
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,10);
_movedraw(30,10, '8.1', 'like 7.1 but 2 center forced lines');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,50);
_movedraw(170,10, '8.2', 'like 7.2 but 2 center forced lines');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line');
$grfx->stroke();

# ================ pg 2
nextPage();
# try a bunch of constraints
$grfx->strokecolor('black');
$grfx->linewidth(1);
$grfx->linedash();

# @points includes first (move to) point
# duplicate points removal row 1
@points = (10,10, 10,10, 10,10, 10,10); # all same point (no-op)
_movedraw(30,700, '1.1', 'like 1-1.1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'curve', -lastseg=>'curve');
$grfx->stroke();
@points = (10,10, 10,10, 50,50, 50,50); # line segment
_movedraw(100,700, '1.2', 'like 1-1.2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'curve', -lastseg=>'curve');
$grfx->stroke();

# degenerate cases row 2,3
@points = (10,10, 50,50); # line segment
_movedraw(30,600, '2.1', 'like 1-2.1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
@points = (10,10, 50,50, 90,90); # 2 colinear line segments
_movedraw(100,600, '2.2', 'like 1-2.2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
@points = (10,10, 30,50, 90,20); # 3 points non-colinear
_movedraw(200,600, '2.3', '2 curves that blend to straight lines due to override of constraintX by line1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
# line2 forced to line1 since only two segments
_movedraw(30,500, '3.1', 'like 2.3 as forced to line1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2');
$grfx->stroke();
# same as
_movedraw(140,500, '3.2', 'like 2.3 as forced to line1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line1', -lastseg=>'line1');
$grfx->stroke();
_movedraw(250,500, '3.3', 'like 2.3 as forced to line1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line1', -lastseg=>'line2');
$grfx->stroke();
_movedraw(360,500, '3.4', 'like 2.3 as forced to line1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();

# 3 colinear points beginning and end row 4
@points = (10,10, 30,30, 50,50, 90,50, 110,30, 130,10);
_movedraw(30,400, '4.1', 'like 1-4.1 but first and last segments gone and colinearity overrides constraint1 to force constraint2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
@points = (10,10, 30,10, 50,10, 90,50, 110,50, 130,50);
_movedraw(180,400, '4.2', 'like 1-4.2 but first and last segments gone and colinearity overrides constraint1 to force constraint2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
@points = (10,10, 30,10, 50,10, 30,50, 50,50, 70,50);
_movedraw(350,400, '4.3', 'like 1-4.3 but first and last segments gone');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
_movedraw(480,400, '4.4', 'like 1-4.4 but first and last segments gone with longer control points making more extreme S-curve');
$grfx->bspline(\@pts, -debug=>$db, -ratio=>0.75, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();

# one simple curve row 5
@points = (10,10, 30,50, 90,20, 150,40);
_movedraw(30,300, '5.1', 'invisible left end straight line causing curve to match, invisible right end curve matches tangent, end tangent is polyline');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
# force first and last to lines
_movedraw(230,300, '5.2', 'ends forced to straight lines (line2), center curve matches end lines at their tangents');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2');
$grfx->stroke();
_movedraw(400,280, '5.3', 'like 5.2 but more extreme from longer control lines');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2', -ratio=>1);
$grfx->stroke();

# long end colinears row 6
@points = (10,10, 20,12, 30,14, 40,16, 50,18, 60,20, 70,22, 80,24);
_movedraw(30,230, '6.1', 'like 1-6.1 with end segments not drawn');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
# short interior colinears row 6
@points = (20,10, 30,30, 50,30, 70,30, 80,10);
_movedraw(120,200, '6.2', 'ends not drawn, left is line, right is curve, drawn line tangents match');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 80,50);
_movedraw(235,200, '6.3', 'ends not drawn, left is line, right is curve, drawn line tangents match');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
# longer interior colinears row 6
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,10);
_movedraw(340,200, '6.4', 'like 1-6.4 but end segments not drawn and tangents match');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,50);
_movedraw(470,200, '6.5', 'like 1-6.5 but end segments not drawn and tangents match');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();

# even longer interior colinears row 7
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,10);
_movedraw(30,100, '7.1', 'like 6.4 but new center point is flat');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,50);
_movedraw(170,100, '7.2', 'like 6.5 but new center point');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
# shorter interior colinears with lines row 7
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,10);
_movedraw(340,100, '7.3', 'like 6.4 but force center line');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,50);
_movedraw(470,100, '7.4', 'like 6.5 but force center line');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();

# even longer interior colinears row 8
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,10);
_movedraw(30,10, '8.1', 'like 7.1 but force 2 center lines');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,50);
_movedraw(170,10, '8.2', 'like 7.2 but force 2 center lines');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'constraint2', -lastseg=>'constraint1');
$grfx->stroke();

# ================ pg 3
nextPage();
# try a bunch of constraints
$grfx->strokecolor('black');
$grfx->linewidth(1);
$grfx->linedash();

# @points includes first (move to) point
# duplicate points removal row 1
@points = (10,10, 10,10, 10,10, 10,10); # all same point (no-op)
_movedraw(30,700, '1.1', 'like 2-1.1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'curve', -lastseg=>'curve');
$grfx->stroke();
@points = (10,10, 10,10, 50,50, 50,50); # line segment
_movedraw(100,700, '1.2', 'like 2-1.2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'curve', -lastseg=>'curve');
$grfx->stroke();

# degenerate cases row 2,3
@points = (10,10, 50,50); # line segment
_movedraw(30,600, '2.1', 'like 2-2.1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
@points = (10,10, 50,50, 90,90); # 2 colinear line segments
_movedraw(100,600, '2.2', 'like 2-2.2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
@points = (10,10, 30,50, 90,20); # 3 points non-colinear
_movedraw(200,600, '2.3', 'like 2-2.3');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
# line2 forced to line1 since only two segments
_movedraw(30,500, '3.1', 'like 2-3.1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2');
$grfx->stroke();
# same as
_movedraw(140,500, '3.2', 'like 2-3.2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line1', -lastseg=>'line1');
$grfx->stroke();
_movedraw(250,500, '3.3', 'like 2-3.3');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line1', -lastseg=>'line2');
$grfx->stroke();
_movedraw(360,500, '3.4', 'like 2-3.4');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();

# 3 colinear points beginning and end row 4
@points = (10,10, 30,30, 50,50, 90,50, 110,30, 130,10);
_movedraw(30,400, '4.1', 'like 2-4.1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
@points = (10,10, 30,10, 50,10, 90,50, 110,50, 130,50);
_movedraw(180,400, '4.2', 'like 2-4.2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
@points = (10,10, 30,10, 50,10, 30,50, 50,50, 70,50);
_movedraw(350,400, '4.3', 'like 2-4.3');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
_movedraw(480,400, '4.4', 'like 2-4.4');
$grfx->bspline(\@pts, -debug=>$db, -ratio=>0.75, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();

# one simple curve row 5
@points = (10,10, 30,50, 90,20, 150,40);
_movedraw(30,300, '5.1', 'end segs invisible, left curve right line, center tangents match');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
# force first and last to lines
_movedraw(230,300, '5.2', 'like 2-5.2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2');
$grfx->stroke();
_movedraw(400,280, '5.3', 'like 2-5.3');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2', -ratio=>1);
$grfx->stroke();

# long end colinears row 6
@points = (10,10, 20,12, 30,14, 40,16, 50,18, 60,20, 70,22, 80,24);
_movedraw(30,230, '6.1', 'like 2-6.1, colinearity overrides constraint1 to constraint2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
# short interior colinears row 6
@points = (20,10, 30,30, 50,30, 70,30, 80,10);
_movedraw(120,200, '6.2', 'left invisible curve, right invisible line, curve tangents match');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 80,50);
_movedraw(235,200, '6.3', 'left invisible curve, right invisible line, curve tangents match');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
# longer interior colinears row 6
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,10);
_movedraw(340,200, '6.4', 'like 6.2 but extra colinear point in middle');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,50);
_movedraw(470,200, '6.5', 'like 6.3 but extra colinear point in middle');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();

# even longer interior colinears row 7
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,10);
_movedraw(30,100, '7.1', 'like 6.4 but new flat center point');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,50);
_movedraw(170,100, '7.2', 'like 6.5 but new center point');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
# shorter interior colinears with lines row 7
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,10);
_movedraw(340,100, '7.3', 'like 6.4 but force center to line');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,50);
_movedraw(470,100, '7.4', 'like 6.5 but force center to line');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();

# even longer interior colinears row 8
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,10);
_movedraw(30,10, '8.1', 'like 7.1 but force center 2 segments to lines');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,50);
_movedraw(170,10, '8.2', 'like 7.2 but force center 2 segments to lines');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'constraint1', -lastseg=>'constraint2');
$grfx->stroke();

# ================ pg 4
nextPage();
# try a bunch of lines
$grfx->strokecolor('black');
$grfx->linewidth(1);
$grfx->linedash();

# @points includes first (move to) point
# duplicate points removal row 1
@points = (10,10, 10,10, 10,10, 10,10); # all same point (no-op)
_movedraw(30,700, '1.1', 'like 3-1.1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'curve', -lastseg=>'curve');
$grfx->stroke();
@points = (10,10, 10,10, 50,50, 50,50); # line segment
_movedraw(100,700, '1.2', 'like 3-1.2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'curve', -lastseg=>'curve');
$grfx->stroke();

# degenerate cases row 2,3
@points = (10,10, 50,50); # line segment
_movedraw(30,600, '2.1', 'like 3-2.1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
@points = (10,10, 50,50, 90,90); # 2 colinear line segments
_movedraw(100,600, '2.2', 'like 3-2.2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
@points = (10,10, 30,50, 90,20); # 3 points non-colinear
_movedraw(200,600, '2.3', 'like 3-2.3');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
# line2 forced to line1 since only two segments
_movedraw(30,500, '3.1', 'like 3-3.1');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2');
$grfx->stroke();
# same as
_movedraw(140,500, '3.2', 'like 3-3.2');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line1', -lastseg=>'line1');
$grfx->stroke();
_movedraw(250,500, '3.3', 'like 3-3.3');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line1', -lastseg=>'line2');
$grfx->stroke();
_movedraw(360,500, '3.4', 'like 3-3.4');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();

# 3 colinear points beginning and end row 4
@points = (10,10, 30,30, 50,50, 90,50, 110,30, 130,10);
_movedraw(30,400, '4.1', 'left line1 overridden by colinearity, right line2 line anyway');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
@points = (10,10, 30,10, 50,10, 90,50, 110,50, 130,50);
_movedraw(180,400, '4.2', 'right line1 overridden by colinearity, left line2 line anyway');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
@points = (10,10, 30,10, 50,10, 30,50, 50,50, 70,50);
_movedraw(350,400, '4.3', 'like 4.2 but more extreme S-curve');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
_movedraw(480,400, '4.4', 'like 4.3 but longer control points');
$grfx->bspline(\@pts, -debug=>$db, -ratio=>0.75, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();

# one simple curve row 5
@points = (10,10, 30,50, 90,20, 150,40);
_movedraw(30,300, '5.1', 'force line left end, force constrained curve right end');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
# force first and last to lines
_movedraw(230,300, '5.2', 'force lines both ends, curve tangents match');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2');
$grfx->stroke();
_movedraw(400,280, '5.3', 'like 5.2 with longer control points for more extreme S-curve');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line2', -ratio=>1);
$grfx->stroke();

# long end colinears row 6
@points = (10,10, 20,12, 30,14, 40,16, 50,18, 60,20, 70,22, 80,24);
_movedraw(30,230, '6.1', 'right end line1 overridden to line by colinearity');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
# short interior colinears row 6
@points = (20,10, 30,30, 50,30, 70,30, 80,10);
_movedraw(120,200, '6.2', 'force left line, right constrained curve, tangents match');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 80,50);
_movedraw(235,200, '6.3', 'force left line, right constrained curve, tangents match');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
# longer interior colinears row 6
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,10);
_movedraw(340,200, '6.4', 'like 6.2 with extra middle point');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,50);
_movedraw(470,200, '6.5', 'like 6.3 with extra middle point');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();

# even longer interior colinears row 7
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,10);
_movedraw(30,100, '7.1', 'like 6.4 with new flat center point');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,50);
_movedraw(170,100, '7.2', 'like 6.5 with new center point');
$grfx->bspline(\@pts, -debug=>$db, -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
# shorter interior colinears with lines row 7
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,10);
_movedraw(340,100, '7.3', 'like 6.4 with center segment forced to line');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 100,50);
_movedraw(470,100, '7.4', 'like 6.5 with center segment forced to line');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();

# even longer interior colinears row 8
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,10);
_movedraw(30,10, '8.1', 'like 7.1 but center colinear segments forced to lines');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();
@points = (20,10, 30,30, 50,30, 70,30, 90,30, 110,30, 120,50);
_movedraw(170,10, '8.2', 'like 7.2 but center colinear segments forced to lines');
$grfx->bspline(\@pts, -debug=>$db, -colinear=>'line', -firstseg=>'line2', -lastseg=>'line1');
$grfx->stroke();

$pdf->saveas($PDFname);
# ---------------------------------------
# move to first set of points, copy remainder into @pts
sub _movedraw {
    my ($hoffset, $voffset, $label, $explain) = @_;
    if (!defined $explain) { $explain = ''; }
   #print "$label\n";
    $grfx->move($points[0]+$hoffset, $points[1]+$voffset +2);
    
    @pts = ();
    for ($i=2; $i<scalar @points; $i+=2) {
	$pts[$i-2] = $points[$i] + $hoffset;
	$pts[$i-1] = $points[$i+1] + $voffset +2;
    }

    $text->font($font, 10);
    $text->translate($hoffset, $voffset);
    $text->text($label);

    # explain fitted in a column
    $text->font($font, 5);
    my $line_count = 0;
    my $w;
    while ($explain ne '') {
	$text->translate($hoffset+15, $voffset+3-6*$line_count++);
	($w, $explain) = $text->text_fill_left($explain, 15*5);
    }
    return;
}
# ---------------------------------------
sub nextPage {
  $pageNo++;
  $page = $pdf->page();
  $grfx = $page->gfx();
  $text = $page->text();
  $page->mediabox('Universal');
  $font = $pdf->corefont('Times-Roman');
  $text->translate(595/2,15);
  $text->font($font, 10);
  $text->fillcolor('black');
  $text->text_center("-$pageNo-"); # prefill page number before any other content
  return;
}

