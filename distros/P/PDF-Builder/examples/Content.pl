# exercise Content.pm as much as possible
# outputs Content.pdf
# author: Phil M Perry

use warnings;
use strict;

our $VERSION = '3.007'; # VERSION
my $LAST_UPDATE = '3.003'; # manually update whenever code is changed

use Math::Trig;
use List::Util qw(min max);

#use constant in => 1 / 72;
#use constant cm => 2.54 / 72; 
#use constant mm => 25.4 / 72;
#use constant pt => 1;

use PDF::Builder;

my $PDFname = 'Content.pdf';
my $globalX = 0; 
my $globalY = 0;
my $compress = 'none';
#my $compress = 'flate';

my $pdf = PDF::Builder->new(-compress => $compress);
my ($page, $grfx, $text); # objects for page, graphics, text
my (@base, @styles, @points, $i, $lw, $angle, @npts);
my (@cellLoc, @cellSize, $font, $width, $d1, $d2, $d3, $d4);
my @axisOffset = (5, 5); # clear the edge of the cell

my $pageNo = 0;
nextPage();
# next (first) page of output, 523pt wide x 720pt high

my $fontR = $pdf->corefont('Times-Roman');
my $fontI = $pdf->corefont('Times-Italic');
my $fontC = $pdf->corefont('Courier');

