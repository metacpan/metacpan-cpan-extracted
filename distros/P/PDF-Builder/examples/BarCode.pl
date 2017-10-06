# exercise BarCode.pm as much as possible
# outputs BarCode.pdf
# author: Phil M Perry
# information from http://www.keyence.com/ss/products/auto_id/barcode_lecture/

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

my $compress = 'flate';  # compressed streams
#my $compress = 'none';  # no stream compression, for debugging

my $PDFname = 'BarCode.pdf';
my $globalX = 0; 
my $globalY = 0;

my ($unused, $cell_height, $j, $cont);

my $pdf = PDF::Builder->new(-compress => $compress);

my ($page, $grfx, $text); # objects for page, graphics, text
my (@base, @styles, @points, $i, $lw, $angle, @npts);
my (@cellLoc, @cellSize, $font, $width, $d1, $d2, $d3, $d4);
my @axisOffset = (5, 5); # clear the edge of the cell
my ($barcode, $type, $content, $bar_height, $mils, $scale);

my $pageNo = 0;
nextPage();
# next (first) page of output, 523pt wide x 720pt high

my $fontR = $pdf->corefont('Times-Roman');
my $fontI = $pdf->corefont('Times-Italic');
my $fontC = $pdf->corefont('Courier');

# page title
$text->textlabel(40,765, $fontR,20, "1D Barcodes");
$bar_height = 80;
$mils = 8;  # bar width unit (minimum bar/gap size, in .001"). default 1 pt
$scale = 1;  # formimage scaling factor

# ----------------------------------------------------
#    UPC not supported
# alphabet: 0..9
# length: 12 digits UPC-A (1+5+5+1) or 8 digits UPC-E (1+6+1)
# should have longer left guard, center (UPC-A), and right guard bars

