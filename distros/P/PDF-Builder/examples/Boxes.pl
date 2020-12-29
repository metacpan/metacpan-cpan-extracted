#!/usr/bin/perl

# demonstrate uses of PDF boxes
# outputs Boxes.pdf
# author: Phil M Perry

use strict;
use warnings;
use PDF::Builder;

use constant in => 1 / 72;  # e.g., 3.5/in for 3.5 inch dimension
use constant cm => 2.54 / 72; 
use constant mm => 25.4 / 72;
use constant pt => 1;

my @dual_format = (800, 600); 
my $live_format = 'letter';  # or A4
my $fontname = 'TimesRoman';

my $trimbox_adj = 1/mm;  # in from bleed box
my $bleedbox_adj = 36/pt;  # in from crop box on top and right for printer inst.
my $cropbox_adj = 0.25/in;  # in from media edge

our $VERSION = '3.021'; # VERSION
my $LAST_UPDATE = '3.017'; # manually update whenever code is changed

my $PDFname = $0;
   $PDFname =~ s/\..*$//;  # remove extension such as .pl
   $PDFname .= '.pdf';     # add new extension .pdf

my $pdf = PDF::Builder->new(-compress => 'none');
my $font = $pdf->corefont($fontname);
my $fontH = $pdf->corefont('Helvetica'); # for headline
my ($page, $grfx, $text, $clip); # semi-globals

media_page('dual');
page_content('dual');
crop_page('dual');
bleed_page('dual');
printer_page('dual');
trim_page('dual');
art_page('dual');

media_page('live');
page_content('live');
crop_page('live');
bleed_page('live');
printer_page('live');
trim_page('live');
art_page('live');

$pdf->saveas($PDFname);

##################################################### subroutines

# --------------- define the media

sub media_page {
	my $mode = shift();

	$page = $pdf->page();
	$grfx = $page->gfx();
	$text = $page->text(); # text always overlays graphics

	if ($mode eq 'dual') {
		$page->mediabox(@dual_format);
		my @size = (0,0, @dual_format);
		media_layer($mode, $grfx, @size);

		$text->fillcolor('black');
		$text->font($font, 20);
		$text->translate(400,550);
		$text->text_center('Set the "paper" (media) size and coordinate system.');
	} else {
		my @size = $page->mediabox($live_format);
		media_layer($mode, $grfx, @size);
		$text->font($font, 20);
		$text->translate($size[2]/2, $size[3]-100);
		$text->text_center("A page (media) of size '$live_format'");
		$text->translate($size[2]/2, $size[3]-130);
		$text->text_center("Lower left ($size[0],$size[1]) to upper right ($size[2],$size[3])");
	}

	return;
}

sub media_layer {
	my ($mode, $grfx, @size) = @_;

	if ($mode eq 'dual') {
		# mint background, two generic page outlines
		$grfx->fillcolor('#E4EFC9');
		$grfx->rectxy(@size);
		$grfx->fill();

		$grfx->fillcolor('white');
		$grfx->rectxy(50,50, 375,500);
		$grfx->fill();
		$grfx->rectxy(425,50, 750,500);
		$grfx->fill();
	}
	# nothing for live
	
	return;
}

# --------------- add content to the pages

sub page_content {
	my $mode = shift();

	$page = $pdf->page();
	$grfx = $page->gfx();
	$text = $page->text(); # text always overlays graphics
	$clip = $page->gfx();  # clip (graphics) overlays text

	if ($mode eq 'dual') {
		$page->mediabox(@dual_format);
		my @size = (0,0, @dual_format);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);

		$text->fillcolor('black');
		$text->font($font, 20);
		$text->translate(400,550);
		$text->text_center('Add graphics and text content.');
		$text->translate(400,525);
		$text->text_center('Note that output auto trimmed to media and paper rollers.');
		# emulate appropriate clipping (just left and right)
		$clip->fillcolor('#E4EFC9');
		$clip->rectxy(405/pt,40/pt, 425/pt,510/pt); 
		$clip->fill();
		$clip->rectxy(750/pt,40/pt, 775/pt,510/pt);
		$clip->fill();
		$clip->fillcolor('gray');
		$clip->rectxy(425/pt,50/pt, 428/pt,500/pt);
		$clip->fill();
		$clip->rectxy(747/pt,50/pt, 750/pt,500/pt);
		$clip->fill();
	} else {
		my @size = $page->mediabox($live_format);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);
		$clip->fillcolor('gray');
		$clip->rectxy(0,0, 3/pt,$size[3]);
		$clip->fill();
		$clip->rectxy($size[2]-3/pt,0, $size[2],$size[3]);
		$clip->fill();
	}

	return;
}

