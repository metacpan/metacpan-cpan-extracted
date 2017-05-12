#!/usr/bin/perl

use PDF::Haru;

my $page_title = "Line Example";

# create new document
my $pdf = PDF::Haru::New();

# add page
my $page = $pdf->AddPage();
$page->SetSize(HPDF_PAGE_SIZE_A4, HPDF_PAGE_PORTRAIT);


# create default-font
my $font = $pdf->GetFont("Helvetica", "StandardEncoding"); 

# print the lines of the page. 
$page->SetLineWidth (1);
$page->Rectangle (50, 50, $page->GetWidth() - 100,
			$page->GetHeight () - 110);
$page->Stroke ();

# print the title of the page (with positioning center). 
$page->SetFontAndSize ($font, 24);
my $tw = $page->TextWidth ($page_title);
$page->BeginText ();
$page->MoveTextPos (($page->GetWidth() - $tw) / 2,
			$page->GetHeight () - 50);
$page->ShowText ($page_title);
$page->EndText ();

$page->SetFontAndSize ($font, 10);

# Draw verious widths of lines. 
$page->SetLineWidth (0);
draw_line ($page, 60, 770, "line width = 0");

$page->SetLineWidth (1.0);
draw_line ($page, 60, 740, "line width = 1.0");

$page->SetLineWidth (2.0);
draw_line ($page, 60, 710, "line width = 2.0");

# Line dash pattern 
$page->SetLineWidth (1.0);

$page->SetFontAndSize ($font, 9);

$page->SetDash ([3], 1);
draw_line ($page, 60, 680, '$dash_pattern=[3], $phase=1 -- 2 on, 3 off, 3 on...');

$page->SetDash ([7,3], 2);
draw_line ($page, 60, 650, '$dash_pattern=[7, 3], $phase=2 -- 5 on 3 off, 7 on,...');

$page->SetDash ([8,7,2,7], 0);
draw_line ($page, 60, 620, '$dash_pattern=[8, 7, 2, 7], $phase=0');

$page->SetFontAndSize ($font, 10);

$page->SetDash ([], 0);

$page->SetLineWidth (30);
$page->SetRGBStroke (0.0, 0.5, 0.0);

# Line Cap Style 
$page->SetLineCap (HPDF_BUTT_END);
draw_line2 ($page, 60, 570, "PDF_BUTT_END");

$page->SetLineCap (HPDF_ROUND_END);
draw_line2 ($page, 60, 505, "PDF_ROUND_END");

$page->SetLineCap (HPDF_PROJECTING_SCUARE_END);
draw_line2 ($page, 60, 440, "PDF_PROJECTING_SCUARE_END");

# Line Join Style
$page->SetLineWidth (30);
$page->SetRGBStroke (0.0, 0.0, 0.5);

$page->SetLineJoin (HPDF_MITER_JOIN);
$page->MoveTo (120, 300);
$page->LineTo (160, 340);
$page->LineTo (200, 300);
$page->Stroke ();

$page->BeginText ();
$page->MoveTextPos (60, 360);
$page->ShowText ("PDF_MITER_JOIN");
$page->EndText ();

$page->SetLineJoin (HPDF_ROUND_JOIN);
$page->MoveTo (120, 195);
$page->LineTo (160, 235);
$page->LineTo (200, 195);
$page->Stroke ();

$page->BeginText ();
$page->MoveTextPos (60, 255);
$page->ShowText ("PDF_ROUND_JOIN");
$page->EndText ();

$page->SetLineJoin (HPDF_BEVEL_JOIN);
$page->MoveTo (120, 90);
$page->LineTo (160, 130);
$page->LineTo (200, 90);
$page->Stroke ();

$page->BeginText ();
$page->MoveTextPos (60, 150);
$page->ShowText ("PDF_BEVEL_JOIN");
$page->EndText ();

# Draw Rectangle 
$page->SetLineWidth (2);
$page->SetRGBStroke (0, 0, 0);
$page->SetRGBFill (0.75, 0.0, 0.0);

draw_rect ($page, 300, 770, "Stroke");
$page->Stroke ();

draw_rect ($page, 300, 720, "Fill");
$page->Fill ();

draw_rect ($page, 300, 670, "Fill then Stroke");
$page->FillStroke ();

# Clip Rect 
$page->GSave ();  # Save the current graphic state 
draw_rect ($page, 300, 620, "Clip Rectangle");
$page->Clip ();
$page->Stroke ();
$page->SetFontAndSize ($font, 13);

$page->BeginText ();
$page->MoveTextPos (290, 600);
$page->SetTextLeading (12);
$page->ShowText (
			"Clip Clip Clip Clip Clip Clipi Clip Clip Clip");
$page->ShowTextNextLine (
			"Clip Clip Clip Clip Clip Clip Clip Clip Clip");