# ----------------------------------------------------
# 1. Codabar
# alphabet: 0..9 - $ / . + (codabar.pm also allows : )
# length: unlimited, manually add start and stop characters
# 4 bars + 3 gaps per character + 1 narrow, 2 widths narrow and wide (2x)
# start and stop characters any one or two of A B C D a b c d
# note that codabar.pm uppercases start and stop characters, may be error!
@cellLoc = makeCellLoc(0, 0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$type = 'Codabar';
$content = 'A32134567890123B';  # len 16 includes start/stop chars, encode=16
$barcode = $pdf->xo_codabar(
    -code => $content,
    -zone => $bar_height,
    -umzn => 0,
    -lmzn => 10,
    -font => $pdf->corefont('Helvetica'),
    -fnsz => 10,
    -mils => $mils,
);
$barcode->{'-docompress'} = 0;
delete $barcode->{'Filter'};

$grfx->formimage($barcode, centerbc($barcode, @cellSize, @base), $scale);

# caption
drawCaption([$type], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 2. Code 128A
# alphabet:   128 ASCII characters 0x00..0x7F or 99 digit pairs
#  CODE A:  ASCII sp.._ (x20..x5F) NUL..US (x00..x1F)   UPPER CASE only
#  CODE B:  ASCII sp..DEL (x20..x7F) with | (x7C) replaced by a hook symbol
#  CODE C:  numeric decimal 00..99  (2n digits only)
#    all alphabets have additional EAN-128-specific controls in alphabet
# START CODE A, may change to CODE x midstream 
# length: unlimited
# 4 distinct bar and gap widths
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$type = 'Code 128 A';
$content = 'TEST of '.$type;
$barcode = $pdf->xo_code128(
    -code => $content,
    -zone => $bar_height,
    -umzn => 0,
    -lmzn => 10,
    -font => $pdf->corefont('Helvetica'),
    -fnsz => 10,
    -mils => $mils,
);
$barcode->{'-docompress'} = 0;
delete $barcode->{'Filter'};

$grfx->formimage($barcode, centerbc($barcode, @cellSize, @base), $scale);

# caption
drawCaption([$type], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 3. Code 128B
# alphabet:   128 ASCII characters 0x00..0x7F or 99 digit pairs
#  CODE A:  ASCII sp.._ (x20..x5F) NUL..US (x00..x1F)   UPPER CASE only
#  CODE B:  ASCII sp..DEL (x20..x7F) with | (x7C) replaced by a hook symbol
#  CODE C:  numeric decimal 00..99  (2n digits only)
#    all alphabets have additional EAN-128-specific controls in alphabet
# START CODE B, may change to CODE x midstream 
# length: unlimited
# 4 distinct bar and gap widths
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$type = 'Code 128 B';
$content = 'Test Of '.$type;
$barcode = $pdf->xo_code128(
    -code => $content,
    -zone => $bar_height,
    -umzn => 0,
    -lmzn => 10,
    -font => $pdf->corefont('Helvetica'),
    -fnsz => 10,
    -mils => $mils,
);
$barcode->{'-docompress'} = 0;
delete $barcode->{'Filter'};

$grfx->formimage($barcode, centerbc($barcode, @cellSize, @base), $scale);

# caption
drawCaption([$type], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 4. Code 128C
# alphabet: 0..9
# length: max 10?, 2n values in this mode
# START CODE C, may change to CODE x midstream 
# 4 distinct bar and gap widths
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$type = 'Code 128 C';
#$content = '0123456789';  # doesn't work!
$content = 'Test Of '.$type;
$barcode = $pdf->xo_code128(
    -code => $content,
    -zone => $bar_height,
    -umzn => 0,
    -lmzn => 10,
    -font => $pdf->corefont('Helvetica'),
    -fnsz => 10,
    -mils => $mils,
);
$barcode->{'-docompress'} = 0;
delete $barcode->{'Filter'};

$grfx->formimage($barcode, centerbc($barcode, @cellSize, @base), $scale);

# caption
drawCaption([$type], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 5. Code EAN-128
# note that EAN-128 is part of Code 128
# alphabet:   128 ASCII characters 0x00..0x7F or 99 digit pairs
#  CODE A:  ASCII sp.._ (x20..x5F) NUL..US (x00..x1F)
#  CODE B:  ASCII sp..DEL (x20..x7F) with | (x7C) replaced by a hook symbol
#  CODE C:  numeric decimal 00..99
#    all alphabets have additional EAN-128-specific controls in alphabet
# superset of CODE 128, with FNC1 required after START CODE x
# length: there appears to be a lengh limit of around 8 digits per (group), and
#      codes will overlay each other if too long. if groups short enough,
#      length is unlimited
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$type = 'Code EAN-128';
#$content = '00123456780000000001';  # seems to be too long
$content = '(00)12345(11)0001';
$barcode = $pdf->xo_code128(
    -code => $content,
    -zone => $bar_height,
    -umzn => 0,
    -lmzn => 10,
    -font => $pdf->corefont('Helvetica'),
    -fnsz => 10,
    -mils => $mils,
);
$barcode->{'-docompress'} = 0;
delete $barcode->{'Filter'};

$grfx->formimage($barcode, centerbc($barcode, @cellSize, @base), $scale);

# caption
drawCaption([$type], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 6. Code 3 of 9
# alphabet: 0..9 A..Z _ sp - $ / . + %
# length: up to 43
# narrow bar/gap and wide bar/gap (3 to 5.3 times wider) 1 character is 9 bars
#   and spaces, with 3 wide and 6 narrow
# * used for start and stop characters
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$type = 'Code 3 of 9';
$content = 'Test '.$type;  # 3 of 9 will uppercase this
$barcode = $pdf->xo_3of9(
    -code => $content,
    -zone => $bar_height,
    -umzn => 0,
    -lmzn => 10,
    -font => $pdf->corefont('Helvetica'),
    -fnsz => 10,
    -mils => $mils,
);
$barcode->{'-docompress'} = 0;
delete $barcode->{'Filter'};

$grfx->formimage($barcode, centerbc($barcode, @cellSize, @base), $scale);

# caption
drawCaption([$type], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 7. Code 3 of 9 with check digit
# alphabet: 0..9 A..Z _ sp - $ / . + %
# length: up to 43
# narrow bar/gap and wide bar/gap (3 to 5.3 times wider) 1 character is 9 bars
#   and spaces, with 3 wide and 6 narrow
# * used for start and stop characters
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$type = 'Code 3 of 9';
$content = 'Test '.$type;  # 3 of 9 will uppercase this
$barcode = $pdf->xo_3of9(
    -code => $content,
    -zone => $bar_height,
    -umzn => 0,
    -lmzn => 10,
    -font => $pdf->corefont('Helvetica'),
    -fnsz => 10,
    -mils => $mils,
);
$barcode->{'-docompress'} = 0;
delete $barcode->{'Filter'};

$grfx->formimage($barcode, centerbc($barcode, @cellSize, @base), $scale);

# caption
drawCaption([$type.' check digit'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 8. Code 3 of 9 with check digit
# alphabet: 0..9 A..Z _ sp - $ / . + %
# length: up to 43
# narrow bar/gap and wide bar/gap (3 to 5.3 times wider) 1 character is 9 bars
#   and spaces, with 3 wide and 6 narrow
# * used for start and stop characters
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$type = 'Code 3 of 9';
$content = 'Test '.$type;  # 3 of 9 will uppercase this
$barcode = $pdf->xo_3of9(
    -code => $content,
    -zone => $bar_height,
    -umzn => 0,
    -lmzn => 10,
    -font => $pdf->corefont('Helvetica'),
    -fnsz => 10,
    -mils => $mils,
);
$barcode->{'-docompress'} = 0;
delete $barcode->{'Filter'};

$grfx->formimage($barcode, centerbc($barcode, @cellSize, @base), $scale);

# caption
drawCaption([$type.' full ASCII'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 9. Code 3 of 9 full ASCII with check digit
# alphabet: full ASCII x00..x7F
# length: up to 43
# narrow bar/gap and wide bar/gap (3 to 5.3 times wider) 1 character is 9 bars
#   and spaces, with 3 wide and 6 narrow
# * used for start and stop characters
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$type = 'Code 3 of 9';
$content = 'Test '.$type;  # 3 of 9 will uppercase this
$barcode = $pdf->xo_3of9(
    -code => $content,
    -zone => $bar_height,
    -umzn => 0,
    -lmzn => 10,
    -font => $pdf->corefont('Helvetica'),
    -fnsz => 10,
    -mils => $mils,
);
$barcode->{'-docompress'} = 0;
delete $barcode->{'Filter'};

$grfx->formimage($barcode, centerbc($barcode, @cellSize, @base), $scale);

# caption
drawCaption([$type.' fASC chkd'], 'LC');

$grfx->restore();

# ----------------------------------------------------
#    Code EAN (EAN-8) not supported
# alphabet: 0..9
# length: 8   4+4  (4+3 & chkdig)
# should have longer left guard, center, and right guard bars
# narrow bar width .26 to .66mm (.33mm preferred)
# bar height (guard bars/text) 18.29 to 45.72mm (22.86mm preferred)
# total length excluding left/right margins 29.83 to 74.58mm (37.29mm preferred)

# ----------------------------------------------------
# 10. Code EAN-13
# alphabet: 0..9
# length: 13 (for books: 978 + 10-digit ISBN)   1+6+6 (1+6+5 & chkdig)
# should have longer left guard, center, and right guard bars
# narrow bar width .26 to .66mm (.33mm preferred)
# bar height (guard bars/text) 18.29 to 45.72mm (22.86mm preferred)
# total length excluding left/right margins 29.83 to 74.58mm (37.29mm preferred)
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$type = 'Code EAN-13';
$content = '9123456789013';
$barcode = $pdf->xo_ean13(
    -code => $content,
    -zone => $bar_height,
    -umzn => 0,
    -lmzn => 10,
    -font => $pdf->corefont('Helvetica'),
    -fnsz => 10,
    -mils => $mils*2,
);
$barcode->{'-docompress'} = 0;
delete $barcode->{'Filter'};

$grfx->formimage($barcode, centerbc($barcode, @cellSize, @base), $scale);

# caption
drawCaption([$type.' w/ prefix'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 11. Code Interleaved 2 of 5
# alphabet: 0..9
# length: even (2n) number of digits
# NOTE: Industrial 2 of 5, Matrix 2 of 5, COOP 2 of 5, and IATA barcodes
#       are variations on this barcode, but not equal to it!
# 5 bars first digit interleaved with 5 spaces of second digit, etc.
@cellLoc = makeCellLoc(0);
@cellSize = (170, 131); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 20);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

$type = 'Code Int 2 of 5';
$content = '0123456789';
$barcode = $pdf->xo_2of5int(
    -code => $content,
    -zone => $bar_height,
    -umzn => 0,
    -lmzn => 10,
    -font => $pdf->corefont('Helvetica'),
    -fnsz => 10,
    -mils => $mils*2,
);
$barcode->{'-docompress'} = 0;
delete $barcode->{'Filter'};

$grfx->formimage($barcode, centerbc($barcode, @cellSize, @base), $scale);

# caption
drawCaption([$type], 'LC');

$grfx->restore();

# ----------------------------------------------------
$pdf->saveas($PDFname);

# =====================================================================
sub centerbc {
  my ($img, $wcapacity,$hcapacity, @base) = @_;

  my $w = ($wcapacity - $img->width())/2 + $base[0];
  my $h = ($hcapacity - $img->height())/2 + $base[1];

  return ($w, $h);
}

# ---------------------------------------
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

  # lower left corner of cell
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
