#!/usr/bin/perl
# exercise Content/Text.pm as much as possible
# outputs ContentText.pdf
# author: Phil M Perry

use warnings;
use strict;

our $VERSION = '3.015'; # VERSION
my $LAST_UPDATE = '3.010'; # manually update whenever code is changed

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

my $DofI = 'When in the course of human events, it becomes necessary for ' .
           'one people to dissolve the political bands which have heretofore ' .
           'connected them with another...';

# Lorem Ipsum text, borrowed from examples/022_truefonts and newlines inserted.
#  To use without newlines, $LoremIpsum =~ s/\n/ /g;
my $LoremIpsum = 
"Sed ut perspiciatis, unde omnis iste natus error sit ".
"voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, ".
"quae ab illo inventore veritatis et quasi architecto beatae vitae dicta ".
"sunt, explicabo. Nemo enim ipsam voluptatem, quia voluptas sit, aspernatur ".
"aut odit aut fugit, sed quia consequuntur magni dolores eos, qui ratione ".
"dolor sit, voluptatem sequi nesciunt, neque porro quisquam est, qui dolorem ".
"ipsum, quia amet, consectetur, adipisci velit, sed quia non numquam eius ".
"modi tempora incidunt, ut labore et dolore magnam aliquam quaerat ".
"voluptatem.\nUt enim ad minima veniam, quis nostrum exercitationem ullam ".
"corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? ".
"Quis autem vel eum iure reprehenderit, qui in ea voluptate velit esse, quam ".
"nihil molestiae consequatur, vel illum, qui dolorem eum fugiat, quo voluptas ".
"nulla pariatur? At vero eos et accusamus et iusto odio dignissimos ducimus, ".
"qui blanditiis praesentium voluptatum deleniti atque corrupti, quos dolores ".
"et quas molestias excepturi sint, obcaecati cupiditate non provident, ".
"similique sunt in culpa, qui officia deserunt mollitia animi, id est laborum ".
"et dolorum fuga.\nEt harum quidem rerum facilis est et expedita distinctio. ".
"Nam libero tempore, cum soluta nobis est eligendi optio, cumque nihil ".
"impedit, quo minus id, quod maxime placeat, facere possimus, omnis voluptas ".
"assumenda est, omnis dolor repellendus.\nTemporibus autem quibusdam et aut ".
"officiis debitis aut rerum necessitatibus saepe eveniet, ut et voluptates ".
"repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur ".
"a sapiente delectus, ut aut reiciendis voluptatibus maiores alias ".
"consequatur aut perferendis doloribus asperiores repellat.";
# A short LI paragraph
my $LoremIpsumPara = 
"Sed ut perspiciatis, unde omnis iste natus error sit ".
"voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, ".
"quae ab illo inventore veritatis.";

my ($unused, $cell_height, $j, $cont);

my $pdf = PDF::Builder->new();
my ($page, $grfx, $text); # objects for page, graphics, text
my (@base, @styles, @points, $i, $lw, $angle, @npts);
#$pdf->{'forcecompress'} = 0;  # don't compress, so we can see what's happening
my (@cellLoc, @cellSize, $font, $width, $d1, $d2, $d3, $d4);
my @axisOffset = (5, 5); # clear the edge of the cell

my $pageNo = 0;
nextPage();
# next (first) page of output, 523pt wide x 720pt high

my $fontR = $pdf->corefont('Times-Roman');
my $fontI = $pdf->corefont('Times-Italic');
my $fontC = $pdf->corefont('Courier');

# ----------------------------------------------------
# 1. text_left()  alias for text
@cellLoc = makeCellLoc(0, 0);
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
$text->text_left('When in the course', 140);
$text->translate($base[0]+15, $base[1]+ 80);
$text->text_left('of human events, it becomes', 140);
$text->translate($base[0]+15, $base[1]+ 60);
$text->text_left('necessary for one people to dissolve the', 140);
$text->translate($base[0]+15, $base[1]+ 40);
$text->text_left('political bands...', 140);