sub content_layer {
	my ($mode, $grfx, $text, @size) = @_;

	if ($mode eq 'dual') {
		# left hand page unclipped
		the_content($mode, $grfx, $text, 50,50, 375,500);

		# right hand page clipped to media and paper handling
		# (3 pt on sides here)
		the_content($mode, $grfx, $text, 425,50, 750,500);
	} else {
		# page clipped to media and paper handling
		# (3 pt on sides here)
		the_content($mode, $grfx, $text, @size);
	}

	return;
}

sub the_content {
	my ($mode, $grfx, $text, @size) = @_;
	my ($width,$height, $x1,$y1, $x2,$y2);

	my $fontsize = ($mode eq 'dual')? 12: 24;
	
# Lorem Ipsum text, borrowed from examples/ContentText.pl, including newlines
# to mark end of paragraphs.
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

	# size[0 1]..size[2 3] is media where to draw graphics and text content
	# left page will go over its boundaries in one case!
	
	# the headline box (to bleed box)
	$grfx->fillcolor('blue');
	# top, left, and right to bleedbox
	$x1 = $size[0] + $cropbox_adj + 0;
	$x2 = $size[2] - $cropbox_adj - $bleedbox_adj;
	$height = (($mode eq 'single')?2.5:1)*25/pt;
	$y2 = $size[3] - $cropbox_adj - $bleedbox_adj;
	$y1 = $y2 - $height;
	$grfx->rectxy($x1,$y1, $x2,$y2);
	$grfx->fill();
	$text->font($fontH, 20/pt);
	$text->fillcolor('white');
	$text->translate($x2 - $trimbox_adj - 5/pt,
	         	 $y1 + 3/pt);
	$text->text_right("The Headline");
	
	# a well-behaved red separator line to bleed box
	$grfx->strokecolor('red');
	$width = $mode eq 'single'? 3: 1.5; # line width
	$grfx->linewidth($width);
	$grfx->poly($x1,$y1-$width/2, $x2,$y1-$width/2);
	$grfx->stroke();
	$y1 -= $width;
	
	# the text and background box exceeding media width
	$grfx->fillcolor('green');
	$y1 -= 15/pt; $y2 = $y1 + 10/pt;
	$grfx->rectxy($size[0]-7/pt,$y1, $size[2]+7/pt,$y2);
	$grfx->fill();
        $text->fillcolor('white');
	$text->font($fontH, 8/pt);
	$text->translate(($size[0]+$size[2])/2, $y1+2/pt);
	$text->fillcolor('#E4EFC9');
	if ($mode eq 'dual') {
		$text->text_center("This text is so long that it exceeds the media width and will be cropped by media box and printer.");
	} else {
		$text->text_center("This text is so long that it exceeds the media width and will be cropped by media box and printer. And here is incredibly even more text to extend the line on a single page format example.");
	}
	
	# the diagonal line exceeding media size
	$grfx->strokecolor('purple');
	$grfx->linewidth(1);
	$grfx->poly($size[0]-7/pt,$y1, $size[2]+7/pt,$size[1]-4/pt);
	$grfx->stroke();
	
	# a line to media edge
	$grfx->strokecolor('yellow');
	$width = $mode eq 'single'? 3: 1.5; # line width
	$grfx->linewidth($width);
	$y1 -= 5/pt; $y2 = $y1;
	$grfx->poly($size[0],$y1, $size[2],$y2);
	$grfx->stroke();
	$y1 -= 3*$width;
	
	# some Lorem Ipsum text within trim box and a margin
	$text->fillcolor('black');
	$text->font($font, $fontsize);
        $text->lead($fontsize * 1.25);
	$x1 += $trimbox_adj + 4/pt;
	$y1 -= 5/pt + $fontsize/pt;  # top baseline less one line
	$x2 -= $trimbox_adj + 4/pt;
	$text->translate($x1, $y1);
	my $cont = 0;
	my $unused;
	($LoremIpsum, $cont, $unused) = $text->section($LoremIpsum,
		$x2 - $x1, $y1 - $size[1] - 3/pt - $fontsize*1.25, $cont,
		-spillover => 0, -align => 'justify',
		-pndnt => 2, -pvgap => 4 );
	
	return;
}

