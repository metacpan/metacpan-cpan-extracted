#!/usr/bin/perl

use PDF::Haru;

my $SAMP_TXT = "The quick brown fox jumps over the lazy dog. ";

# create new document
my $pdf = PDF::Haru::New();

# add page
my $page = $pdf->AddPage();
$page->SetSize(HPDF_PAGE_SIZE_A5, HPDF_PAGE_PORTRAIT);

my $page_height = $page->GetHeight ();

# create default-font
my $font = $pdf->GetFont("Helvetica", "StandardEncoding");

$page->SetTextLeading (20);

my $left = 25;
my $top = 545;
my $right = 200;
my $bottom = $top - 40;

$page->Rectangle ($left, $bottom, $right - $left,
			$top - $bottom);
$page->Stroke ();

$page->BeginText ();

$page->SetFontAndSize ($font, 10);
$page->TextOut ($left, $top + 3, "HPDF_TALIGN_LEFT");

$page->SetFontAndSize ($font, 13);
$page->TextRect ($left, $top, $right, $bottom,
			$SAMP_TXT, HPDF_TALIGN_LEFT);

$page->EndText ();

# HPDF_TALIGN_RIGTH 
$left = 220;
$right = 395;

$page->Rectangle ($left, $bottom, $right - $left,
			$top - $bottom);
$page->Stroke ();

$page->BeginText ();

$page->SetFontAndSize ($font, 10);
$page->TextOut ($left, $top + 3, "HPDF_TALIGN_RIGTH");

$page->SetFontAndSize ($font, 13);
$page->TextRect ($left, $top, $right, $bottom,
			$SAMP_TXT, HPDF_TALIGN_RIGHT);

$page->EndText ();

# HPDF_TALIGN_CENTER 
$left = 25;
$top = 475;
$right = 200;
$bottom = $top - 40;

$page->Rectangle ($left, $bottom, $right - $left,
			$top - $bottom);
$page->Stroke ();

$page->BeginText ();

$page->SetFontAndSize ($font, 10);
$page->TextOut ($left, $top + 3, "HPDF_TALIGN_CENTER");

$page->SetFontAndSize ($font, 13);
$page->TextRect ($left, $top, $right, $bottom,
			$SAMP_TXT, HPDF_TALIGN_CENTER);

$page->EndText ();

# HPDF_TALIGN_JUSTIFY 
$left = 220;
$right = 395;

$page->Rectangle ($left, $bottom, $right - $left,
			$top - $bottom);
$page->Stroke ();

$page->BeginText ();

$page->SetFontAndSize ($font, 10);
$page->TextOut ($left, $top + 3, "HPDF_TALIGN_JUSTIFY");

$page->SetFontAndSize ($font, 13);
$page->TextRect ($left, $top, $right, $bottom,
			$SAMP_TXT, HPDF_TALIGN_JUSTIFY);

$page->EndText ();



# Skewed coordinate system 
$page->GSave ();

my $angle1 = 5;
my $angle2 = 10;
my $rad1 = $angle1 / 180 * 3.141592;
my $rad2 = $angle2 / 180 * 3.141592;

$page->Concat (1, sin($rad1)/cos($rad1), sin($rad2)/cos($rad2), 1, 25, 350);
$left = 0;
$top = 40;
$right = 175;
$bottom = 0;

$page->Rectangle ($left, $bottom, $right - $left,
			$top - $bottom);
$page->Stroke ();

$page->BeginText ();

$page->SetFontAndSize ($font, 10);
$page->TextOut ($left, $top + 3, "Skewed coordinate system");

$page->SetFontAndSize ($font, 13);
$page->TextRect ($left, $top, $right, $bottom,
			$SAMP_TXT, HPDF_TALIGN_LEFT);

$page->EndText ();

$page->GRestore ();


# Rotated coordinate system 
$page->GSave ();

$angle1 = 5;
$rad1 = $angle1 / 180 * 3.141592;

$page->Concat (cos($rad1), sin($rad1), -sin($rad1), cos($rad1), 220, 350);
$left = 0;
$top = 40;
$right = 175;
$bottom = 0;

$page->Rectangle ($left, $bottom, $right - $left,
			$top - $bottom);
$page->Stroke ();

$page->BeginText ();

$page->SetFontAndSize ($font, 10);
$page->TextOut ($left, $top + 3, "Rotated coordinate system");

$page->SetFontAndSize ($font, 13);
$page->TextRect ($left, $top, $right, $bottom,
			$SAMP_TXT, HPDF_TALIGN_LEFT);

$page->EndText ();

$page->GRestore ();


# text along a circle 
$page->SetGrayStroke (0);
$page->Circle (210, 190, 145);
$page->Circle (210, 190, 113);
$page->Stroke ();

$angle1 = 360 / (length ($SAMP_TXT));
$angle2 = 180;

$page->BeginText ();
$font = $pdf->GetFont ("Courier-Bold", "StandardEncoding");
$page->SetFontAndSize ($font, 30);

for (my $i = 0; $i < length ($SAMP_TXT); $i++) {


	$rad1 = ($angle2 - 90) / 180 * 3.141592;
	$rad2 = $angle2 / 180 * 3.141592;

	my $x = 210 + cos($rad2) * 122;
	my $y = 190 + sin($rad2) * 122;

	$page->SetTextMatrix(cos($rad1), sin($rad1), -sin($rad1), cos($rad1), $x, $y);

	my $buf = substr($SAMP_TXT,$i,1);
	$page->ShowText ($buf);
	$angle2 -= $angle1;
}

$page->EndText ();



# save the document to a file
$pdf->SaveToFile("text_demo2.pdf");

# cleanup
$pdf->Free();