$page->ShowTextNextLine (
			"Clip Clip Clip Clip Clip Clip Clip Clip Clip");
$page->EndText ();
$page->GRestore ();

# Curve Example(CurveTo2) 
my $x = 330;
my $y = 440;
my $x1 = 430;
my $y1 = 530;
my $x2 = 480;
my $y2 = 470;
my $x3 = 480;
my $y3 = 90;

$page->SetRGBFill (0, 0, 0);

$page->BeginText ();
$page->MoveTextPos (300, 540);
$page->ShowText ("CurveTo2(x1, y1, x2. y2)");
$page->EndText ();

$page->BeginText ();
$page->MoveTextPos ($x + 5, $y - 5);
$page->ShowText ("Current point");
$page->MoveTextPos ($x1 - $x, $y1 - $y);
$page->ShowText ("(x1, y1)");
$page->MoveTextPos ($x2 - $x1, $y2 - $y1);
$page->ShowText ("(x2, y2)");
$page->EndText ();

$page->SetDash ([3], 0);

$page->SetLineWidth (0.5);
$page->MoveTo (x1, y1);
$page->LineTo (x2, y2);
$page->Stroke ();

$page->SetDash ([], 0);

$page->SetLineWidth (1.5);

$page->MoveTo ($x, $y);
$page->CurveTo2 ($x1, $y1, $x2, $y2);
$page->Stroke ();

# Curve Example(CurveTo3)
$y -= 150;
$y1 -= 150;
$y2 -= 150;

$page->BeginText ();
$page->MoveTextPos (300, 390);
$page->ShowText ("CurveTo3(x1, y1, x2. y2)");
$page->EndText ();

$page->BeginText ();
$page->MoveTextPos ($x + 5, $y - 5);
$page->ShowText ("Current point");
$page->MoveTextPos ($x1 - $x, $y1 - $y);
$page->ShowText ("(x1, y1)");
$page->MoveTextPos ($x2 - $x1, $y2 - $y1);
$page->ShowText ("(x2, y2)");
$page->EndText ();

$page->SetDash ([3], 0);

$page->SetLineWidth (0.5);
$page->MoveTo ($x, $y);
$page->LineTo ($x1, $y1);
$page->Stroke ();

$page->SetDash ([], 0);

$page->SetLineWidth (1.5);
$page->MoveTo ($x, $y);
$page->CurveTo3 ($x1, $y1, $x2, $y2);
$page->Stroke ();

# Curve Example(CurveTo) 
$y -= 150;
$y1 -= 160;
$y2 -= 130;
$x2 += 10;

$page->BeginText ();
$page->MoveTextPos (300, 240);
$page->ShowText ("CurveTo(x1, y1, x2. y2, x3, y3)");
$page->EndText ();

$page->BeginText ();
$page->MoveTextPos ($x + 5, $y - 5);
$page->ShowText ("Current point");
$page->MoveTextPos ($x1 - $x, $y1 - $y);
$page->ShowText ("(x1, y1)");
$page->MoveTextPos ($x2 - $x1, $y2 - $y1);
$page->ShowText ("(x2, y2)");
$page->MoveTextPos ($x3 - $x2, $y3 - $y2);
$page->ShowText ("(x3, y3)");
$page->EndText ();

$page->SetDash ([3], 0);

$page->SetLineWidth (0.5);
$page->MoveTo ($x, $y);
$page->LineTo ($x1, $y1);
$page->Stroke ();
$page->MoveTo ($x2, $y2);
$page->LineTo ($x3, $y3);
$page->Stroke ();

$page->SetDash ([], 0);

$page->SetLineWidth (1.5);
$page->MoveTo ($x, $y);
$page->CurveTo ($x1, $y1, $x2, $y2, $x3, $y3);
$page->Stroke ();


# save the document to a file
$pdf->SaveToFile("line_demo.pdf");

# cleanup
$pdf->Free();


sub draw_line {
	my ($page,$x,$y,$label) = @_;
    $page->BeginText ();
    $page->MoveTextPos ($x, $y - 10);
    $page->ShowText ($label);
    $page->EndText ();

    $page->MoveTo ($x, $y - 15);
    $page->LineTo ($x + 220, $y - 15);
    $page->Stroke ();	
}

sub draw_line2 {
	my ($page,$x,$y,$label) = @_;
    $page->BeginText ();
    $page->MoveTextPos ($x, $y);
    $page->ShowText ($label);
    $page->EndText ();

    $page->MoveTo ($x + 30, $y - 25);
    $page->LineTo ($x + 160, $y - 25);
    $page->Stroke ();	
}

sub draw_rect {
	my ($page,$x,$y,$label) = @_;
    $page->BeginText ();
    $page->MoveTextPos ($x, $y - 10);
    $page->ShowText ($label);
    $page->EndText ();

    $page->Rectangle($x, $y - 40, 220, 25);	
}