# --------------- crop the pages to what printer can output
#                 let's say 1/4 inch off each edge (probably too much)

sub crop_page {
	my $mode = shift();

	$page = $pdf->page();
	$grfx = $page->gfx();
	$text = $page->text(); # text always overlays graphics
	$clip = $page->gfx();  # clip (graphics) overlays text

	if ($mode eq 'dual') {
		$page->mediabox(@dual_format);
		my @size = (0,0, @dual_format);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);

		$text->fillcolor('black');
		$text->font($font, 20);
		$text->translate(400,550);
		$text->text_center('Set crop box 1/4 inch all around.');
		$text->translate(400,525);
		$text->text_center('Probably excessive for most printers.');
		# draw crop box on left page
		$grfx->strokecolor('black');
		$grfx->linewidth(1);
		$grfx->linedash(3);
		$grfx->poly(40/pt,50/pt+$cropbox_adj, 385/pt,50/pt+$cropbox_adj);
		$grfx->poly(40/pt,500/pt-$cropbox_adj, 385/pt,500/pt-$cropbox_adj);
		$grfx->poly(50/pt+$cropbox_adj,40/pt, 50/pt+$cropbox_adj,510/pt);
		$grfx->poly(375/pt-$cropbox_adj,40/pt, 375/pt-$cropbox_adj,510/pt);
		$grfx->stroke();
		$grfx->linedash();
		# emulate appropriate clipping 
		$clip->fillcolor('#E4EFC9');
		$clip->rectxy(405/pt,40/pt, 425/pt,510/pt); 
		$clip->fill();
		$clip->rectxy(750/pt,40/pt, 775/pt,510/pt);
		$clip->fill();
		$clip->fillcolor('gray');
		$clip->rectxy(425/pt,50/pt, 425/pt+$cropbox_adj,500/pt);
		$clip->fill();
		$clip->rectxy(750/pt-$cropbox_adj,50/pt, 750/pt,500/pt);
		$clip->fill();
		$clip->rectxy(425/pt,50/pt, 750/pt,50/pt+$cropbox_adj);
		$clip->fill();
		$clip->rectxy(425/pt,500/pt-$cropbox_adj, 750/pt,500/pt);
		$clip->fill();
	} else {
		my @size = $page->mediabox($live_format);
		$page->cropbox($size[0]+$cropbox_adj,
			       $size[1]+$cropbox_adj,
			       $size[2]-$cropbox_adj,
			       $size[3]-$cropbox_adj);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);
		# ->cropbox() should actually trim content
	}

	return;
}

# --------------- set bleed box: no visible effect