# caption
drawCaption(['text_left()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 2. text_justified() 
@cellLoc = makeCellLoc(1);
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
$text->text_justified('When in the course', 140);
$text->translate($base[0]+15, $base[1]+ 80);
$text->text_justified('of human events, it becomes', 140);
$text->translate($base[0]+15, $base[1]+ 60);
$text->text_justified('necessary for one people to dissolve the', 140);
$text->translate($base[0]+15, $base[1]+ 40);
$text->text_justified('political bands...', 140);

# caption
drawCaption(['text_justified()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 3. text_fill_left(): show one long original line chopped into short lines
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

$i = $DofI;
$text->translate($base[0]+15, $base[1]+105);
while ($i ne '') {
  ($lw, $i) = $text->text_fill_left($i, 140, -spillover=>0);
  $text->cr();
}

# caption
drawCaption(['text_fill_left()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 4. text_fill(): alias for text_fill_left()
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

$i = $DofI;
$text->translate($base[0]+15, $base[1]+105);
while ($i ne '') {
  ($lw, $i) = $text->text_fill($i, 140, -spillover=>0);
  $text->cr();
}

# caption
drawCaption(['text_fill()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 5. text_fill_center(): show one long original line chopped into short lines
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

$i = $DofI;
$text->translate($base[0]+15+140/2, $base[1]+105);
while ($i ne '') {
  ($lw, $i) = $text->text_fill_center($i, 140, -spillover=>0);
  $text->cr();
}

# caption
drawCaption(['text_fill_center()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 6. text_fill_right(): show one long original line chopped into short lines
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

$i = $DofI;
$text->translate($base[0]+15+140, $base[1]+105);
while ($i ne '') {
  ($lw, $i) = $text->text_fill_right($i, 140, -spillover=>0);
  $text->cr();
}

# caption
drawCaption(['text_fill_right()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 7. text_fill_justified(): show one long original line chopped into short lines
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

$i = $DofI;
$text->translate($base[0]+15, $base[1]+105);
while ($i ne '') {
  ($lw, $i) = $text->text_fill_justified($i, 140, -spillover=>0);
  $text->cr();
}

# caption
drawCaption(['text_fill_justified()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 8. text_fill_justified() with centered final line
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

$i = $DofI;
$text->translate($base[0]+15, $base[1]+105);
while ($i ne '') {
  ($lw, $i) = $text->text_fill_justified($i, 140, 
	                 -spillover=>0, -last_align => 'c');
  $text->cr();
}

# caption
drawCaption(['... last line centered'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 9. text_fill_justified() with right-aligned final line
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

$i = $DofI;
$text->translate($base[0]+15, $base[1]+105);
while ($i ne '') {
  ($lw, $i) = $text->text_fill_justified($i, 140, 
	                 -spillover=>0, -last_align => 'r');
  $text->cr();
}

# caption
drawCaption(['... last line right'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 10. paragraph(): fits a paragraph of text to a given width
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

$i = $LoremIpsumPara;

$text->translate($base[0]+15, $base[1]+105);
($i, $unused) = $text->paragraph($i, 140,110, 0,
	                 -spillover=>0);
if ($i ne '') { print "paragraph() had leftover text!\n"; }

# caption
drawCaption(['paragraph()'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 11. paragraph() left aligned, indent 1.5em
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

$i = $LoremIpsumPara;

$text->translate($base[0]+15, $base[1]+105);
($i, $unused) = $text->paragraph($i, 140,110, 0, -spillover=>0,
	-align => 'left', -pndnt => 1.5 );
if ($i ne '') { print "paragraph() had leftover text!\n"; }

# caption
drawCaption(['paragraph() ind 1.5em'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 12. paragraph() left aligned, outdent 1.5em
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

$i = $LoremIpsumPara;

$text->translate($base[0]+15, $base[1]+105);
($i, $unused) = $text->paragraph($i, 140,110, 0, -spillover=>0,
	-align => 'left', -pndnt => -1.5 );
if ($i ne '') { print "paragraph() had leftover text!\n"; }

# caption
drawCaption(['paragraph() ind -1.5em'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 13. paragraph() justified
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

$i = $LoremIpsumPara;

$text->translate($base[0]+15, $base[1]+105);
($i, $unused) = $text->paragraph($i, 140,110, 0, -spillover=>0,
	-align => 'justified' );
if ($i ne '') { print "paragraph() had leftover text!\n"; }

# caption
drawCaption(['paragraph() justified'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 14. paragraph() justified indent 1.5em
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

$i = $LoremIpsumPara;

$text->translate($base[0]+15, $base[1]+105);
($i, $unused) = $text->paragraph($i, 140,110, 0, -spillover=>0,
	-align => 'justified', -pndnt => 1.5 );
if ($i ne '') { print "paragraph() had leftover text!\n"; }

# caption
drawCaption(['paragraph() j ind 1.5'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 15. paragraph() justified, outdent 1.5em
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

$i = $LoremIpsumPara;

$text->translate($base[0]+15, $base[1]+105);
($i, $unused) = $text->paragraph($i, 140,110, 0, -spillover=>0,
	-align => 'justified', -pndnt => -1.5 );
if ($i ne '') { print "paragraph() had leftover text!\n"; }

# caption
drawCaption(['paragraph() j ind -1.5'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 16. paragraph() right aligned
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

$i = $LoremIpsumPara;

$text->translate($base[0]+15+140, $base[1]+105);
($i, $unused) = $text->paragraph($i, 140,110, 0, -spillover=>0,
	-align => 'right' );
if ($i ne '') { print "paragraph() had leftover text!\n"; }

# caption
drawCaption(['paragraph() right algn'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 17. paragraph() right aligned indent 2.5em
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

$i = $LoremIpsumPara;

$text->translate($base[0]+15+140, $base[1]+105);
($i, $unused) = $text->paragraph($i, 140,110, 0, -spillover=>0,
	-align => 'right', -pndnt => 2.5 );
if ($i ne '') { print "paragraph() had leftover text!\n"; }

# caption
drawCaption(['paragraph() r ind 2.5'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 18. paragraph() right aligned, outdent 2.0em
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

$i = $LoremIpsumPara;

$text->translate($base[0]+15+140, $base[1]+105);
($i, $unused) = $text->paragraph($i, 140,110, 0, -spillover=>0,
	-align => 'right', -pndnt => -2.0 );
if ($i ne '') { print "paragraph() had leftover text!\n"; }

# caption
drawCaption(['paragraph() r ind -2.0'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 19. paragraph() centered
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

$i = $LoremIpsumPara;

$text->translate($base[0]+15+140/2, $base[1]+105);
($i, $unused) = $text->paragraph($i, 140,110, 0, -spillover=>0,
	-align => 'center' );
if ($i ne '') { print "paragraph() had leftover text!\n"; }

# caption
drawCaption(['paragraph() centered'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 20. section() 
@cellLoc = makeCellLoc(4);  # new page
@cellLoc = makeCellLoc(0, 2);  # full page, start at second row up
$cell_height = 440;
@cellSize = (520, $cell_height); 
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
# column limits
$grfx->poly(15,$cell_height-11, 15,10);
$grfx->poly(155,$cell_height-11, 155,10);
$grfx->poly(190,$cell_height-11, 190,10);
$grfx->poly(330,$cell_height-11, 330,10);
$grfx->poly(365,$cell_height-11, 365,10);
$grfx->poly(505,$cell_height-11, 505,10);
$grfx->stroke();

$i = $LoremIpsum;

$cont = 0;
for ($j=0; $j<3; $j++) {
  $text->translate($base[0]+15+175*$j, $base[1]+$cell_height-23);
  ($i, $cont, $unused) = $text->section($i, 140,$cell_height-42, $cont, 
	  -spillover=>0, -align => 'left' );
}
if ($i ne '') { print "section() had leftover text!\n"; }

# caption
drawCaption(['section() left aligned (3 calls)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 21. section()  with 10pt paragraph spacing
@cellLoc = makeCellLoc(5);  # new page
@cellLoc = makeCellLoc(0, 2);  # full page, start at second row up
$cell_height = 440;
@cellSize = (520, $cell_height); 
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
# column limits
$grfx->poly(15,$cell_height-11, 15,10);
$grfx->poly(155,$cell_height-11, 155,10);
$grfx->poly(190,$cell_height-11, 190,10);
$grfx->poly(330,$cell_height-11, 330,10);
$grfx->poly(365,$cell_height-11, 365,10);
$grfx->poly(505,$cell_height-11, 505,10);
$grfx->stroke();

$i = $LoremIpsum;

$cont = 0;
for ($j=0; $j<3; $j++) {
  $text->translate($base[0]+15+175*$j, $base[1]+$cell_height-23);
  ($i, $cont, $unused) = $text->section($i, 140,$cell_height-42, $cont, 
  	  -spillover=>0, -align => 'left', -pvgap => 10 );
}
if ($i ne '') { print "section() had leftover text!\n"; }

# caption
drawCaption(['section() left align 10pt para gap (3 calls)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 22. section()  with 2em paragraph indent
@cellLoc = makeCellLoc(5);  # new page
@cellLoc = makeCellLoc(0, 2);  # full page, start at second row up
$cell_height = 440;
@cellSize = (520, $cell_height); 
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
# column limits
$grfx->poly(15,$cell_height-11, 15,10);
$grfx->poly(155,$cell_height-11, 155,10);
$grfx->poly(190,$cell_height-11, 190,10);
$grfx->poly(330,$cell_height-11, 330,10);
$grfx->poly(365,$cell_height-11, 365,10);
$grfx->poly(505,$cell_height-11, 505,10);
$grfx->stroke();

$i = $LoremIpsum;

$cont = 0;
for ($j=0; $j<3; $j++) {
  $text->translate($base[0]+15+175*$j, $base[1]+$cell_height-23);
  ($i, $cont, $unused) = $text->section($i, 140,$cell_height-42, $cont, 
	  -spillover=>0, -align => 'left', -pndnt => 2 );
}
if ($i ne '') { print "section() had leftover text!\n"; }

# caption
drawCaption(['section() left align 2em para indent (3 calls)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 23. section()  with 2em paragraph outdent
@cellLoc = makeCellLoc(5);  # new page
@cellLoc = makeCellLoc(0, 2);  # full page, start at second row up
$cell_height = 440;
@cellSize = (520, $cell_height); 
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
# column limits
$grfx->poly(15,$cell_height-11, 15,10);
$grfx->poly(155,$cell_height-11, 155,10);
$grfx->poly(190,$cell_height-11, 190,10);
$grfx->poly(330,$cell_height-11, 330,10);
$grfx->poly(365,$cell_height-11, 365,10);
$grfx->poly(505,$cell_height-11, 505,10);
$grfx->stroke();

$i = $LoremIpsum;

$cont = 0;
for ($j=0; $j<3; $j++) {
  $text->translate($base[0]+15+175*$j, $base[1]+$cell_height-23);
  ($i, $cont, $unused) = $text->section($i, 140,$cell_height-42, $cont,
	  -spillover=>0, -align => 'left', -pndnt => -2 );
}
if ($i ne '') { print "section() had leftover text!\n"; }

# caption
drawCaption(['section() left align 2em para outdent (3 calls)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 24. section() justified with 2em paragraph indent
@cellLoc = makeCellLoc(5);  # new page
@cellLoc = makeCellLoc(0, 2);  # full page, start at second row up
$cell_height = 440;
@cellSize = (520, $cell_height); 
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
# column limits
$grfx->poly(15,$cell_height-11, 15,10);
$grfx->poly(155,$cell_height-11, 155,10);
$grfx->poly(190,$cell_height-11, 190,10);
$grfx->poly(330,$cell_height-11, 330,10);
$grfx->poly(365,$cell_height-11, 365,10);
$grfx->poly(505,$cell_height-11, 505,10);
$grfx->stroke();

$i = $LoremIpsum;

$cont = 0;
for ($j=0; $j<3; $j++) {
  $text->translate($base[0]+15+175*$j, $base[1]+$cell_height-23);
  ($i, $cont, $unused) = $text->section($i, 140,$cell_height-42, $cont,
	  -spillover=>0, -align => 'justified', -pndnt => 2 );
}
if ($i ne '') { print "section() had leftover text!\n"; }

# caption
drawCaption(['section() justified 2em para indent (3 calls)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 25. section() left aligned with 2em paragraph indent and 5pt gap
@cellLoc = makeCellLoc(5);  # new page
@cellLoc = makeCellLoc(0, 2);  # full page, start at second row up
$cell_height = 440;
@cellSize = (520, $cell_height); 
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
# column limits
$grfx->poly(15,$cell_height-11, 15,10);
$grfx->poly(155,$cell_height-11, 155,10);
$grfx->poly(190,$cell_height-11, 190,10);
$grfx->poly(330,$cell_height-11, 330,10);
$grfx->poly(365,$cell_height-11, 365,10);
$grfx->poly(505,$cell_height-11, 505,10);
$grfx->stroke();

$i = $LoremIpsum;

$cont = 0;
for ($j=0; $j<3; $j++) {
  $text->translate($base[0]+15+175*$j, $base[1]+$cell_height-23);
  ($i, $cont, $unused) = $text->section($i, 140,$cell_height-42, $cont,
	  -spillover=>0, -align => 'justify', -pndnt => 2, -pvgap => 5 );
}
if ($i ne '') { print "section() had leftover text!\n"; }

# caption
drawCaption(['section() justified 2em para indent 5pt gap (3 calls)'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 26. textlabel() examples
# code borrowed from examples/020_textunderline and modified
@cellLoc = makeCellLoc(5);  # new page
@cellLoc = makeCellLoc(0, 3);  # full page, start at bottom row 
$cell_height = 500;
@cellSize = (520, $cell_height); 
$grfx->save();

makeCell(@cellLoc, @cellSize);
@base=@cellLoc;
#$base[0] += 10;
#$base[1] += 10;
$text->font($fontR, 12);
$text->strokecolor('black');
$text->fillcolor('black');
$text->lead(15);

#my $f1 = $pdf->corefont('Helvetica', -encode=>'latin1');
my $f2 = $pdf->corefont('Helvetica-Bold', -encode=>'latin1');

# place black dot at text origin coordinates
$grfx->linewidth(2);
$grfx->strokecolor('black');

$grfx->circle(50,530, 0.5);
$grfx->stroke();
$text->textlabel(50,530, $f2, 20, 'Normal Helvetica Bold Text in Red', -color=>'red');

$grfx->circle(50,430, 0.5);
$grfx->stroke();
$text->textlabel(50,430, $f2, 20, 'Normal Text in Blue Triple Underline in Red+Yellow+Black -45d',
    -color=>'#0000CC',
    -rotate=>-45,
    -hscale=>65,
    # 3 underlines:
    #   distance 4, thickness 1, color red
    #   distance 7, thickness 1.5, color yellow
    #   distance 11, thickness 2, color (strokecolor default) black
    -underline=>[4,[1,'red'],7,[1.5,'yellow'],11,2],
);

$grfx->circle(300,430, 0.5);
$grfx->stroke();
$text->textlabel(300,430, $f2, 20, 'Text Centered +45d',
    -color=>'#0000CC',
    -rotate=>45,
    -center=>1,
    -underline=>[4,[2,'red']],
);

$grfx->circle(520,430, 0.5);
$grfx->stroke();
$text->textlabel(520,430, $f2, 20, 'Text Right -45d',
    -color=>'#0000CC',
    -rotate=>-45,
    -right=>1,
    -underline=>[4,[2,'red']],
);

$grfx->circle(300,360, 0.5);
$grfx->stroke();
$text->textlabel(300,360, $f2, 20, '"auto" underline',
    -color=>'#0000CC',
    -underline=>'auto',
);

$grfx->circle(300,330, 0.5);
$grfx->stroke();
$text->textlabel(300,330, $f2, 20, 'Extra word spacing',
    -color=>'#0000CC',
    -wordspace=>10,
);

$grfx->circle(300,300, 0.5);
$grfx->stroke();
$text->textlabel(300,300, $f2, 20, 'Extra char spacing',
    -color=>'#0000CC',
    -charspace=>2,
);

$grfx->circle(300,270, 0.5);
$grfx->stroke();
$text->textlabel(300,270, $f2, 20, 'Condensed text',
    -color=>'#0000CC',
    -charspace=>-2,
);

$grfx->circle(300,240, 0.5);
$grfx->stroke();
$text->textlabel(300,240, $f2, 20, 'Render mode 1',
    # note that color is fill color, which is not used (only stroke color)
    -color=>'#0000CC',
    -render=>1,
);

# caption
drawCaption(['textlabel() samples'], 'LC');

$grfx->restore();

# soft hyphens (Latin-1) and a couple of hard hyphens in DofI
my $DofIh = 
    "When in the course of hu\xADman events, it be-comes " . 
    "ne\xADces\xADsa\xADry for one peo\xADple to dis\xADsolve the " .
    "po\xADlit\xADi-cal bands which have here\xADto\xADfore " .
    "con\xADnect\xADed them with ano\xADther...";

@cellLoc = makeCellLoc(1); # skip to new page
# ----------------------------------------------------
# 27. text_fill() with soft hyphens and a couple of hard hyphens, no hyphenate
# no splitting of words
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

$i = $DofIh;
$text->translate($base[0]+15, $base[1]+105);
while ($i ne '') {
  ($lw, $i) = $text->text_fill($i, 140, -spillover=>0);
  $text->cr();
}

# caption
drawCaption(['Latin-1, hyph. off'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 28. text_fill() with soft hyphens and a couple of hard hyphens, do hyphenate
# splits at 3 soft hyphens
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

$i = $DofIh;
$text->translate($base[0]+15, $base[1]+105);
while ($i ne '') {
  ($lw, $i) = $text->text_fill($i, 140, -spillover=>0, -hyphenate=>1);
  $text->cr();
}

# caption
drawCaption(['Latin-1, SHY+hard'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 29. paragraph() with soft hyphens and a couple of hard hyphens, do hyphenate
#    and indent to force split at hard hyphen (also 1 soft hyphen)
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

$i = $DofIh;
$text->translate($base[0]+15, $base[1]+105);
($lw, $i) = $text->paragraph($i, 140,110, 0, -spillover=>0, -pndnt=>3.5, -hyphenate=>1 );

# caption
drawCaption(['Latin-1, ind frc new'], 'LC');

$grfx->restore();

# change $DofIh to UTF-8  SHYs should expand to C2AD internally, no visible chg.
$DofIh = Encode::decode('latin1', $DofIh);
# ----------------------------------------------------
# 30. text_fill() with soft hyphens and a couple of hard hyphens, no hyphenate
# no splitting of words
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

$i = $DofIh;
$text->translate($base[0]+15, $base[1]+105);
while ($i ne '') {
  ($lw, $i) = $text->text_fill($i, 140, -spillover=>0);
  $text->cr();
}

# caption
drawCaption(['UTF-8, hyph. off'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 31. text_fill() with soft hyphens and a couple of hard hyphens, do hyphenate
# splits at 3 soft hyphens
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

$i = $DofIh;
$text->translate($base[0]+15, $base[1]+105);
while ($i ne '') {
  ($lw, $i) = $text->text_fill($i, 140, -spillover=>0, -hyphenate=>1);
  $text->cr();
}

# caption
drawCaption(['UTF-8, SHY+hard'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 32. paragraph() with soft hyphens and a couple of hard hyphens, do hyphenate
#    and indent to force split at hard hyphen (also 1 soft hyphen)
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

$i = $DofIh;
$text->translate($base[0]+15, $base[1]+105);
($lw, $i) = $text->paragraph($i, 140,110, 0, -spillover=>0, -pndnt=>3.5, -hyphenate=>1 );

# caption
drawCaption(['UTF-8, ind frc new'], 'LC');

$grfx->restore();

my $nonsense = "HereAreLongCamelCaseWordsThatNeedToBeSplitUp." .
               "fdsfsdflf;dp-dflkjfad.df;ljgsdfdfl:dfd-0igabc1123456defgh!" .
	       "blahBlah/necch/necch/necch.";

# ----------------------------------------------------
# 33. paragraph() with punctuation, digit runs, and camelCase, do hyphenate
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

$i = $nonsense;
$text->translate($base[0]+15, $base[1]+105);
($lw, $i) = $text->paragraph($i, 140,110, 0, -spillover=>0, -pndnt=>0, -hyphenate=>1 );

# caption
drawCaption(['Latin-1 non-hyphen'], 'LC');

$grfx->restore();

# ----------------------------------------------------
# 34. paragraph() with punctuation, digit runs, and camelCase, do hyphenate
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

$i = $nonsense;
$text->translate($base[0]+15, $base[1]+105);
($lw, $i) = $text->paragraph($i, 140,110, 0, -spillover=>0, -pndnt=>-1.0, -hyphenate=>1 );

# caption
drawCaption(['Latin-1 non-hyphen, outd'], 'LC');

$grfx->restore();

# ----------------------------------------------------
$pdf->saveas($PDFname);

# =====================================================================
sub colors {
  my $color = shift;
  $grfx->strokecolor($color);
  $grfx->fillcolor($color);
  $text->strokecolor($color);
  $text->fillcolor($color);
  return;
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
  $text->text_center($pageNo); # prefill page number before any other content
  return;
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
  return;
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
  return;
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
  return;
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

  $y=20; # shut up perlcritic
  for ($i=0; $i<@captions; $i++) {
    # $just = LC
    $text->translate($cellLoc[0]+$cellSize[0]/2-$width/2, $cellLoc[1]-$y);
    $text->text($captions[$i]);
    $y+=13; # shut up perlcritic
  }
  return;
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
