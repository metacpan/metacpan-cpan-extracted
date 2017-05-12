use strict;
use warnings;
use SOOT ':all';

# Getting Contours From TH2D
# Author: Josh de Bever
#         CSI Medical Physics Group
#         The University of Western Ontario
#         London, Ontario, Canada
#   Date: Oct. 22, 2004
#   Modified by O.Couet (Nov. 26, 2004)
#   Converted to Perl by S. Mueller (Jul 22, 2011)

ContourList();
$gApplication->Run();

sub SawTooth {
  # This function is specific to a sawtooth function with period
  # WaveLen, symmetric about x = 0, and with amplitude = 1. Each segment
  # is 1/4 of the wavelength.
  #
  #           |
  #      /\   |
  #     /  \  |
  #    /    \ |
  #   /      \
  #  /--------\--------/------------
  #           |\      /
  #           | \    /
  #           |  \  /
  #           |   \/
  #
  my ($x, $WaveLen) = @_;
  my $wl2 = 0.5*$WaveLen;
  my $wl4 = 0.25*$WaveLen;
  return -99999999 if $x < -$wl2 or $x > $wl2; # Error X out of bounds
  if ($x <= -$wl4) {
    return $x + 2.;
  } elsif ($x > -$wl4 and $x <= $wl4) {
    return -$x;
  } elsif ($x > $wl4 and $x <= $wl2) {
    return $x - 2.;
  }
  die "Should not be reached";
}

use constant PI => TMath::Pi();
sub ContourList {
  my $c = TCanvas->new("c","Contour List",0,0,600,600)->keep;
  $c->SetRightMargin(0.15);
  $c->SetTopMargin(0.15);

  my ($i, $j);

  my $nZsamples   = 80;
  my $nPhiSamples = 80;

  my $HofZwavelength = 4.0;       # 4 meters
  my $dZ             =  $HofZwavelength/($nZsamples - 1.);
  my $dPhi           = 2*PI()/($nPhiSamples - 1.);

  my (@z, @HofZ, @phi, @FofPhi);

  # Discretized Z and Phi Values
  foreach my $i (0 .. $nZsamples) {
    $z[$i]    = $i*$dZ - $HofZwavelength/2.;
    $HofZ[$i] = SawTooth($z[$i], $HofZwavelength)
  }

  foreach my $i (0.. $nPhiSamples) {
    $phi[$i]    = $i*$dPhi;
    $FofPhi[$i] = sin($phi[$i]);
  }
   
  # Create Histogram
  my $HistStreamFn = TH2D->new(
    "HstreamFn",
    "#splitline{Histogram with negative and positive contents. Six contours are defined.}{It is plotted with options CONT LIST to retrieve the contours points in TGraphs}",
    $nZsamples, $z[0], $z[$#z],
    $nPhiSamples, $phi[0], $phi[$#phi]
  )->keep;

  # Load Histogram Data
  foreach my $i (0 .. $nZsamples) {
    foreach my $j (0 .. $nPhiSamples) {
      $HistStreamFn->SetBinContent($i, $j, $HofZ[$i] * $FofPhi[$j]);
    }
  }

  $gStyle->SetPalette(1);
  $gStyle->SetOptStat(0);
  $gStyle->SetTitleW(0.99);
  $gStyle->SetTitleH(0.08);

  my @contours = (-.7, -.5, -.1, .1, .4, .8);
  $HistStreamFn->SetContour(6, \@contours);
  # Draw contours as filled regions, and Save points
  $HistStreamFn->Draw("CONT Z LIST");
  $c->Update(); # Needed to force the plotting and retrieve the contours in TGraphs

  # Get Contours
  #my $sp = $gROOT->GetListOfSpecials();
  my $conts = $gROOT->FindObject("contours");

  my $nGraphs    = 0;
  my $TotalConts = 0;
  
  if (not defined($conts)) {
    printf("*** No Contours Were Extracted!\n");
    return;
  } else {
    $TotalConts = $conts->GetSize();
  }

  printf("TotalConts = %d\n", $TotalConts);

  foreach my $i (0 .. $TotalConts-1) {
    my $contLevel =$conts->At($i);
    printf("Contour %d has %d Graphs\n", $i, $contLevel->GetSize());
    $nGraphs += $contLevel->GetSize();
  }

  $nGraphs = 0;

  my $c1 = TCanvas->new("c1","Contour List",610,0,600,600)->keep;
  $c1->SetTopMargin(0.15);
  my $hr = TH2F->new("hr",
    "#splitline{Negative contours are returned first (highest to lowest). Positive contours are returned from}{lowest to highest. On this plot Negative contours are drawn in red and positive contours in blue.}",
    2, -2., 2., 2, 0., 6.5
  );

  $hr->Draw();
  my $l = TLatex->new;
  $l->SetTextSize(0.03);

  foreach my $i (0 .. $TotalConts-1) {
    my $contLevel = $conts->At($i);
    my $z0;
    if ($i<3) { $z0 = $contours[2-$i]; }
    else      { $z0 = $contours[$i]; }
    printf("Z-Level Passed in as:  Z = %f\n", $z0);

    # Get first graph from list on curves on this level
    my $curv = $contLevel->First();
    foreach my $j (0 .. $contLevel->GetSize()-1) {
      my $x0 = $curv->GetX()->[0];
      my $y0 = $curv->GetY()->[0];
      if ($z0<0) { $curv->SetLineColor(kRed); }
      if ($z0>0) { $curv->SetLineColor(kBlue); }
      $nGraphs++;
      printf("\tGraph: %d  -- %d Elements\n", $nGraphs, $curv->GetN());

      # Draw clones of the graphs to avoid deletions in case the 1st
      # pad is redrawn.
      my $gc = $curv->Clone()->keep;
      $gc->Draw("C");

      my $val = sprintf("%g",$z0);
         $l->DrawLatex($x0,$y0,$val);
         $curv = $contLevel->After($curv); # Get Next graph
      }
   }
   $c1->Update();
   printf("\n\n\tExtracted %d Contours and %d Graphs \n", $TotalConts, $nGraphs );
   $gStyle->SetTitleW(0.);
   $gStyle->SetTitleH(0.);
}