sub bleed_page {
	my $mode = shift();

	$page = $pdf->page();
	$grfx = $page->gfx();
	$text = $page->text(); # text always overlays graphics
	$clip = $page->gfx();  # clip (graphics) overlays text

	if ($mode eq 'dual') {
		$page->mediabox(@dual_format);
		my @size = (0,0, @dual_format);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);

		$text->fillcolor('black');
		$text->font($font, 20);
		$text->translate(400,550);
		$text->text_center('Set bleed box bottom and left at crop,');
		$text->translate(400,525);
		$text->text_center('just outside trim box on top and right.');
		# draw crop box on left page in gray
		$grfx->linewidth(1);
		$grfx->linedash(3);
		$grfx->strokecolor('black'); # shared with bleed box
		$grfx->poly(40/pt,50/pt+$cropbox_adj, 385/pt,50/pt+$cropbox_adj);
		$grfx->stroke();
		$grfx->strokecolor('#CCC');
		$grfx->poly(50/pt,500/pt-$cropbox_adj, 375/pt,500/pt-$cropbox_adj);
		$grfx->stroke();
		$grfx->strokecolor('black'); # shared with bleed box
		$grfx->poly(50/pt+$cropbox_adj,40/pt, 50/pt+$cropbox_adj,510/pt);
		$grfx->stroke();
		$grfx->strokecolor('#CCC');
		$grfx->poly(375/pt-$cropbox_adj,50/pt, 375/pt-$cropbox_adj,500/pt);
		$grfx->stroke();
		# now bleed box in black on left page (shares left and bottom)
		$grfx->strokecolor('black');
		$grfx->poly(40/pt,500/pt-$cropbox_adj-$bleedbox_adj, 385/pt,500/pt-$cropbox_adj-$bleedbox_adj);
		$grfx->poly(375/pt-$cropbox_adj-$bleedbox_adj,40/pt, 375/pt-$cropbox_adj-$bleedbox_adj,510/pt);
		$grfx->stroke();
		$grfx->linedash();
		# emulate appropriate clipping 
		# no additional content removed by bleed box
		$clip->fillcolor('#E4EFC9');
		$clip->rectxy(405/pt,40/pt, 425/pt,510/pt); 
		$clip->fill();
		$clip->rectxy(750/pt,40/pt, 775/pt,510/pt);
		$clip->fill();
		$clip->fillcolor('gray');
		$clip->rectxy(425/pt,50/pt, 425/pt+$cropbox_adj,500/pt);
		$clip->fill();
		$clip->rectxy(750/pt-$cropbox_adj,50/pt, 750/pt,500/pt);
		$clip->fill();
		$clip->rectxy(425/pt,50/pt, 750/pt,50/pt+$cropbox_adj);
		$clip->fill();
		$clip->rectxy(425/pt,500/pt-$cropbox_adj, 750/pt,500/pt);
		$clip->fill();
	} else {
		my @size = $page->mediabox($live_format);
		$page->cropbox($size[0]+$cropbox_adj,
			       $size[1]+$cropbox_adj,
			       $size[2]-$cropbox_adj,
			       $size[3]-$cropbox_adj);
		$page->bleedbox($size[0]+$cropbox_adj,
			       $size[1]+$cropbox_adj,
			       $size[2]-$cropbox_adj-$bleedbox_adj,
			       $size[3]-$cropbox_adj-$bleedbox_adj);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);
		# ->cropbox() should actually trim content
	}

	return;
}

# --------------- add some printer instructions: crop marks, color alignment

