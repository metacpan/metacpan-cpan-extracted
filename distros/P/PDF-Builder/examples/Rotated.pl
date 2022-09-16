#!/usr/bin/perl
# demonstrate a page of portrait-mode text, followed by a two-page spread
# rotated content, and finally back to portrait mode for a last page.
# outputs Rotated.pdf
# author: Phil M Perry

use warnings;
use strict;

our $VERSION = '3.024'; # VERSION
our $LAST_UPDATE = '3.023'; # manually update whenever code is changed

use PDF::Builder;

my $PDFname = $0;
   $PDFname =~ s/\..*$//;  # remove extension
   $PDFname .= '.pdf';     # add new extension
my $pgsize = 'letter';  # A4, universal also good choices

my $marginTop = 72;  # points
my $marginBot = 72;
my $outerMargin = 72;
my $innerMargin = 144; # includes binding area
my $gutter = 54;  # for rotated two column
my $fontsize = 15;

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

my ($page, $text, $width, $height, $unused, $cont, $contR, 
	$txt, $txtR, %margins);
$txtR = $txt = "$LoremIpsum\n$LoremIpsum"; # ensure plenty of text

my $pdf = PDF::Builder->new();
$pdf->mediabox($pgsize);
my @pageDim = $pdf->mediabox();

my $font = $pdf->corefont('Times-Roman');

# page 1 (portrait, right hand) =====================================
$page = $pdf->page();
$text = $page->text();
$text->font($font, $fontsize);
$text->leading($fontsize*1.25);

$width = $pageDim[2];
$height = $pageDim[3];
$margins{'T'} = $marginTop;
$margins{'B'} = $marginBot;
$margins{'L'} = $innerMargin;
$margins{'R'} = $outerMargin;

$cont = 0;
# single column, full width of page
$text->translate($margins{'L'}, $height-$margins{'T'}-$fontsize);
($txt, $cont, $unused) = $text->section($txt, 
	  $width-$margins{'L'}-$margins{'R'},
	  $height-$margins{'T'}-$margins{'B'}, $cont,
	  -spillover=>0, -align => 'justify', -pndnt => 2, -pvgap => 4 );
# expect $txt to have around a page left over (for page 4)

# heading, footing
$text->translate(($width+$margins{'L'}-$margins{'R'})/2,
	         $height-$margins{'T'}/2);
$text->text_center('Lorem Ipsum');
$text->translate(($width+$margins{'L'}-$margins{'R'})/2,
	         ($margins{'B'}-$fontsize)/2);
$text->text_center('-- 1 --');

# page 2 landscape, top =====================================
$page = $pdf->page();

$width = $pageDim[3];
$height = $pageDim[2];
$page->mediabox(0,0, $width,$height); # landscape
$margins{'T'} = $outerMargin;
$margins{'B'} = $innerMargin;
$margins{'L'} = $marginBot;
$margins{'R'} = $marginTop;

$text = $page->text();
$text->font($font, $fontsize);
$text->leading($fontsize*1.25);

$contR = 0;
# two columns, half width of page
$text->translate($margins{'L'}, $height-$margins{'T'}-$fontsize);
($txtR, $contR, $unused) = $text->section($txtR, 
	  ($width-$margins{'L'}-$margins{'R'}-$gutter)/2,
	  $height-$margins{'T'}-$margins{'B'}, $contR,
	  -spillover=>0, -align => 'justify', -pndnt => 2, -pvgap => 4 );
$text->translate(($width+$margins{'L'}-$margins{'R'}+$gutter)/2, 
	  $height-$margins{'T'}-$fontsize);
($txtR, $contR, $unused) = $text->section($txtR, 
	  ($width-$margins{'L'}-$margins{'R'}-$gutter)/2,
	  $height-$margins{'T'}-$margins{'B'}, $contR,
	  -spillover=>0, -align => 'justify', -pndnt => 2, -pvgap => 4 );

# heading, footing (unrotated)
$text->transform(-translate => [$width-$margins{'R'}/2-$fontsize,
		                0.5*($height-$margins{'T'}+$margins{'B'})], 
	         -rotate => -90);
$text->text_center('The Sequel');
$text->transform(-translate => [$margins{'L'}/2,
		                0.5*($height-$margins{'T'}+$margins{'B'})], 
	         -rotate => -90);
$text->text_center('-- 2 --');

# page 3 landscape, bottom =====================================
$page = $pdf->page();

$width = $pageDim[3];
$height = $pageDim[2];
$page->mediabox(0,0, $width,$height); # landscape
$margins{'T'} = $innerMargin;
$margins{'B'} = $outerMargin;
$margins{'L'} = $marginBot;
$margins{'R'} = $marginTop;

$text = $page->text();
$text->font($font, $fontsize);
$text->leading($fontsize*1.25);

# two columns, half width of page
$text->translate($margins{'L'}, $height-$margins{'T'}-$fontsize);
($txtR, $contR, $unused) = $text->section($txtR, 
	  ($width-$margins{'L'}-$margins{'R'}-$gutter)/2,
	  $height-$margins{'T'}-$margins{'B'}, $contR,
	  -spillover=>0, -align => 'justify', -pndnt => 2, -pvgap => 4 );
$text->translate(($width+$margins{'L'}-$margins{'R'}+$gutter)/2, 
	  $height-$margins{'T'}-$fontsize);
($txtR, $contR, $unused) = $text->section($txtR, 
	  ($width-$margins{'L'}-$margins{'R'}-$gutter)/2,
	  $height-$margins{'T'}-$margins{'B'}, $contR,
	  -spillover=>0, -align => 'justify', -pndnt => 2, -pvgap => 4 );

# heading, footing (unrotated)
$text->transform(-translate => [$width-$margins{'R'}/2-$fontsize,
		                0.5*($height-$margins{'T'}+$margins{'B'})], 
	         -rotate => -90);
$text->text_center('Lorem Ipsum');
$text->transform(-translate => [$margins{'L'}/2,
		                0.5*($height-$margins{'T'}+$margins{'B'})], 
	         -rotate => -90);
$text->text_center('-- 3 --');

# page 4 (portrait, left hand) =====================================
$page = $pdf->page();
$text = $page->text();
$text->font($font, $fontsize);
$text->leading($fontsize*1.25);

$width = $pageDim[2];
$height = $pageDim[3];
$margins{'T'} = $marginTop;
$margins{'B'} = $marginBot;
$margins{'L'} = $outerMargin;
$margins{'R'} = $innerMargin;

# single column, full width of page
$text->translate($margins{'L'}, $height-$margins{'T'}-$fontsize);
($txt, $cont, $unused) = $text->section($txt, 
	  $width-$margins{'L'}-$margins{'R'},
	  $height-$margins{'T'}-$margins{'B'}, $cont,
	  -spillover=>0, -align => 'justify', -pndnt => 2, -pvgap => 4 );

# heading, footing
$text->translate(($width+$margins{'L'}-$margins{'R'})/2,
	         $height-$margins{'T'}/2);
$text->text_center('The Sequel');
$text->translate(($width+$margins{'L'}-$margins{'R'})/2,
	         ($margins{'B'}-$fontsize)/2);
$text->text_center('-- 4 --');

# ========================
$pdf->saveas($PDFname);
