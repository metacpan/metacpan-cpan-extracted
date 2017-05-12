use strict;
use warnings;
use SOOT ':all';
use File::Spec;

# Macro to test scatterplot smoothers: ksmooth, lowess, supsmu
# as described in:
#    Modern Applied Statistics with S-Plus, 3rd Edition
#    W.N. Venables and B.D. Ripley
#    Chapter 9: Smooth Regression, Figure 9.1 
#
# Example is a set of data on 133 observations of acceleration against time
# for a simulated motorcycle accident, taken from Silverman (1985).

# data taken from R library MASS: mcycle.txt
my $rootlib = Alien::ROOT->new->libdir;
my $inFile = shift
             || File::Spec->catfile($rootlib, '..', '..',
                                    qw(share doc root tutorials graphs motorcycle.dat));

# read file and add to fit object
my $x = [];
my $y = [];

my ($vX, $vY);
my $vNData = 0;

open INPUT, "$inFile" or die "Could not open $inFile"; 
while (<INPUT>) {
  ($vX,$vY) = split;
  push @$x, $vX*1.;
  push @$y, $vY*1.;
  $vNData++;
}
close INPUT;

my $grin = TGraph->new($vNData,$x,$y);

# draw graph
my $can = TCanvas->new("can","Smooth Regression",200,10,900,700);
$can->Divide(2,3);

# Kernel Smoother
# create new kernel smoother and smooth data with bandwidth = 2.0
my $gs = TGraphSmooth->new("normal");
my $grout = $gs->SmoothKern($grin,"normal",2.0);
DrawSmooth($can, $grin, $grout, 1, "Kernel Smoother: bandwidth = 2.0", "times", "accel");

# redraw ksmooth with bandwidth = 5.0
$grout = $gs->SmoothKern($grin,"normal",5.0);
DrawSmooth($can,$grin,$grout,2,"Kernel Smoother: bandwidth = 5.0","","");

# Lowess Smoother
# create new lowess smoother and smooth data with fraction f = 2/3
$grout = $gs->SmoothLowess($grin,"",0.67);
DrawSmooth($can,$grin,$grout,3,"Lowess: f = 2/3","","");

# redraw lowess with fraction f = 0.2
$grout = $gs->SmoothLowess($grin,"",0.2);
DrawSmooth($can,$grin,$grout,4,"Lowess: f = 0.2","","");

# Super Smoother
# create new super smoother and smooth data with default bass = 0 and span = 0
$grout = $gs->SmoothSuper($grin,"",0,0);
DrawSmooth($can,$grin,$grout,5,"Super Smoother: bass = 0","","");

# redraw supsmu with bass = 3 (smoother curve)
$grout = $gs->SmoothSuper($grin,"",3);
DrawSmooth($can,$grin,$grout,6,"Super Smoother: bass = 3","","");

sub DrawSmooth {
   my ($can, $grin, $grout, $pad, $title, $xt, $yt) = @_;
   $can->cd($pad);
   my $vFrame = $can->DrawFrame(0,-130,60,70);
   $vFrame->SetTitle($title);
   $vFrame->SetTitleSize(0.2);
   $vFrame->SetXTitle($xt);
   $vFrame->SetYTitle($yt);
   $grin->Draw("P");
   $grout->SetMarkerColor(kRed);
   $grout->SetMarkerStyle(21);
   $grout->SetMarkerSize(0.5);
   $grout->DrawClone("P");
   $grout->DrawClone("LPX");
   $vFrame->keep;
}

$gApplication->Run;
