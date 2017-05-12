#!/usr/bin/perl

use PDF::Haru;

my $page_title = 'Text Demo';
my $samp_text = 'abcdefgABCDEFG123!#$%&+-@?';
my $samp_text2 = 'The quick brown fox jumps over the lazy dog.';

# create new document
my $pdf = PDF::Haru::New();

# add page
my $page = $pdf->AddPage();

# create default-font
my $font = $pdf->GetFont("Helvetica", "StandardEncoding");

#print the title of the page (with positioning center).
$page->SetFontAndSize ($font, 24);
my $tw = $page->TextWidth ($page_title);
$page->BeginText ();
$page->TextOut (($page->GetWidth() - $tw) / 2,
			$page->GetHeight () - 50, $page_title);
$page->EndText ();

$page->BeginText ();
$page->MoveTextPos (60, $page->GetHeight() - 60);


# font size
my $fsize = 8;
while ($fsize < 60) {
	my $buf;
	my $len;

	# set style and size of font.
	$page->SetFontAndSize($font, $fsize);

	# set the position of the text. 
	$page->MoveTextPos (0, -5 - $fsize);

	$buf = $samp_text;

	# measure the number of characters which included in the page.
	$len = $page->MeasureText ($samp_text,
					$page->GetWidth() - 120, HPDF_FALSE);
	$buf = substr($buf,0,$len);
	$page->ShowText ($buf);

	# print the description.
	$page->MoveTextPos (0, -10);
	$page->SetFontAndSize($font, 8);

	$buf = sprintf("Fontsize=%.0f", $fsize);

	$page->ShowText ($buf);

	$fsize *= 1.5;
}


# font color
$page->SetFontAndSize($font, 8);
$page->MoveTextPos (0, -30);
$page->ShowText ("Font color");

$page->SetFontAndSize ($font, 18);
$page->MoveTextPos (0, -20);
my $len = length($samp_text);
for (my $i = 0; $i < $len; $i++) {
	my $buf;
	my $r = $i / $len;
	my $g = 1 - ($i / $len);
	$buf = substr($samp_text,$i,1);

	$page->SetRGBFill ($r, $g, 0);
	$page->ShowText ($buf);
}
$page->MoveTextPos (0, -25);

for (my $i = 0; $i < $len; $i++) {
	my $buf;
	my $r = $i / $len;
	my $b = 1 - ($i / $len);
	$buf = substr($samp_text,$i,1);

	$page->SetRGBFill ($r, 0, $b);
	$page->ShowText ($buf);
}
$page->MoveTextPos (0, -25);

for (my $i = 0; $i < $len; $i++) {
	my $buf;
	my $b = $i / $len;
	my $g = 1 - ($i / $len);
	$buf = substr($samp_text,$i,1);

	$page->SetRGBFill (0, $g, $b);
	$page->ShowText ($buf);
}

$page->EndText ();

my $ypos = 450;


# Font rendering mode
$page->SetFontAndSize($font, 32);
$page->SetRGBFill (0.5, 0.5, 0.0);
$page->SetLineWidth (1.5);

# PDF_FILL 
show_description ($page,  60, $ypos,
			"RenderingMode=PDF_FILL");
$page->SetTextRenderingMode (HPDF_FILL);
$page->BeginText ();
$page->TextOut (60, $ypos, "ABCabc123");
$page->EndText ();

# PDF_STROKE 
show_description ($page, 60, $ypos - 50,
			"RenderingMode=PDF_STROKE");
$page->SetTextRenderingMode (HPDF_STROKE);
$page->BeginText ();
$page->TextOut (60, $ypos - 50, "ABCabc123");
$page->EndText ();

# PDF_FILL_THEN_STROKE 
show_description ($page, 60, $ypos - 100,
			"RenderingMode=PDF_FILL_THEN_STROKE");
$page->SetTextRenderingMode (HPDF_FILL_THEN_STROKE);
$page->BeginText ();
$page->TextOut (60, $ypos - 100, "ABCabc123");
$page->EndText ();

# PDF_FILL_CLIPPING 
show_description ($page, 60, $ypos - 150,
			"RenderingMode=PDF_FILL_CLIPPING");
$page->GSave ();
$page->SetTextRenderingMode (HPDF_FILL_CLIPPING);
$page->BeginText ();
$page->TextOut (60, $ypos - 150, "ABCabc123");
$page->EndText ();
#show_stripe_pattern ($page, 60, $ypos - 150);
$page->GRestore ();

