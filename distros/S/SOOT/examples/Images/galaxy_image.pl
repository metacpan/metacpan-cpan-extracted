use strict;
use warnings;
use SOOT ':all';

my $canv = TCanvas->new("image", "n4254", 40, 40, 812, 700);
$canv->ToggleEventStatus();
$canv->SetRightMargin(0.2);
$canv->SetLeftMargin(0.01);
$canv->SetTopMargin(0.01);
$canv->SetBottomMargin(0.01);

# read the pixel data from file "galaxy.root"
# the size of the image is 401 X 401 pixels
my $file = 'galaxy.root';
my $gal;
if (-e $file) {
  $gal = TFile->new($file, "READ");
} else {
  $gal = TFile::Open("http://root.cern.ch/files/$file");
}
my $img = $gal->Get("n4254");
$img->Draw();

# open the color editor
$img->StartPaletteEditor();

# zoom the image
$img->Zoom(80, 80, 250, 250);

$gApplication->Run;