sub printer_page {
	my $mode = shift();

	$page = $pdf->page();
	$grfx = $page->gfx();
	$text = $page->text(); # text always overlays graphics
	$clip = $page->gfx();  # clip (graphics) overlays text

	if ($mode eq 'dual') {
		$page->mediabox(@dual_format);
		my @size = (0,0, @dual_format);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);

		$text->fillcolor('black');
		$text->font($font, 20);
		$text->translate(400,550);
		$text->text_center('Add some printer instructions, crop marks,');
		$text->translate(400,525);
		$text->text_center('and color alignment dots.');
		# draw crop box on left page in gray
		$grfx->linewidth(1);
		$grfx->linedash(3);
		$grfx->strokecolor('black'); # shared with bleed box
		$grfx->poly(40/pt,50/pt+$cropbox_adj, 385/pt,50/pt+$cropbox_adj);
		$grfx->stroke();
		$grfx->strokecolor('#CCC');
		$grfx->poly(50/pt,500/pt-$cropbox_adj, 375/pt,500/pt-$cropbox_adj);
		$grfx->stroke();
		$grfx->strokecolor('black'); # shared with bleed box
		$grfx->poly(50/pt+$cropbox_adj,40/pt, 50/pt+$cropbox_adj,510/pt);
		$grfx->stroke();
		$grfx->strokecolor('#CCC');
		$grfx->poly(375/pt-$cropbox_adj,50/pt, 375/pt-$cropbox_adj,500/pt);
		$grfx->stroke();
		# now bleed box in black on left page (shares left and bottom)
		$grfx->strokecolor('black');
		$grfx->poly(40/pt,500/pt-$cropbox_adj-$bleedbox_adj, 385/pt,500/pt-$cropbox_adj-$bleedbox_adj);
		$grfx->poly(375/pt-$cropbox_adj-$bleedbox_adj,40/pt, 375/pt-$cropbox_adj-$bleedbox_adj,510/pt);
		$grfx->stroke();
		$grfx->linedash();
		# emulate appropriate clipping 
		# no additional content removed by bleed box
		$clip->fillcolor('#E4EFC9');
		$clip->rectxy(405/pt,40/pt, 425/pt,510/pt); 
		$clip->fill();
		$clip->rectxy(750/pt,40/pt, 775/pt,510/pt);
		$clip->fill();
		$clip->fillcolor('gray');
		$clip->rectxy(425/pt,50/pt, 425/pt+$cropbox_adj,500/pt);
		$clip->fill();
		$clip->rectxy(750/pt-$cropbox_adj,50/pt, 750/pt,500/pt);
		$clip->fill();
		$clip->rectxy(425/pt,50/pt, 750/pt,50/pt+$cropbox_adj);
		$clip->fill();
		$clip->rectxy(425/pt,500/pt-$cropbox_adj, 750/pt,500/pt);
		$clip->fill();
		printer_marks($mode, $text, $grfx, 50,50, 375,500);
		printer_marks($mode, $text, $grfx, 425,50, 750,500);

	} else {
		my @size = $page->mediabox($live_format);
		$page->cropbox($size[0]+$cropbox_adj,
			       $size[1]+$cropbox_adj,
			       $size[2]-$cropbox_adj,
			       $size[3]-$cropbox_adj);
		$page->bleedbox($size[0]+$cropbox_adj,
			       $size[1]+$cropbox_adj,
			       $size[2]-$cropbox_adj-$bleedbox_adj,
			       $size[3]-$cropbox_adj-$bleedbox_adj);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);
		# ->cropbox() should actually trim content
		printer_marks($mode, $text, $grfx, @size);
	}

	return;
}

