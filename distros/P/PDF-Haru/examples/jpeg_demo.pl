#!/usr/bin/perl

use PDF::Haru;

# create new document
my $pdf = PDF::Haru::New();

my $font = $pdf->GetFont("Helvetica", "StandardEncoding"); 

# add page
my $page = $pdf->AddPage();

$page->SetWidth (650);
$page->SetHeight (500);

my $dst = $page->CreateDestination ();
$dst->SetXYZ (0, $page->GetHeight (), 1);
$pdf->SetOpenAction($dst);

$page->BeginText ();
$page->SetFontAndSize ($font, 20);
$page->MoveTextPos (220, $page->GetHeight () - 70);
$page->ShowText ("JpegDemo");
$page->EndText ();

$page->SetFontAndSize ($font, 12);

draw_image ($pdf, "rgb.jpg", 70, $page->GetHeight () - 410,
			"24bit color image");
draw_image ($pdf, "gray.jpg", 340, $page->GetHeight () - 410,
			"8bit grayscale image");


# save the document to a file
$pdf->SaveToFile("jpeg_demo.pdf");

# cleanup
$pdf->Free();


sub draw_image {
	my ($pdf,$filename,$x,$y,$text) = @_;
	my $page = $pdf->GetCurrentPage ();
	my $image = $pdf->LoadJpegImageFromFile ('images/'.$filename);
    # Draw image to the canvas. 
    $page->DrawImage ($image, $x, $y, $image->GetWidth (),
                $image->GetHeight ());

    # Print the text. 
    $page->BeginText ();
    $page->SetTextLeading (16);
    $page->MoveTextPos ($x, $y);
    $page->ShowTextNextLine ($filename);
    $page->ShowTextNextLine ($text);
    $page->EndText ();
}
