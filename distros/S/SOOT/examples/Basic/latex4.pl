use strict;
use warnings;
use SOOT ':all';

# Draw the Greek letters as a table and save the result as GIF, PS, PDF 
# and SVG files. 
# Lowercase Greek letters are obtained by adding a # to the name of the letter. 
# For an uppercase Greek letter, just capitalize the first letter of the
# command name. Some letter have two representations. The name of the
# second one (the "variation") starts with "var".
my $c1 = TCanvas->new("greek","greek",600,700);

my $l = TLatex->new;
$l->SetTextSize(0.03);

# Draw the columns titles
$l->SetTextAlign(22);
$l->DrawLatex(0.165, 0.95, "Lower case");
$l->DrawLatex(0.495, 0.95, "Upper case");
$l->DrawLatex(0.825, 0.95, "Variations");

# Draw the lower case letters
$l->SetTextAlign(12);
my ($y, $x1, $x2);
$y = 0.90; $x1 = 0.07; $x2 = $x1+0.2;
my @letters = qw(
  alpha beta gamma delta epsilon zeta eta
  theta iota kappa lambda mu nu xi omicron
  pi rho sigma tau upsilon phi chi psi omega
);
foreach my $letter (@letters) {
  $l->DrawLatex($x1, $y, "$letter : ");
  $l->DrawLatex($x2, $y, "#$letter");
  $y -= 0.0375;
}

# Draw the upper case letters
$y = 0.90; $x1 = 0.40; $x2 = $x1+0.2;
foreach my $letter (map {ucfirst $_} @letters) {
  $l->DrawLatex($x1, $y, "$letter : ");
  $l->DrawLatex($x2, $y, "#$letter");
  $y -= 0.0375;
}

# Draw the variations
my @letterVariations  = qw(varepsilon vartheta varsigma varUpsilon varphi varomega);
my @letterVariationsY = (0.7500, 0.6375, 0.2625, 0.1875, 0.1500, 0.0375);
$x1 = 0.73; $x2 = $x1+0.2;
foreach my $i (0..$#letterVariations) {
  my $letter = $letterVariations[$i];
  my $y      = $letterVariationsY[$i];
  $l->DrawLatex($x1, $y, "$letter : ");
  $l->DrawLatex($x2, $y, "#$letter");
}

# Save the picture in various formats
$c1->Print("greek.ps");
$c1->Print("greek.gif");
$c1->Print("greek.pdf");
$c1->Print("greek.svg");

$gApplication->Run;