sub printer_marks {
	my ($mode, $text, $grfx, @size) = @_;
	my $width = 3/pt;
	my ($x,$y, $xc,$yc);

	# add some printing instructions
	$text->font($fontH, 15);
	$text->fillcolor('black');
	$text->translate(($size[0]+$size[2])/2, $size[3]/pt-40/pt);
	$text->text_center("Print on 20-24 LB clay-coat");

	# and crop marks just outside the trim box
	$grfx->strokecolor('brown');
	$grfx->linewidth($width);

	$x = $size[0] + $cropbox_adj + $trimbox_adj - $width/2; # lower left
	$y = $size[1] + $cropbox_adj + $trimbox_adj - $width/2;
	$grfx->move($x,$y - 5/pt);
	$grfx->vline($y - 5/pt + 20/pt);
	$grfx->move($x - 5/pt,$y);
	$grfx->hline($x - 5/pt + 20/pt);

	$x = $size[0] + $cropbox_adj + $trimbox_adj - $width/2; # upper left
	$y = $size[3] - $cropbox_adj - $bleedbox_adj - $trimbox_adj + $width/2;
	$grfx->move($x,$y + 5/pt);
	$grfx->vline($y + 5/pt - 20/pt);
	$grfx->move($x - 5/pt,$y);
	$grfx->hline($x - 5/pt + 20/pt);

	$x = $size[2] - $cropbox_adj - $bleedbox_adj - $trimbox_adj + $width/2; # upper right
	$y = $size[3] - $cropbox_adj - $bleedbox_adj - $trimbox_adj + $width/2;
	$grfx->move($x,$y + 5/pt);
	$grfx->vline($y + 5/pt - 20/pt);
	$grfx->move($x + 5/pt,$y);
	$grfx->hline($x + 5/pt - 20/pt);

	$x = $size[2] - $cropbox_adj - $bleedbox_adj - $trimbox_adj + $width/2; # lower right
	$y = $size[1] + $cropbox_adj + $trimbox_adj - $width/2;
	$grfx->move($x,$y - 5/pt);
	$grfx->vline($y - 5/pt + 20/pt);
	$grfx->move($x + 5/pt,$y);
	$grfx->hline($x + 5/pt - 20/pt);

	$grfx->stroke();

	# and some color alignment dots
	$xc = $size[2] - $cropbox_adj - $bleedbox_adj/2;
	$yc = ($size[1] + $size[3])/2 + 10/pt;

	$grfx->strokecolor('black');
	$grfx->linewidth(1);
	$grfx->fillcolor('black');
	$grfx->circle($xc, $yc, 10/pt);
        $grfx->fill();
	$grfx->poly($xc - 12/pt, $yc, $xc + 12/pt, $yc);
	$grfx->poly($xc, $yc + 12/pt, $xc, $yc - 12/pt);
	$grfx->stroke();
	$yc -= 35/pt;
	$grfx->fillcolor('yellow');
	$grfx->circle($xc, $yc, 10/pt);
        $grfx->fill();
	$grfx->poly($xc - 12/pt, $yc, $xc + 12/pt, $yc);
	$grfx->poly($xc, $yc + 12/pt, $xc, $yc - 12/pt);
	$grfx->stroke();
	$yc -= 35/pt;
	$grfx->fillcolor('magenta');
	$grfx->circle($xc, $yc, 10/pt);
        $grfx->fill();
	$grfx->poly($xc - 12/pt, $yc, $xc + 12/pt, $yc);
	$grfx->poly($xc, $yc + 12/pt, $xc, $yc - 12/pt);
	$grfx->stroke();
	$yc -= 35/pt;
	$grfx->fillcolor('cyan');
	$grfx->circle($xc, $yc, 10/pt);
        $grfx->fill();
	$grfx->poly($xc - 12/pt, $yc, $xc + 12/pt, $yc);
	$grfx->poly($xc, $yc + 12/pt, $xc, $yc - 12/pt);
	$grfx->stroke();
	
	return;
}

# --------------- set trim box: emulate effect of paper being cut

