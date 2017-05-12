use strict;
use warnings;
use SOOT ':all';

$gROOT->Reset;

my $nut = TCanvas->new('nut', 'FirstSession', 100, 10, 700, 900); 
$nut->Range(0, 0, 20, 24); 
$nut->SetFillColor(10); 
$nut->SetBorderSize(2); 
 
my $pl = TPaveLabel->new( 3, 22, 17, 23.7, 'My first SOOT interactive session', 'br'); 
$pl->SetFillColor(18); 
$pl->Draw(); 
 
my $t = TText->new(0,0,'a'); 
$t->SetTextFont(62); 
$t->SetTextSize(0.025); 
$t->SetTextAlign(12); 
$t->DrawText(2, 20.3, 'SOOT provides ROOT bindings for Perl');
$t->DrawText(2, 19.3, 'Blocks of lines can be entered typographically.'); 
$t->DrawText(2, 18.3, 'Previous typed lines can be recalled.'); 
 
$t->SetTextFont(72); 
$t->SetTextSize(0.026); 
$t->DrawText(3, 17, '> my ($x, $y) = (5, 7)'); 
$t->DrawText(3, 16, '> $x*sqrt($y)'); 
$t->DrawText(3, 14, '> print "sqrt($_) = " . sqrt($_) for 2..7');
$t->DrawText(3, 10, '> use SOOT; my $f1 = TF1->new( "f1", "sin(x)/x", 0, 10 )'); 
$t->DrawText(3,  9, '> $f1.Draw()'); 
$t->SetTextFont(81); 
$t->SetTextSize(0.018); 
$t->DrawText(4, 15,   '13.228756555322953'); 
$t->DrawText(4, 13.3, 'sqrt(2) = 1.414214');
$t->DrawText(4, 12.7, 'sqrt(3) = 1.732051'); 
$t->DrawText(4, 12.1, 'sqrt(4) = 2.000000'); 
$t->DrawText(4, 11.5, 'sqrt(5) = 2.236068'); 
$t->DrawText(4, 10.9, 'sqrt(6) = 2.449490'); 
 
my $pad = TPad->new('pad', 'pad', .2, .05, .8, .35); 
$pad->SetFillColor(42); 
$pad->SetFrameFillColor(33); 
$pad->SetBorderSize(10); 
$pad->Draw(); 
$pad->cd(); 
$pad->SetGrid(); 
 
my $f1 = TF1->new('f1', 'sin(x)/x', 0, 10); 
$f1->Draw(); 
$nut->cd(); 
$nut->Update(); 

$gApplication->Run;

__END__
