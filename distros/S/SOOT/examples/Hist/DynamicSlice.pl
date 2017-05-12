#!/usr/bin/env perl
use strict;
use warnings;
use SOOT qw/:all/;
SOOT::Init(0);
SOOT::Load('TGX11TTF');

DynamicSlice();
$gApplication->Run();

sub DynamicExec {
  # Example of function called when a mouse event occurs in a pad.
  # When moving the mouse in the canvas, a second canvas shows the
  # projection along X of the bin corresponding to the Y position
  # of the mouse. The resulting histogram is fitted with a gaussian.
  # A "dynamic" line shows the current bin position in Y.
  # This more elaborated example can be used as a starting point
  # to develop more powerful interactive applications exploiting CINT
  # as a development engine.
  #
  # Author:  Rene Brun
   
  my $select = $gPad->GetSelected();
  return if !defined $select;
  $gPad->SetUniqueID(0), return if !$select->InheritsFrom(TH2::Class());
  my $h = $select->as('TH2');
  $gPad->GetCanvas()->FeedbackMode(kTRUE);

  # erase old position and draw a line at current position
  my $pyold = $gPad->GetUniqueID();
  my $px = $gPad->GetEventX();
  my $py = $gPad->GetEventY();
  my $uxmin = $gPad->GetUxmin();
  my $uxmax = $gPad->GetUxmax();
  my $pxmin = $gPad->XtoAbsPixel($uxmin);
  my $pxmax = $gPad->XtoAbsPixel($uxmax);
  if ($pyold) {
    $gVirtualX->DrawLine($pxmin, $pyold, $pxmax, $pyold);
  }
  $gVirtualX->DrawLine($pxmin, $py, $pxmax, $py);
  $gPad->SetUniqueID($py);
  my $upy = $gPad->AbsPixeltoY($py);
  my $y = $gPad->PadtoY($upy);

  # create or set the new canvas c2
  my $padsav = $gPad;
  my $c2 = $gROOT->FindObject("c2");
  if (defined $c2) {
    #$c2->GetPrimitive("Projection")->delete;
  }
  else {
    $c2 = TCanvas->new("c2","Projection Canvas",710,10,700,500);
  }
  $c2->SetGrid();
  $c2->cd();

  # draw slice corresponding to mouse position
  my $biny = $h->GetYaxis()->FindBin($y);
  my $hp = $h->ProjectionX("", $biny, $biny);
  $hp->SetFillColor(38);
  my $title = sprintf("Projection of biny=%d", $biny);
  $hp->SetName("Projection");
  $hp->SetTitle($title);
  $hp->Fit("gaus", "ql");
  $hp->GetFunction("gaus")->SetLineColor(kRed);
  $hp->GetFunction("gaus")->SetLineWidth(6);
  $c2->Update();
  $padsav->cd();
}

# Show the slice of a TH2 following the mouse position
sub DynamicSlice {
  # Create a new canvas.
  my $c1 = TCanvas->new("c1","Dynamic Slice Example",10,10,700,500)->keep;
  $c1->SetFillColor(42);
  $c1->SetFrameFillColor(33);
  
  # create a 2-d histogram, fill and draw it
  my $hpxpy = TH2F->new("hpxpy","py vs px",40,-4,4,40,-4,4)->keep;
  $hpxpy->SetStats(0);
  foreach (1..50000) {
    my ($px, $py) = $gRandom->Rannor();
    $hpxpy->Fill($px, $py);
  }
  $hpxpy->Draw("col");
   
  # Add a TExec object to the canvas
  $c1->AddExec("dynamic", sub {DynamicExec()});
}