sub trim_page {
	my $mode = shift();

	$page = $pdf->page();
	$grfx = $page->gfx();
	$text = $page->text(); # text always overlays graphics
	$clip = $page->gfx();  # clip (graphics) overlays text

	if ($mode eq 'dual') {
		$page->mediabox(@dual_format);
		my @size = (0,0, @dual_format);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);

		$text->fillcolor('black');
		$text->font($font, 20);
		$text->translate(400,550);
		$text->text_center('Set trim box to final paper size.');
		$text->translate(400,525);
		$text->text_center('Won\'t see anything until paper is actually cut.');
		# draw crop box on left page in light gray
		$grfx->linewidth(1);
		$grfx->linedash(3);
		$grfx->strokecolor('#999'); # shared with bleed box
		$grfx->poly(50/pt,50/pt+$cropbox_adj, 375/pt,50/pt+$cropbox_adj);
		$grfx->stroke();
		$grfx->strokecolor('#CCC');
		$grfx->poly(50/pt,500/pt-$cropbox_adj, 375/pt,500/pt-$cropbox_adj);
		$grfx->stroke();
		$grfx->strokecolor('#999'); # shared with bleed box
		$grfx->poly(50/pt+$cropbox_adj,50/pt, 50/pt+$cropbox_adj,500/pt);
		$grfx->stroke();
		$grfx->strokecolor('#CCC');
		$grfx->poly(375/pt-$cropbox_adj,50/pt, 375/pt-$cropbox_adj,500/pt);
		$grfx->stroke();
		# now bleed box in med gray on left page (shares left and bottom)
		$grfx->strokecolor('#999');
		$grfx->poly(50/pt,500/pt-$cropbox_adj-$bleedbox_adj, 375/pt,500/pt-$cropbox_adj-$bleedbox_adj);
		$grfx->poly(375/pt-$cropbox_adj-$bleedbox_adj,50/pt, 375/pt-$cropbox_adj-$bleedbox_adj,500/pt);
		$grfx->stroke();
		# now trim box in black
		$grfx->strokecolor('black'); 
		$grfx->poly(40/pt,50/pt+$cropbox_adj+$trimbox_adj, 385/pt,50/pt+$cropbox_adj+$trimbox_adj);
		$grfx->poly(40/pt,500/pt-$cropbox_adj-$bleedbox_adj-$trimbox_adj, 385/pt,500/pt-$cropbox_adj-$bleedbox_adj-$trimbox_adj);
		$grfx->poly(50/pt+$cropbox_adj+$trimbox_adj,40/pt, 50/pt+$cropbox_adj+$trimbox_adj,510/pt);
		$grfx->poly(375/pt-$cropbox_adj-$bleedbox_adj-$trimbox_adj,40/pt, 375/pt-$cropbox_adj-$bleedbox_adj-$trimbox_adj,510/pt);
		$grfx->stroke();
		$grfx->linedash();
		# emulate appropriate clipping 
		# no additional content removed by bleed box
		$clip->fillcolor('#E4EFC9');
		$clip->rectxy(405/pt,40/pt, 425/pt,510/pt); 
		$clip->rectxy(750/pt,40/pt, 775/pt,510/pt);
		$clip->fill();
		$clip->fillcolor('gray');
		$clip->rectxy(425/pt,50/pt, 425/pt+$cropbox_adj+$trimbox_adj,500/pt);
		$clip->rectxy(750/pt-$cropbox_adj-$bleedbox_adj-$trimbox_adj,50/pt, 750/pt,500/pt);
		$clip->rectxy(425/pt,50/pt, 750/pt,50/pt+$cropbox_adj+$trimbox_adj);
		$clip->rectxy(425/pt,500/pt-$cropbox_adj-$bleedbox_adj-$trimbox_adj, 750/pt,500/pt);
		$clip->fill();
		printer_marks($mode, $text, $grfx, 50,50, 375,500);
		printer_marks($mode, $text, $grfx, 425,50, 750,500);
	} else {
		my @size = $page->mediabox($live_format);
		#$page->cropbox($size[0]+$cropbox_adj,
		#	       $size[1]+$cropbox_adj,
		#	       $size[2]-$cropbox_adj,
		#	       $size[3]-$cropbox_adj);
		#$page->bleedbox($size[0]+$cropbox_adj,
		#	       $size[1]+$cropbox_adj,
		#	       $size[2]-$cropbox_adj-$bleedbox_adj,
		#	       $size[3]-$cropbox_adj-$bleedbox_adj);
		# just emulate trimmed paper with small crop box
		$page->cropbox($size[0]+$cropbox_adj+$trimbox_adj,
			       $size[1]+$cropbox_adj+$trimbox_adj,
			       $size[2]-$cropbox_adj-$bleedbox_adj-$trimbox_adj,
			       $size[3]-$cropbox_adj-$bleedbox_adj-$trimbox_adj);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);
		# ->cropbox() should actually trim content
		printer_marks($mode, $text, $grfx, @size);
	}

	return;
}

# --------------- set art box