# ============ demonstrate graphics ===========================================
# ----------------------------------------------------
# 1. translate 0,0 to 36,36 and draw old and new axes
@cellLoc = makeCellLoc(0, 0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;

# old axes at "0,0"
colors('black');
$grfx->transform(-translate => \@base);
$text->transform(-translate => \@base);
drawAxes();  
drawLabels('oldX', 'oldY');
$grfx->restore();

$grfx->save();
# new axes at "36,36"
colors('red');
$base[0] += 36;
$base[1] += 36;
$grfx->transform(-translate => \@base);
$text->transform(-translate => \@base);
drawAxes();
drawLabels('newX', 'newY');

# caption
drawCaption(['translate(36, 36)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 2. rotate new axes 30 degrees from old
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
# the translate is just to give clearance for rotated axes
$base[0] += 50;
$base[1] += 15;

# old axes at "0,0"
colors('black');
$grfx->transform(-translate => \@base);
$text->transform(-translate => \@base);
drawAxes();  
drawLabels('oldX', 'oldY');
$grfx->restore();

$grfx->save();
# new axes rotated 30
colors('red');
# axes are drawn at @axisOffset, so need to correct for that so origins coincide
# alpha must be less than 90 degrees
$base[0] += 2.627; # AOy(sin(alpha) + sin(alpha+90) - 1)
$base[1] -= 1.740; # AOx(cos(alpha) + cos(alpha+90) - 1)
$grfx->transform(-translate => \@base,
                 -rotate    => 30);
$text->transform(-translate => \@base,
                 -rotate    => 30);
drawAxes();  
drawLabels('newX', 'newY');

# caption
drawCaption(['rotate(30)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 3. scale axes X 1.2x, Y 0.5x
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
# the translate is just to give clearance for scaled axes
$base[0] +=  5;
$base[1] += 15;

# old axes at "0,0"
colors('black');
$grfx->transform(-translate => \@base);
$text->transform(-translate => \@base);
drawAxes();  
drawLabels('oldX', 'oldY');
$grfx->restore();

$grfx->save();
# new axes scaled 1.2x .5x
colors('red');
# axes are drawn at @axisOffset, so need to correct for that so origins coincide
# when scaled in both directions
$base[0] -=  1.0;
$base[1] +=  2.5;
$grfx->transform(-translate => \@base,
                 -scale     => [1.2, 0.5]);
$text->transform(-translate => \@base,
                 -scale     => [1.2, 0.5]);
drawAxes();  
drawLabels('newX', 'newY');

# caption
drawCaption(['scale(1.2, .5)']);

$grfx->restore();

# ----------------------------------------------------
# 4. skew axes X 10 degrees, Y 15 degrees
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
# the translate is just to give clearance for skewed axes
$base[0] +=  5;
$base[1] += 15;

# old axes at "0,0"
colors('black');
$grfx->transform(-translate => \@base);
$text->transform(-translate => \@base);
drawAxes();  
drawLabels('oldX', 'oldY');  
$grfx->restore();

$grfx->save();
# new axes skewed 10 deg (CCW from X), 15 deg (CW from Y)
colors('red');
# axes are drawn at @axisOffset, so need to correct for that so origins coincide
# when skewed in both directions
$base[0] -=  1.0;
$base[1] -=  1.0;
$grfx->transform(-translate => \@base,
                 -skew      => [10, 15]);
$text->transform(-translate => \@base,
                 -skew      => [10, 15]);
drawAxes();
drawLabels('newX', 'newY');

# caption
drawCaption(['skew(10, 15)']);

$grfx->restore();

# ----------------------------------------------------
# 5. rotate then translate
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
# the translate is just to give clearance for rotated axes
$base[0] += 20;
$base[1] +=  0;

# old axes at "0,0"
colors('black');
$grfx->transform(-translate => \@base);
$text->transform(-translate => \@base);
drawAxes();  
drawLabels('oldX', 'oldY');  
$grfx->restore();

$grfx->save();
# new axes translate(50,15) then rotate(30)
colors('red');
$base[0] += 50;
$base[1] += 15;
$grfx->transform(-translate => \@base,
                 -rotate    => 30);
$text->transform(-translate => \@base,
                 -rotate    => 30);
drawAxes();
drawLabels('newX', 'newY');

# caption
drawCaption(['translate(50, 15)', 'rotate(30)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 6. rotate then translate
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
# the translate is just to give clearance for rotated axes
$base[0] += 20;
$base[1] +=  0;

# old axes at "0,0"
colors('black');
$grfx->transform(-translate => \@base);
$text->transform(-translate => \@base);
drawAxes();  
drawLabels('oldX', 'oldY');  
$grfx->restore();

$grfx->save();
# new axes rotate(30) then translate(50,15)
# actually, this simulates what would happen if you rotated about the
# old origin and then translated, remembering that we start with 0,0 
# origin at the lower left corner of the page, rather than the old axes.
# we have to use the transform() call, which fixes the order in which
# operations are done.
# alpha = 30, beta = atan2(15, 50), len = sqrt(15^2 + 50^2)
# addl x = len*cos(alpha+beta), addl y = len*sin(alpha+beta)
colors('red');
$base[0] += 35.80;
$base[1] += 37.99;
$grfx->transform(-translate => \@base,
                 -rotate    => 30);
$text->transform(-translate => \@base,
                 -rotate    => 30);
drawAxes();
drawLabels('newX', 'newY');

# caption
drawCaption(['rotate(30)', 'translate(50, 15)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 7. various linewidths
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->translate(@base);
$grfx->strokecolor('black');
foreach my $w (1, 2, 4, 8, 16) {
  $text->translate($base[0]+$w*8, $base[1]);
  $text->text_center($w);
  $grfx->linewidth($w);
  $grfx->poly($w*8,10, $w*8+10,110);
  $grfx->stroke();
}

# caption
drawCaption(['linewidth()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 8. various linecaps
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

@styles = ('butt', 'round', 'projecting square');
$grfx->translate(@base);
$grfx->strokecolor('black');
foreach my $cap (0, 1, 2) {
  $text->font($fontC, 12);
  $text->translate($base[0]+8, $base[1]+17+35*$cap);
  $text->text_center($cap);

  $text->font($fontI, 8);
  $text->translate($base[0]+83, $base[1]+17+35*$cap-13);
  $text->text_center($styles[$cap]);

  $grfx->linecap($cap);
  $grfx->strokecolor('red');
  $grfx->linewidth(20);
  $grfx->poly(37,20+35*$cap, 128,20+35*$cap);
  $grfx->stroke();

  $grfx->linecap(0);
  $grfx->strokecolor('black');
  $grfx->poly(37,20+35*$cap, 128,20+35*$cap);
  $grfx->stroke();

  greenLine([37,20+35*$cap, 128,20+35*$cap]);

}

# caption
drawCaption(['linecap()'], 'LC');

$grfx->restore();

if (1 == 1) {  # needs more research... shows no visible difference
# ----------------------------------------------------
# 9. flatness
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->translate(@base);
$grfx->strokecolor('black');
$grfx->linewidth(1);

$grfx->flatness(1);
#$grfx->circle(73,55, 30);
@points = (40,75, 100,90, 130,60); # EP1=20,20, CP1, CP2, EP2
$grfx->linedash();
$grfx->move(20, 20);
$grfx->curve(@points);
$grfx->stroke();

$grfx->flatness(5);
#$grfx->circle(73,55, 33);
@points = (40,80, 100,95, 130,65); # EP1=20,20, CP1, CP2, EP2
$grfx->linedash();
$grfx->move(20, 25);
$grfx->curve(@points);
$grfx->stroke();

$text->translate($base[0]+100,$base[1]+60);
$text->text_center('1.0');
$text->translate($base[0]+115,$base[1]+85);
$text->text_center('5.0');

# caption
drawCaption(['flatness()'], 'LC');

$grfx->restore();
}

# ----------------------------------------------------
# 10. miter linejoin
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();
$lw = 20;

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->translate(@base);
@points = (135,25, 35,25, 135,95);
$grfx->linecap(0);
$grfx->linejoin(0);

$grfx->strokecolor('red');
$grfx->linewidth($lw);
$grfx->poly(@points);
$grfx->stroke();

$grfx->strokecolor('black');
for ($i=0; $i<@points; $i+=2) {
  $grfx->poly($points[$i],$points[$i+1], $points[$i+2],$points[$i+3]);
  $grfx->stroke();
}

# gray overlap
$grfx->fillcolor('#333333');
$angle = atan2($points[5]-$points[3], $points[4]-$points[2]);
@npts = ($points[2], $points[3], $points[2], $points[3]+$lw/2,
         $points[2]+$lw/2*(1/tan($angle)+1/sin($angle)),$points[3]+$lw/2,
	 $points[2]+$lw/2*sin($angle),$points[3]-$lw/2*cos($angle));
$grfx->poly(@npts);
$grfx->close();
$grfx->fill();
greenLine(\@points);

# caption
drawCaption(['linejoin(0)  (miter)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 11. round linejoin
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();
$lw = 20;

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->translate(@base);
@points = (135,25, 35,25, 135,95);
$grfx->linecap(0);
$grfx->linejoin(1);

$grfx->strokecolor('red');
$grfx->linewidth($lw);
$grfx->poly(@points);
$grfx->stroke();

$grfx->strokecolor('black');
for ($i=0; $i<@points; $i+=2) {
  $grfx->poly($points[$i],$points[$i+1], $points[$i+2],$points[$i+3]);
  $grfx->stroke();
}

# gray overlap
$grfx->fillcolor('#333333');
$angle = atan2($points[5]-$points[3], $points[4]-$points[2]);
@npts = ($points[2], $points[3], $points[2], $points[3]+$lw/2,
         $points[2]+$lw/2*(1/tan($angle)+1/sin($angle)),$points[3]+$lw/2,
	 $points[2]+$lw/2*sin($angle),$points[3]-$lw/2*cos($angle));
$grfx->poly(@npts);
$grfx->close();
$grfx->fill();
greenLine(\@points);

# caption
drawCaption(['linejoin(1)  (round)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 12. bevel linejoin
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();
$lw = 20;

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->translate(@base);
@points = (135,25, 35,25, 135,95);
$grfx->linecap(0);
$grfx->linejoin(2);

$grfx->strokecolor('red');
$grfx->linewidth($lw);
$grfx->poly(@points);
$grfx->stroke();

$grfx->strokecolor('black');
for ($i=0; $i<@points; $i+=2) {
  $grfx->poly($points[$i],$points[$i+1], $points[$i+2],$points[$i+3]);
  $grfx->stroke();
}

# gray overlap
$grfx->fillcolor('#333333');
$angle = atan2($points[5]-$points[3], $points[4]-$points[2]);
@npts = ($points[2], $points[3], $points[2], $points[3]+$lw/2,
         $points[2]+$lw/2*(1/tan($angle)+1/sin($angle)),$points[3]+$lw/2,
	 $points[2]+$lw/2*sin($angle),$points[3]-$lw/2*cos($angle));
$grfx->poly(@npts);
$grfx->close();
$grfx->fill();
greenLine(\@points);

# caption
drawCaption(['linejoin(2)  (bevel)'], 'LC');

$grfx->restore();

# new miter limit (4) should be in effect from here on out
# HOWEVER, a nextPage() call (within makeCellLoc()) creates a new $grfx, 
# so it's not carried over to the next cell! repeat at each miter limit
# example, after makeCellLoc(), to be sure it's there.
#$grfx->miterlimit(4);   # default is 10 (11.5 degree miter)

# ----------------------------------------------------
# 13. linejoin(0) (miter) at 135 deg at miterlimit 4
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();
$grfx->miterlimit(4);   # default is 10 (11.5 degree miter)

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->translate(@base);
@points = (135,25, 55,25, 15,95);
$grfx->linecap(0);
$grfx->linejoin(0);

$grfx->strokecolor('red');
$grfx->linewidth($lw);
$grfx->poly(@points);
$grfx->stroke();

$grfx->strokecolor('black');
for ($i=0; $i<@points; $i+=2) {
  $grfx->poly($points[$i],$points[$i+1], $points[$i+2],$points[$i+3]);
  $grfx->stroke();
}

# gray overlap
$grfx->fillcolor('#333333');
$angle = atan2($points[5]-$points[3], $points[4]-$points[2]);
@npts = ($points[2], $points[3], $points[2], $points[3]+$lw/2,
         $points[2]+$lw/2*(1/tan($angle)+1/sin($angle)),$points[3]+$lw/2,
	 $points[2]+$lw/2*sin($angle),$points[3]-$lw/2*cos($angle));
$grfx->poly(@npts);
$grfx->close();
$grfx->fill();
greenLine(\@points);

# caption
drawCaption(['mitered join 135 deg'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 14. linejoin(0) (miter) at 90 deg at miterlimit 4
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();
$grfx->miterlimit(4);   # default is 10 (11.5 degree miter)

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->translate(@base);
@points = (135,25, 55,25, 55,95);
$grfx->linecap(0);
$grfx->linejoin(0);

$grfx->strokecolor('red');
$grfx->linewidth($lw);
$grfx->poly(@points);
$grfx->stroke();

$grfx->strokecolor('black');
for ($i=0; $i<@points; $i+=2) {
  $grfx->poly($points[$i],$points[$i+1], $points[$i+2],$points[$i+3]);
  $grfx->stroke();
}

# gray overlap
$grfx->fillcolor('#333333');
$angle = atan2($points[5]-$points[3], $points[4]-$points[2]);
@npts = ($points[2], $points[3], $points[2], $points[3]+$lw/2,
         $points[2]+$lw/2*(1/tan($angle)+1/sin($angle)),$points[3]+$lw/2,
	 $points[2]+$lw/2*sin($angle),$points[3]-$lw/2*cos($angle));
$grfx->poly(@npts);
$grfx->close();
$grfx->fill();
greenLine(\@points);

# caption
drawCaption(['mitered join 90 deg'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 15. linejoin(0) (miter) at 45 deg at miterlimit 4
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();
$grfx->miterlimit(4);   # default is 10 (11.5 degree miter)

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->translate(@base);
@points = (135,25, 55,25, 135,105);
$grfx->linecap(0);
$grfx->linejoin(0);

$grfx->strokecolor('red');
$grfx->linewidth($lw);
$grfx->poly(@points);
$grfx->stroke();

$grfx->strokecolor('black');
for ($i=0; $i<@points; $i+=2) {
  $grfx->poly($points[$i],$points[$i+1], $points[$i+2],$points[$i+3]);
  $grfx->stroke();
}

# gray overlap
$grfx->fillcolor('#333333');
$angle = atan2($points[5]-$points[3], $points[4]-$points[2]);
@npts = ($points[2], $points[3], $points[2], $points[3]+$lw/2,
         $points[2]+$lw/2*(1/tan($angle)+1/sin($angle)),$points[3]+$lw/2,
	 $points[2]+$lw/2*sin($angle),$points[3]-$lw/2*cos($angle));
$grfx->poly(@npts);
$grfx->close();
$grfx->fill();
greenLine(\@points);

# caption
drawCaption(['mitered join 45 deg'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 16. linejoin(0) (miter) at 30 deg at miterlimit 4
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();
$grfx->miterlimit(4);   # default is 10 (11.5 degree miter)

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->translate(@base);
@points = (135,25, 55,25, 135,71.2);
$grfx->linecap(0);
$grfx->linejoin(0);

$grfx->strokecolor('red');
$grfx->linewidth($lw);
$grfx->poly(@points);
$grfx->stroke();

$grfx->strokecolor('black');
for ($i=0; $i<@points; $i+=2) {
  $grfx->poly($points[$i],$points[$i+1], $points[$i+2],$points[$i+3]);
  $grfx->stroke();
}

# gray overlap
$grfx->fillcolor('#333333');
$angle = atan2($points[5]-$points[3], $points[4]-$points[2]);
@npts = ($points[2], $points[3], $points[2], $points[3]+$lw/2,
         $points[2]+$lw/2*(1/tan($angle)+1/sin($angle)),$points[3]+$lw/2,
	 $points[2]+$lw/2*sin($angle),$points[3]-$lw/2*cos($angle));
$grfx->poly(@npts);
$grfx->close();
$grfx->fill();
greenLine(\@points);

# caption
drawCaption(['mitered join 30 deg'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 17. linejoin(0) (miter) at 20 deg at miterlimit 4
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();
$grfx->miterlimit(4);   # default is 10 (11.5 degree miter)

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->translate(@base);
@points = (135,25, 55,25, 135,54.1);
$grfx->linecap(0);
$grfx->linejoin(0);

$grfx->strokecolor('red');
$grfx->linewidth($lw);
$grfx->poly(@points);
$grfx->stroke();

$grfx->strokecolor('black');
for ($i=0; $i<@points; $i+=2) {
  $grfx->poly($points[$i],$points[$i+1], $points[$i+2],$points[$i+3]);
  $grfx->stroke();
}

# gray overlap
$grfx->fillcolor('#333333');
$angle = atan2($points[5]-$points[3], $points[4]-$points[2]);
@npts = ($points[2], $points[3], $points[2], $points[3]+$lw/2,
         $points[2]+$lw/2*(1/tan($angle)+1/sin($angle)),$points[3]+$lw/2,
	 $points[2]+$lw/2*sin($angle),$points[3]-$lw/2*cos($angle));
$grfx->poly(@npts);
$grfx->close();
$grfx->fill();
greenLine(\@points);

# caption
drawCaption(['mitered join 20 deg'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 18. linejoin(0) (miter) at 15 deg at miterlimit 4
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();
$grfx->miterlimit(4);   # default is 10 (11.5 degree miter)

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->translate(@base);
@points = (135,25, 55,25, 135,46.4);
$grfx->linecap(0);
$grfx->linejoin(0);

$grfx->strokecolor('red');
$grfx->linewidth($lw);
$grfx->poly(@points);
$grfx->stroke();

$grfx->strokecolor('black');
for ($i=0; $i<@points; $i+=2) {
  $grfx->poly($points[$i],$points[$i+1], $points[$i+2],$points[$i+3]);
  $grfx->stroke();
}

# gray overlap
$grfx->fillcolor('#333333');
$angle = atan2($points[5]-$points[3], $points[4]-$points[2]);
@npts = ($points[2], $points[3], $points[2], $points[3]+$lw/2,
         $points[2]+$lw/2*(1/tan($angle)+1/sin($angle)),$points[3]+$lw/2,
	 $points[2]+$lw/2*sin($angle),$points[3]-$lw/2*cos($angle));
$grfx->poly(@npts);
$grfx->close();
$grfx->fill();
greenLine(\@points);

# caption
drawCaption(['mitered join 15 deg'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 19. linedash() three examples
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

@styles = ('linedash()', 'linedash(10)', 'linedash(15, 10)', 'linedash(-pattern=>[15,8, 2,5], -shift=>8)');
$grfx->translate(@base);
$grfx->strokecolor('black');
$grfx->linewidth(2);
foreach my $pat (0, 1, 2, 3) {
  $text->font($fontI, 8);
  $text->translate($base[0]+73, $base[1]+17+25*$pat-8);
  $text->text_center($styles[$pat]);

  if      ($pat == 0) {
    $grfx->linedash();
  } elsif ($pat == 1) {
    $grfx->linedash(10);
  } elsif ($pat == 2) {
    $grfx->linedash(15, 10);
  } else {
    $grfx->linedash(-pattern=>[15,8, 2,5], -shift=>8);
  }
  $grfx->poly(20,20+25*$pat, 130,20+25*$pat);
  $grfx->stroke();

}

# caption
drawCaption(['linedash()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# egstate(): not shown
# ----------------------------------------------------
# move(): shown as part of other examples
# ----------------------------------------------------
# close(): shown as part of other examples
# ----------------------------------------------------
# endpath(): would be shown as part of other examples

# ----------------------------------------------------
# 20. hline(), line(), vline(), poly()
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 20;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);

# move, hline, diagonal line, vline
  $grfx->save();
  $text->translate($base[0]+10, $base[1]+90);
  $text->text('hline, line, vline');

  $grfx->translate(@base);
  $grfx->move(10, 25);
  $grfx->hline(30);
  $grfx->line(60, 60);
  $grfx->vline(80);
  $grfx->stroke();
  $grfx->restore();

# poly
  $grfx->save();
  $text->translate($base[0]+130, $base[1]+0);
  $text->text_right('poly');

  $grfx->translate($base[0]+70, $base[1]-10);
  $grfx->poly(10,25, 30,25, 60,60, 60,80);
  $grfx->stroke();
  $grfx->restore();

# caption
drawCaption(['hline, line, vline, or poly'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 21. rect()
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 20;

$grfx->strokecolor('black');
$grfx->linewidth(1);
$text->font($fontC, 8);

# single rectangle (x,y w,h)
  $grfx->save();
  $text->translate($base[0]+30, $base[1]+95);
  $text->text_center('single rect');

  $grfx->translate(@base);
  $grfx->rect(10,70, 30,15);
  $grfx->stroke();
  greenLine([10,70]);
  $grfx->restore();

# multiple rectangles (x,y w,h) with common corner
  $grfx->save();
  $text->translate($base[0]+100, $base[1]-5);
  $text->text_center('multiple rects');

  $grfx->translate($base[0]+90,$base[1]-35);
  # all 10,70 corner. UR + +, LR + -, LL - -, UL - +
  $grfx->rect(10,70, 30,15, 10,70, 40,-20, 10,70, -35,-25, 10,70, -45,25);
  $grfx->stroke();
  greenLine([10,70]);
  $grfx->restore();

# caption
drawCaption(['rect()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 22. rectxy() two examples
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(1);
$text->font($fontC, 8);

# LL - UR corners
  $grfx->save();
  $text->translate($base[0]+10, $base[1]+90);
  $text->text('LL - UR corners');

  $grfx->translate(@base);
  $grfx->rectxy(10,70, 40,80);
  $grfx->stroke();
  greenLine([10, 70]);
  $grfx->restore();

# LR - UL corners
  $grfx->save();
  $text->translate($base[0]+130, $base[1]+0);
  $text->text_right('LR - UL corners');

  $grfx->translate($base[0]+70, $base[1]-10);
  $grfx->rectxy(35,25, 10,50);
  $grfx->stroke();
  greenLine([35,25]);
  $grfx->restore();

# caption
drawCaption(['rectxy()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 23. circle()
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

# radius 20, 40, 60 at 75, 55       
for (my $r = 20; $r < 80; $r += 20) {
  $grfx->save();

  $grfx->circle(75, 55, $r);
  $grfx->stroke();
  $grfx->restore();
}

# caption
drawCaption(['circle()  3 radii'], 'LC');
$text->translate($cellLoc[0]+$cellSize[0]/2, $cellLoc[1]-20);
$text->font($fontC, 12);
$text->fillcolor('black');
$text->text_center('circle()  3 radii');

$grfx->restore();

# ----------------------------------------------------
# 24. ellipse()
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

# semidiameters 10, 20 at 75, 55       
  $grfx->save();
  $grfx->ellipse(75,55, 10,20);
  $grfx->stroke();
  $grfx->restore();

# semidiameters 40, 30 at 75, 55       
  $grfx->save();
  $grfx->ellipse(75,55, 40,30);
  $grfx->stroke();
  $grfx->restore();

# semidiameters 50, 60 at 75, 55       
  $grfx->save();
  $grfx->ellipse(75,55, 50,60);
  $grfx->stroke();
  $grfx->restore();

# caption
drawCaption(['ellipse()  3 radius sets'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 25. arc()
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

# CCW 90 degrees, semidiameters 10, 20 at 75, 55       
  $grfx->save();
  $grfx->arc(75,55, 10,20, 90,180, 1);
  $grfx->stroke();
  $grfx->restore();

# CCW 180 degrees, semidiameters 40, 30 at 75, 55 
  $grfx->save();
  $grfx->arc(75,55, 40,30, 235,45, 1);
  $grfx->stroke();
  $grfx->restore();

# CW 315 degrees, diameter 60 at 75, 55       
  $grfx->save();
  $grfx->arc(75,55, 60,60, 310,355, 1, 1);
  $grfx->stroke();
  $grfx->restore();

# caption
drawCaption(['arc()  3 radius sets'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 26. pie()  a.k.a. Pac-man eating a slice of pie
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

# semidiameters 40,30  50 degree slice missing centered at 0 degrees
  $grfx->save();
# $grfx->pie(75,55, 40,30, 45,360);
  $grfx->pie(75,55, 40,30, 25,335);
  $grfx->stroke();
  $grfx->restore();

# removed slice offset to right
  $grfx->save();
  $grfx->pie(95,55, 40,30, 25,335, 1);  # draw CW this time
  $grfx->stroke();
  $grfx->restore();

# caption
drawCaption(['pie()  one slice removed'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 27. curve()  (cubic Bezier curve)
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

@points = (40,75, 100,90, 130,60); # EP1=20,20, CP1, CP2, EP2
$grfx->linedash();
$grfx->move(20, 20);
$grfx->curve(@points);
$grfx->stroke();
$grfx->linedash(4);
greenLine([20, 20, @points]);
$grfx->strokecolor('black');

# caption
drawCaption(['curve()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 28. spline()  (cubic Bezier curve with synthesized control points)
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

@points = (40,75, 130,60); # EP1=20,20, CP1, EP2
$grfx->linedash();
$grfx->move(20, 20);
$grfx->spline(@points);
$grfx->stroke();
$grfx->linedash(4);
greenLine([20, 20, @points]);
$grfx->strokecolor('black');

# caption
drawCaption(['spline()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 29. bogen()  (circular arc segment) 1/4  smaller arc, non-flipped
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

# two intersecting circles in gray
$grfx->save();
$grfx->strokecolor('#999999');
$grfx->circle(50,45, 40);
$grfx->circle(90,70, 40);
$grfx->stroke();
$grfx->restore();

# bogen (arc) smaller arc, clockwise (not flipped)
# endpoints are manually calculated
$grfx->bogen(53,85, 87,30, 40, 1, 0, 0);
#$grfx->hline(160);    # show end point of bogen
$grfx->stroke();
$text->translate($base[0]+49, $base[1]+90);
$text->text_right('P1');
$text->translate($base[0]+92, $base[1]+19);
$text->text('P2');
greenLine([53, 85]);
greenLine([87, 30]);

# caption
drawCaption(['bogen() sm arc no-flip'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 29A. bogen()  (circular arc segment) 1/4  smaller arc, non-flipped
# with start and end connecting lines
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

# two intersecting circles in gray
$grfx->save();
$grfx->strokecolor('#999999');
$grfx->circle(50,45, 40);
$grfx->circle(90,70, 40);
$grfx->stroke();
$grfx->restore();

# bogen (arc) smaller arc, clockwise (not flipped)
# endpoints are manually calculated
$grfx->move(0,0);     # will connect to existing point
$grfx->bogen(53,85, 87,30, 40, 0, 0, 0);
$grfx->hline(150);    # show end point of bogen
$grfx->stroke();
$text->translate($base[0]+49, $base[1]+90);
$text->text_right('P1');
$text->translate($base[0]+92, $base[1]+19);
$text->text('P2');
greenLine([53, 85]);
greenLine([87, 30]);

# caption
drawCaption(['bogen move=F, end line'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 30. bogen()  (circular arc segment) 2/4  larger arc, non-flipped
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

# two intersecting circles in gray
$grfx->save();
$grfx->strokecolor('#999999');
$grfx->circle(50,45, 40);
$grfx->circle(90,70, 40);
$grfx->stroke();
$grfx->restore();

# bogen (arc) larger arc, clockwise (not flipped)
# endpoints are manually calculated
$grfx->bogen(53,85, 87,30, 40, 1, 1, 0);
#$grfx->hline(160);    # show end point of bogen
$grfx->stroke();
$text->translate($base[0]+49, $base[1]+90);
$text->text_right('P1');
$text->translate($base[0]+92, $base[1]+19);
$text->text('P2');
greenLine([53, 85]);
greenLine([87, 30]);

# caption
drawCaption(['bogen() lg arc no-flip'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 31. bogen()  (circular arc segment) 3/4  smaller arc, flipped (mirrored)
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

# two intersecting circles in gray
$grfx->save();
$grfx->strokecolor('#999999');
$grfx->circle(50,45, 40);
$grfx->circle(90,70, 40);
$grfx->stroke();
$grfx->restore();

# bogen (arc) smaller arc, counter-clockwise (flipped)
# endpoints are manually calculated
$grfx->bogen(53,85, 87,30, 40, 1, 0, 1);
#$grfx->hline(160);    # show end point of bogen
$grfx->stroke();
$text->translate($base[0]+49, $base[1]+90);
$text->text_right('P1');
$text->translate($base[0]+92, $base[1]+19);
$text->text('P2');
greenLine([53, 85]);
greenLine([87, 30]);


# caption
drawCaption(['bogen() sm arc flip'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 32. bogen()  (circular arc segment) 4/4  larger arc, flipped (mirrored)
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
$base[0] += 10;
$base[1] += 10;

$grfx->strokecolor('black');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

# two intersecting circles in gray
$grfx->save();
$grfx->strokecolor('#999999');
$grfx->circle(50,45, 40);
$grfx->circle(90,70, 40);
$grfx->stroke();
$grfx->restore();

# bogen (arc) larger arc, counter-clockwise (flipped)
# endpoints are manually calculated
$grfx->bogen(53,85, 87,30, 40, 1, 1, 1);
#$grfx->hline(160);    # show end point of bogen
$grfx->stroke();
$text->translate($base[0]+49, $base[1]+90);
$text->text_right('P1');
$text->translate($base[0]+92, $base[1]+19);
$text->text('P2');
greenLine([53, 85]);
greenLine([87, 30]);


# caption
drawCaption(['bogen() lg arc flip'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# stroke(): shown as part of other examples
# ----------------------------------------------------

# ----------------------------------------------------
# 33. fill(): 5 pt star with both rules
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$width=80;
$d1= $width*cos(36/180*3.141593);
$d2= $width*sin(36/180*3.141593);
$d3= $width*cos(18/180*3.141593);
$d4= $width*sin(18/180*3.141593);

$grfx->strokecolor('black');
$grfx->fillcolor('#999');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

# fill() (non-zero winding)
$grfx->save();

@points = (25,50, $d1,$d2, -$width,0, $d1,-$d2, -$d4,$d3);
# convert relative coordinates to absolute
for ($i=2; $i<@points; $i+=2) {
  $points[$i]   += $points[$i-2];
  $points[$i+1] += $points[$i-1];
}
$grfx->poly(@points);
$grfx->close();
$grfx->fill();

$grfx->restore();

# fill() (even-odd)
$grfx->save();

@points = (95,20, $d1,$d2, -$width,0, $d1,-$d2, -$d4,$d3);
# convert relative coordinates to absolute
for ($i=2; $i<@points; $i+=2) {
  $points[$i]   += $points[$i-2];
  $points[$i+1] += $points[$i-1];
}
$grfx->poly(@points);
$grfx->close();
$grfx->fill(1);

$grfx->restore();

# caption
drawCaption(['fill() with non-zero', 'winding and even-odd'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 34. fillstroke(): 5 pt star with both rules
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$width=80;
$d1= $width*cos(36/180*3.141593);
$d2= $width*sin(36/180*3.141593);
$d3= $width*cos(18/180*3.141593);
$d4= $width*sin(18/180*3.141593);

$grfx->strokecolor('black');
$grfx->fillcolor('#999');
$grfx->linewidth(2);
$text->font($fontC, 8);
$grfx->translate(@base);

# fill() (non-zero winding)
$grfx->save();

@points = (25,50, $d1,$d2, -$width,0, $d1,-$d2, -$d4,$d3);
# convert relative coordinates to absolute
for ($i=2; $i<@points; $i+=2) {
  $points[$i]   += $points[$i-2];
  $points[$i+1] += $points[$i-1];
}
$grfx->poly(@points);
$grfx->close();
$grfx->fillstroke();

$grfx->restore();

# fill() (even-odd)
$grfx->save();

@points = (95,20, $d1,$d2, -$width,0, $d1,-$d2, -$d4,$d3);
# convert relative coordinates to absolute
for ($i=2; $i<@points; $i+=2) {
  $points[$i]   += $points[$i-2];
  $points[$i+1] += $points[$i-1];
}
$grfx->poly(@points);
$grfx->close();
$grfx->fillstroke(1);

$grfx->restore();

# caption
drawCaption(['fillstroke() w/ non-zero', 'winding and even-odd'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 37. clip(): filled circle with box cut out
@cellLoc = makeCellLoc(1);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$width=80;

$grfx->strokecolor('black');
$grfx->fillcolor('#999');
$grfx->linewidth(1);
$text->font($fontC, 16);
$grfx->translate(@base);

# clip port dashed square, solid circle
$grfx->save();

$grfx->linedash(3);
$grfx->rect(40,55, 40,45);
$grfx->stroke();
$grfx->linewidth(2);
$grfx->linedash();
$grfx->circle(45,90, 30);
$grfx->stroke();
#$text->translate($base[0]+45, $base[1]+90);
#$text->text_center("Hello");

$grfx->restore();

# actual clip port, filled and stroked circle
$grfx->save();

$grfx->rect(120,10, 40,45);
$grfx->clip();
$grfx->endpath();  # necessary for separating the clip and paint
$grfx->circle(125,45, 30);
$grfx->fillstroke();
#$text->translate($base[0]+125, $base[1]+45); # "He" not clipped
#$text->text_center("Hello");

$grfx->restore();

# caption
drawCaption(['clip()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 38. clip(): show that clip-on-clip only reduces clipping area
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$width=80;

$grfx->strokecolor('black');
$grfx->fillcolor('#999');
$grfx->linewidth(1);
$text->font($fontC, 16);
$grfx->translate(@base);

# clip port dashed square, solid circle
$grfx->save();

$grfx->linedash(3);
$grfx->rect(40,55, 40,45);
$grfx->rect(60,80, 25,25);
$grfx->stroke();
$grfx->linewidth(2);
$grfx->linedash();
$grfx->circle(45,90, 30);
$grfx->stroke();
#$text->translate($base[0]+45, $base[1]+90);
#$text->text_center("Hello");

$grfx->restore();

# actual clip port, filled and stroked circle
$grfx->save();

$grfx->rect(120,10, 40,45);
$grfx->clip();
$grfx->endpath();  # necessary for separating the clip and paint
$grfx->rect(140,35, 25,25);
$grfx->clip();
$grfx->endpath();  # necessary for separating the clip and paint
$grfx->circle(125,45, 30);
$grfx->fillstroke();
#$text->translate($base[0]+125, $base[1]+45); # "He" not clipped
#$text->text_center("Hello");

$grfx->restore();

# caption
drawCaption(['clip()  twice'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 39. clip(): show clip with two clipping areas (union)
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$width=80;

$grfx->strokecolor('black');
$grfx->fillcolor('#999');
$grfx->linewidth(1);
$text->font($fontC, 16);
$grfx->translate(@base);

# clip port dashed square, solid circle
$grfx->save();

$grfx->linedash(3);
$grfx->rect(40,55, 40,45);
$grfx->rect(60,80, 25,25);
$grfx->stroke();
$grfx->linewidth(2);
$grfx->linedash();
$grfx->circle(45,90, 30);
$grfx->stroke();
#$text->translate($base[0]+45, $base[1]+90);
#$text->text_center("Hello");

$grfx->restore();

# actual clip port, filled and stroked circle
$grfx->save();

$grfx->rect(120,10, 40,45);
$grfx->rect(140,35, 25,25);
$grfx->clip();
$grfx->endpath();  # necessary for separating the clip and paint
$grfx->circle(125,45, 30);
$grfx->fillstroke();
#$text->translate($base[0]+125, $base[1]+45); # "He" not clipped
#$text->text_center("Hello");

$grfx->restore();

# caption
drawCaption(['clip()  once, two areas'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# fillcolor(): shown as part of other examples
# ----------------------------------------------------
# strokecolor(): shown as part of other examples
# ----------------------------------------------------
# shade(): omit for now
# ----------------------------------------------------
# fillcolor(): shown as part of other examples
# ----------------------------------------------------
# strokecolor(): shown as part of other examples
# ----------------------------------------------------

# ----------------------------------------------------
# 40. image(): display an image, 640x480 scaled to 160x120
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$width=80;

$grfx->strokecolor('black');
$grfx->fillcolor('#999');
$grfx->linewidth(2);
$text->font($fontC, 16);
$grfx->translate(@base);

my $img_obj = $pdf->image_jpeg('examples\resources\aptfrontview.jpg');
$grfx->image($img_obj, 5,5, 160,120);

# caption
drawCaption(['image()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 41. formimage(): display an image, 640x480 scaled to 160x120 (25%)
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$width=80;

$grfx->strokecolor('black');
$grfx->fillcolor('#999');
$grfx->linewidth(2);
$text->font($fontC, 16);
$grfx->translate(@base);

$img_obj = $pdf->image_jpeg('examples\resources\aptfrontview.jpg');
$grfx->formimage($img_obj, 5,5, 0.25*$img_obj->width(),0.25*$img_obj->height());

# caption
drawCaption(['formimage() 25%'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 42. formimage(): display an image, 640x480 scaled to 80x120 (12.5 x 25%)
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$width=80;

$grfx->strokecolor('black');
$grfx->fillcolor('#999');
$grfx->linewidth(2);
$text->font($fontC, 16);
$grfx->translate(@base);

$img_obj = $pdf->image_jpeg('examples\resources\aptfrontview.jpg');
$grfx->formimage($img_obj, 45,5, 0.125*$img_obj->width(),0.25*$img_obj->height());

# caption
drawCaption(['formimage() 12.5x25%'], 'LC');

$grfx->restore();

# ============ demonstrate text ===============================================
# ----------------------------------------------------
# 43. charspace(): show -.9 condensed, 0 normal, +3 expanded 
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);

$text->translate($base[0]+10, $base[1]+100);
$text->charspace(-0.9);
$text->text('Condensed text');

$text->translate($base[0]+10, $base[1]+60);
$text->charspace(0);
$text->text('Normal text');

$text->translate($base[0]+10, $base[1]+20);
$text->charspace(3);
$text->text('Expanded text');

$text->charspace(0);

# caption
drawCaption(['charspace()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 44. wordspace(): show -1 condensed, 0 normal, +3 expanded 
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 13);

$text->translate($base[0]+5, $base[1]+100);
$text->wordspace(-1);
$text->text('Less space between words');

$text->translate($base[0]+5, $base[1]+60);
$text->wordspace(0);
$text->text('Normal space between words');

$text->translate($base[0]+5, $base[1]+20);
$text->wordspace(3);
$text->text('More space between words');

$text->wordspace(0);

# caption
drawCaption(['wordspace()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 45. hscale(): show 85 condensed, 100 normal, 125 expanded 
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 16);

$text->translate($base[0]+15, $base[1]+100);
$text->hscale(85);
$text->text('85% scaled text');

$text->translate($base[0]+15, $base[1]+60);
$text->hscale(100);
$text->text('100% scaled text');

$text->translate($base[0]+15, $base[1]+20);
$text->hscale(125);
$text->text('125% scaled text');

$text->hscale(100);

# caption
drawCaption(['hscale()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 46. lead(): show 1.1 tight, 1.4 normal, 2.5 double-space * 10 pt font
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 10);

$text->translate($base[0]+15, $base[1]+110);
$text->lead(10*1.1);
$text->text('tight leading');
$text->cr();
$text->text('at 110% of font size');

$text->translate($base[0]+15, $base[1]+75);
$text->lead(10*1.4);
$text->text('normal leading');
$text->cr();
$text->text('at 140% of font size');

$text->translate($base[0]+15, $base[1]+40);
$text->lead(10*2.5);
$text->text('double space leading');
$text->cr();
$text->text('at 250% of font size');

# caption
drawCaption(['lead()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 47. render(): show modes 0 - 3
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 16);
$text->strokecolor('black');
$text->fillcolor('#999');

$text->translate($base[0]+15, $base[1]+110);
$text->render(0);
$text->text('render 0 fill only');

$text->translate($base[0]+15, $base[1]+80);
$text->render(1);
$text->text('render 1 stroke only');

$text->translate($base[0]+15, $base[1]+50);
$text->render(2);
$text->text('render 2 fill + stroke');

$text->translate($base[0]+15, $base[1]+20);
$text->render(3);
$text->text('render 3 invisible');

$text->render(0);

# caption
drawCaption(['render()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 48. render(): show modes 4 - 7
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 16);
$text->strokecolor('black');
$text->fillcolor('#999');

$text->translate($base[0]+15, $base[1]+110);
$text->render(4);
$text->text('render 4 fill only');

$text->translate($base[0]+15, $base[1]+80);
$text->render(5);
$text->text('render 5 stroke only');

$text->translate($base[0]+15, $base[1]+50);
$text->render(6);
$text->text('render 6 fill + stroke');

$text->translate($base[0]+15, $base[1]+20);
$text->render(7);
$text->text('render 7 invisible');

# clip s/b last line only, so draw filled rectangle over it
# expect to see only fill within text (basically, blue-filled text)
#$grfx->endpath();
#$grfx->fillcolor('#BBBBFF');
#$grfx->rect($base[0]+10,$base[1]+15, 150,20);
#$grfx->fill();

$text->render(0);

# caption
drawCaption(['render() adds to clip'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 49. rise(): show some sub and super scripts
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontI, 16);
$text->strokecolor('black');
$text->fillcolor('black');

$text->translate($base[0]+15, $base[1]+90);
$text->text('E = mc');
$text->font($fontI, 10);
$text->rise(6);
$text->text('2');
$text->font($fontR, 16);
$text->rise(0);
$text->text(' is famous.');

$text->translate($base[0]+15, $base[1]+50);
$text->text('H');
$text->font($fontR, 10);
$text->rise(-5);
$text->text('2');
$text->font($fontR, 16);
$text->rise(0);
$text->text('O is plain old water.');

# caption
drawCaption(['rise() for sub/super'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# textstate(): omit for now
# ----------------------------------------------------
# font(): shown as part of other examples
# ----------------------------------------------------
# distance(): shown as part of other examples
# ----------------------------------------------------

# ----------------------------------------------------
# 50. cr(): show 3 modes
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 12);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$text->translate($base[0]+15, $base[1]+105);
$text->text('cr()');
$text->cr();
$text->text('goes to the next line');

$text->translate($base[0]+15, $base[1]+70);
$text->text('cr(-8) goes DOWN ');
$text->cr(-8);
$text->text('8pts to start next line');

$text->translate($base[0]+15, $base[1]+40);
$text->text('cr(0)');
$text->cr(0);
$text->text('will     overprint next line');

$text->translate($base[0]+15, $base[1]+10);
$text->text('cr(8) goes UP');
$text->cr(8);
$text->text('8pts to start next line');

# caption
drawCaption(['cr() carriage return'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 51. nl(): show an example
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 12);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$text->translate($base[0]+25, $base[1]+105);
$text->text('Here is some text.');
$text->nl();
$text->text('nl() took us here.');
$text->nl(0);
$text->text('nl(0) took us here.');
$text->nl(200);
$text->text('nl(200) took us here.');
$text->nl();
$text->text('nl() took us here.');
$text->nl(-75);
$text->text('nl(-75) took us here.');
$text->nl();
$text->text('nl() took us here.');

# caption
drawCaption(['nl() newline + indent'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 52. textpos(): place some text and return its position
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 12);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$text->translate($base[0]+15, $base[1]+100);
$text->text('Here is some text.');
$text->nl();
my @loc = $text->textpos();
$text->text('* textpos says this line');
$text->nl();
$text->text("starts at @loc.");
$text->nl();
$text->text("We requested ".($base[0]+15)." ".($base[1]+100-15));

# caption
drawCaption(['textpos()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 53. text() with 4 underlines, indent
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 12);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$text->translate($base[0]+15, $base[1]+110);
$text->text('Some underlined text.', -underline=>'auto');

$text->translate($base[0]+15, $base[1]+90);
$text->text('Loosely underlined text.', -underline=>5);

$text->translate($base[0]+15, $base[1]+65);
$text->text('Double underlined text.', -underline=>[3, 2, 8, 1]);

$text->translate($base[0]+15, $base[1]+35);
$text->text('Overlined text.', -underline=>-11);

$text->translate($base[0]+15, $base[1]+15);
$text->text('Indented 36pt text.', -indent=>36);

# caption
drawCaption(['text() underline, indent'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 54. advancewidth(): show some text, draw box around based on aw, leading
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 12);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$grfx->linewidth(1);
$grfx->strokecolor('green');
$grfx->translate(@base);

$text->translate($base[0]+5, $base[1]+ 95);
$i = ' some text to put in a box ';
$text->text($i);
$lw = $text->advancewidth($i);
$grfx->rect(5,95-$text->lead()/4, $lw,$text->lead());
$grfx->stroke();

$text->font($fontR, 36);
$text->translate($base[0]+5, $base[1]+ 35);
$i = ' more text ';
$text->text($i);
$lw = $text->advancewidth($i);
$grfx->rect(5,35-3*$text->lead()/4, $lw,3*$text->lead());
$grfx->stroke();

# caption
drawCaption(['advancewidth()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 55. text() 
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 12);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$grfx->linewidth(1);
$grfx->strokecolor('red');
$grfx->translate(@base);
$grfx->poly(15,120, 15,10);
$grfx->poly(155,120, 155,10);
$grfx->stroke();

$text->translate($base[0]+15, $base[1]+100);
$text->text('When in the course', 140);
$text->translate($base[0]+15, $base[1]+ 80);
$text->text('of human events, it becomes', 140);
$text->translate($base[0]+15, $base[1]+ 60);
$text->text('necessary for one people to dissolve the', 140);
$text->translate($base[0]+15, $base[1]+ 40);
$text->text('political bands...', 140);

# caption
drawCaption(['text()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# add(): advanced method to directly add content to PDF stream
# ----------------------------------------------------
# compressFlate(): advanced method to turn output compression on
# ----------------------------------------------------
# textstart(): advanced method to start a text object
# ----------------------------------------------------
# textend(): advanced method to end a text object
# ----------------------------------------------------

# ----------------------------------------------------
$pdf->saveas($PDFname);

# =====================================================================
sub colors {
  my $color = shift;
  $grfx->strokecolor($color);
  $grfx->fillcolor($color);
  $text->strokecolor($color);
  $text->fillcolor($color);
}

# ---------------------------------------
# if a single coordinate pair, produces a green dot
# if two or more pairs, produces a green dot at each pair, and connects 
#   with a green line
sub greenLine {
  my $pointsRef = shift;
    my @points = @{ $pointsRef };

  my $i;

  $grfx->linewidth(1);
  $grfx->strokecolor('green');
  $grfx->poly(@points);
  $grfx->stroke();

  # draw green dot at each point
  $grfx->linewidth(3);
  $grfx->linecap(1);  # round
  for ($i=0; $i<@points; $i+=2) {
    $grfx->poly($points[$i],$points[$i+1], $points[$i],$points[$i+1]);
  }
  $grfx->stroke();
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
  $text->text_center($pageNo); # prefill page number before any other content
}

# ---------------------------------------
sub makeCell {
  my ($cellLocX, $cellLocY, $cellSizeW, $cellSizeH) = @_;

  # outline and clip of cell
  $grfx->strokecolor('#CCC');
  $grfx->linewidth(2);
  $grfx->rect($cellLocX,$cellLocY, $cellSizeW,$cellSizeH);
  $grfx->stroke();

 #$grfx->linewidth(1);
 #$grfx->rect($cellLocX,$cellLocY, $cellSizeW,$cellSizeH);
 #$grfx->clip(1);
 #$text->linewidth(1);
 #$text->rect($cellLocX,$cellLocY, $cellSizeW,$cellSizeH);
 #$text->clip(1);
}

# ---------------------------------------
# draw a set of axes at current origin
sub drawAxes {

  # draw 75-long axes, at offset 
  $grfx->linejoin(0);  
  $grfx->linewidth(1);
  $grfx->poly($axisOffset[0]+0, $axisOffset[1]+75, 
	      $axisOffset[0]+0, $axisOffset[1]+0, 
	      $axisOffset[0]+75,$axisOffset[1]+0);
  $grfx->stroke();
  # 36x36 box
 #$grfx->rect(0,0, 36,36);  # draw a square
 #$grfx->stroke();

  # X axis arrowhead draw
  $grfx->poly($axisOffset[0]+75-2, $axisOffset[1]+0+2, 
	      $axisOffset[0]+75+0, $axisOffset[1]+0+0, 
	      $axisOffset[0]+75-2, $axisOffset[1]+0-2);
  $grfx->stroke();

  # Y axis arrowhead draw
  $grfx->poly($axisOffset[0]+0-2, $axisOffset[1]+75-2, 
  	      $axisOffset[0]+0+0, $axisOffset[1]+75+0, 
 	      $axisOffset[0]+0+2, $axisOffset[1]+75-2);
  $grfx->stroke();

}

# ---------------------------------------
# label the X and Y axes, and draw a sample 'n'
sub drawLabels {
  my ($Xlabel, $Ylabel) = @_;

  my $fontI = $pdf->corefont('Times-Italic');
  my $fontR = $pdf->corefont('Times-Roman');

  # outline "n"
  $text->distance($axisOffset[0]+0, $axisOffset[1]+0);
  $text->font($fontR, 72);
  $text->render(1);
  $text->text('n');

  $text->render(0);
  $text->font($fontI, 12);

  # X axis label
  $text->distance(75+2, 0-3);
  $text->text($Xlabel);

  # Y axis label
  $text->distance(-75-2+0-4, 0+3+75+2);
  $text->text($Ylabel);

}

# ---------------------------------------
# write out a 1 or more line caption             
sub drawCaption {
  my $captionsRef = shift;
    my @captions = @$captionsRef;
  my $just = shift;  # 'LC' = left justified (centered on longest line)

  my ($width, $i, $y);

  $text->font($fontC, 12);
  $text->fillcolor('black');

  # find longest line width
  $width = 0;
  foreach (@captions) {
    $width = max($width, $text->advancewidth($_));
  }

  for ($i=0, $y=20; $i<@captions; $i++, $y+=13) {
    # $just = LC
    $text->translate($cellLoc[0]+$cellSize[0]/2-$width/2, $cellLoc[1]-$y);
    $text->text($captions[$i]);
  }
}

# ---------------------------------------
# m, n  (both within X and Y index ranges) = set to this position
# 0  = next cell (starts new page if necessary)
# N  = >0 number of cells to skip (starts new page if necessary)
sub makeCellLoc {
  my ($X, $Y) = @_;

  my @cellX = (36, 212, 388);        # horizontal (column positions L to R)
  my @cellY = (625, 458, 281, 104);  # vertical (row positions T to B)
  my $add;

  if (defined $Y) {
    # X and Y given, use if valid indices
    if ($X < 0 || $X > $#cellX) { die "X = $X is invalid index."; }
    if ($Y < 0 || $Y > $#cellY) { die "Y = $Y is invalid index."; }
    $globalX = $X;
    $globalY = $Y;
    $add = 0;
  } elsif ($X == 0) {
    # requesting next cell
    $add = 1;
  } else { 
    # $X is number of cells to skip (1+)
    $add = $X + 1;
  }

  while ($add-- > 0) {
    if ($globalX == $#cellX) {
      # already at end of row
      $globalX = 0;
      $globalY++;
    } else {
      $globalX++;
    }

    if ($globalY > $#cellY) {
      # ran off bottom row, so go to new page
      $globalX = $globalY = 0;
      nextPage();
      # next page of output, 523pt wide x 720pt high
    }
  }

  return ($cellX[$globalX], $cellY[$globalY]);
}
