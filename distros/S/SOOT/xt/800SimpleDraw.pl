use strict;
use warnings;
use Data::Dumper;
use autobox::Core;

use SOOT;

# FIXME, pass arrays instead (since that now works)
my $g = TGraphErrors->new(3, [1., 3., 5.],
                             [9., 4., 6.],
                             [0.5, 0.5, 0.5],
                             [0.5, 0.5, 0.5] );

my $cv = TCanvas->new("myCanvas");
$g->Draw("ALP");
$cv->SaveAs("cv.eps");

my $x = $g->GetX();
warn Dumper $x;

my $bad = TGraph->new("blah", "blah", 2, [1,2], [2,3]);