sub art_page {
	my $mode = shift();

	$page = $pdf->page();
	$grfx = $page->gfx();
	$text = $page->text(); # text always overlays graphics
	$clip = $page->gfx();  # clip (graphics) overlays text

	if ($mode eq 'dual') {
		$page->mediabox(@dual_format);
		my @size = (0,0, @dual_format);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);

		$text->fillcolor('black');
		$text->font($font, 20);
		$text->translate(400,550);
		$text->text_center('Set art box. No visible effect.');
		# draw crop box on left page in light gray
		$grfx->linewidth(1);
		$grfx->linedash(3);
		$grfx->strokecolor('#BBB'); # shared with bleed box
		$grfx->poly(50/pt,50/pt+$cropbox_adj, 375/pt,50/pt+$cropbox_adj);
		$grfx->stroke();
		$grfx->strokecolor('#EEE');
		$grfx->poly(50/pt,500/pt-$cropbox_adj, 375/pt,500/pt-$cropbox_adj);
		$grfx->stroke();
		$grfx->strokecolor('#BBB'); # shared with bleed box
		$grfx->poly(50/pt+$cropbox_adj,50/pt, 50/pt+$cropbox_adj,500/pt);
		$grfx->stroke();
		$grfx->strokecolor('#EEE');
		$grfx->poly(375/pt-$cropbox_adj,50/pt, 375/pt-$cropbox_adj,500/pt);
		$grfx->stroke();
		# now bleed box in med gray on left page (shares left and bottom)
		$grfx->strokecolor('#BBB');
		$grfx->poly(50/pt,500/pt-$cropbox_adj-$bleedbox_adj, 375/pt,500/pt-$cropbox_adj-$bleedbox_adj);
		$grfx->poly(375/pt-$cropbox_adj-$bleedbox_adj,50/pt, 375/pt-$cropbox_adj-$bleedbox_adj,500/pt);
		$grfx->stroke();
		# now trim box in dark gray for top, black for others
		# (shared with art box)
		$grfx->strokecolor('#999'); 
		$grfx->poly(50/pt,500/pt-$cropbox_adj-$bleedbox_adj-$trimbox_adj, 375/pt,500/pt-$cropbox_adj-$bleedbox_adj-$trimbox_adj);
		$grfx->stroke();
		$grfx->strokecolor('black'); 
		$grfx->poly(40/pt,50/pt+$cropbox_adj+$trimbox_adj, 385/pt,50/pt+$cropbox_adj+$trimbox_adj);
		$grfx->poly(50/pt+$cropbox_adj+$trimbox_adj,40/pt, 50/pt+$cropbox_adj+$trimbox_adj,510/pt);
		$grfx->poly(375/pt-$cropbox_adj-$bleedbox_adj-$trimbox_adj,40/pt, 375/pt-$cropbox_adj-$bleedbox_adj-$trimbox_adj,510/pt);
		# art box in black. only top is different from trim box
		$grfx->poly(40/pt,500/pt-110/pt, 385/pt,500/pt-110/pt);
		$grfx->stroke();
		$grfx->linedash();
		# emulate appropriate clipping 
		# no additional content removed by art box
		$clip->fillcolor('#E4EFC9');
		$clip->rectxy(405/pt,40/pt, 425/pt,510/pt); 
		$clip->rectxy(750/pt,40/pt, 775/pt,510/pt);
		$clip->fill();
		$clip->fillcolor('gray');
		$clip->rectxy(425/pt,50/pt, 425/pt+$cropbox_adj+$trimbox_adj,500/pt);
		$clip->rectxy(750/pt-$cropbox_adj-$bleedbox_adj-$trimbox_adj,50/pt, 750/pt,500/pt);
		$clip->rectxy(425/pt,50/pt, 750/pt,50/pt+$cropbox_adj+$trimbox_adj);
		$clip->rectxy(425/pt,500/pt-110/pt, 750/pt,500/pt);
		$clip->fill();
		printer_marks($mode, $text, $grfx, 50,50, 375,500);
		printer_marks($mode, $text, $grfx, 425,50, 750,500);
	} else {
		my @size = $page->mediabox($live_format);
		#$page->cropbox($size[0]+$cropbox_adj,
		#	       $size[1]+$cropbox_adj,
		#	       $size[2]-$cropbox_adj,
		#	       $size[3]-$cropbox_adj);
		#$page->bleedbox($size[0]+$cropbox_adj,
		#	       $size[1]+$cropbox_adj,
		#	       $size[2]-$cropbox_adj-$bleedbox_adj,
		#	       $size[3]-$cropbox_adj-$bleedbox_adj);
		# just emulate trimmed paper with small crop box
		$page->cropbox($size[0]+$cropbox_adj+$trimbox_adj,
			       $size[1]+$cropbox_adj+$trimbox_adj,
			       $size[2]-$cropbox_adj-$bleedbox_adj-$trimbox_adj,
			       $size[3]-110/pt);
		media_layer($mode, $grfx, @size);
		content_layer($mode, $grfx, $text, @size);
		# ->cropbox() should actually trim content
		printer_marks($mode, $text, $grfx, @size);
	}

	return;
}