# PDF_STROKE_CLIPPING 
show_description ($page, 60, $ypos - 200,
			"RenderingMode=PDF_STROKE_CLIPPING");
$page->GSave ();
$page->SetTextRenderingMode (HPDF_STROKE_CLIPPING);
$page->BeginText ();
$page->TextOut (60, $ypos - 200, "ABCabc123");
$page->EndText ();
#show_stripe_pattern ($page, 60, $ypos - 200);
$page->GRestore ();

# PDF_FILL_STROKE_CLIPPING 
show_description ($page, 60, $ypos - 250,
			"RenderingMode=PDF_FILL_STROKE_CLIPPING");
$page->GSave ();
$page->SetTextRenderingMode (HPDF_FILL_STROKE_CLIPPING);
$page->BeginText ();
$page->TextOut (60, $ypos - 250, "ABCabc123");
$page->EndText ();
#show_stripe_pattern ($page, 60, $ypos - 250);
$page->GRestore ();

# Reset text attributes 
$page->SetTextRenderingMode (HPDF_FILL);
$page->SetRGBFill (0, 0, 0);
$page->SetFontAndSize($font, 30);


# Rotating text
my $angle1 = 30;                   
my $rad1 = $angle1 / 180 * 3.141592; 

show_description ($page, 320, $ypos - 60, "Rotating text");
$page->BeginText ();
$page->SetTextMatrix (cos($rad1), sin($rad1), -sin($rad1), cos($rad1),
			330, $ypos - 60);
$page->ShowText ("ABCabc123");
$page->EndText ();


# Skewing text.
show_description ($page, 320, $ypos - 120, "Skewing text");
$page->BeginText ();

my $angle1 = 10;
my $angle2 = 20;
$rad1 = $angle1 / 180 * 3.141592;
my $rad2 = $angle2 / 180 * 3.141592;

$page->SetTextMatrix (1, sin($rad1)/cos($rad1), sin($rad2)/cos($rad2), 1, 320, $ypos - 120);
$page->ShowText ("ABCabc123");
$page->EndText ();


# scaling text (X direction)
show_description ($page, 320, $ypos - 175, "Scaling text (X direction)");
$page->BeginText ();
$page->SetTextMatrix (1.5, 0, 0, 1, 320, $ypos - 175);
$page->ShowText ("ABCabc12");
$page->EndText ();


# scaling text (Y direction)
show_description ($page, 320, $ypos - 250, "Scaling text (Y direction)");
$page->BeginText ();
$page->SetTextMatrix (1, 0, 0, 2, 320, $ypos - 250);
$page->ShowText ("ABCabc123");
$page->EndText ();


# char spacing, word spacing
show_description ($page, 60, 140, "char-spacing 0");
show_description ($page, 60, 100, "char-spacing 1.5");
show_description ($page, 60, 60, "char-spacing 1.5, word-spacing 2.5");

$page->SetFontAndSize ($font, 20);
$page->SetRGBFill (0.1, 0.3, 0.1);

# char-spacing 0 
$page->BeginText ();
$page->TextOut (60, 140, $samp_text2);
$page->EndText ();

# char-spacing 1.5 
$page->SetCharSpace (1.5);

$page->BeginText ();
$page->TextOut (60, 100, $samp_text2);
$page->EndText ();

# char-spacing 1.5, word-spacing 3.5 
$page->SetWordSpace (2.5);

$page->BeginText ();
$page->TextOut (60, 60, $samp_text2);
$page->EndText ();


# save the document to a file
$pdf->SaveToFile("text_demo.pdf");

# cleanup
$pdf->Free();



sub show_description  () {
	my ($page,$x,$y,$text) = @_;
	my $fsize = $page->GetCurrentFontSize();
	my $font = $page->GetCurrentFont ();
	my ($r, $g, $b) = $page->GetRGBFill();
	
    $page->BeginText ();
    $page->SetRGBFill (0, 0, 0);
    $page->SetTextRenderingMode (HPDF_FILL);
    $page->SetFontAndSize ($font, 10);
    $page->TextOut ($x, $y - 12, $text);
    $page->EndText ();

    $page->SetFontAndSize ($font, $fsize);
    $page->SetRGBFill ($r, $g, $b);	
}
