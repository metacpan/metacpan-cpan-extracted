#!/usr/bin/env perl
use strict;
use warnings;
use SOOT qw/:all/;

my $cv = exclusiongraph();
$gApplication->Run();

sub exclusiongraph {
     # Draw three graphs with an exclusion zone.
     #Author: Olivier Couet
     
     my $c1 = TCanvas->new("c1","Exclusion graphs examples",200,10,600,400);
     $c1->SetGrid;

     my $mg = TMultiGraph->new->keep;
     $mg->SetTitle("Exclusion graphs");

     my $n = 35;
     my (@x1, @x2, @x3, @y1, @y2, @y3);
     foreach my $i (0..$n-1) {
         $x1[$i] = $i*0.1;
         $x2[$i] = $x1[$i];
         $x3[$i] = $x1[$i]+.5;
         $y1[$i] = 10.*sin($x1[$i]||1e-12);
         $y2[$i] = 10.*cos($x1[$i])+1e-12;
         $y3[$i] = 10.*sin($x1[$i])-2.+1e-12;
     }

     my $gr1 = TGraph->new($n,\@x1,\@y1)->keep;
     $gr1->SetLineColor(2);
     $gr1->SetLineWidth(1504);
     $gr1->SetFillStyle(3005);

     my $gr2 = TGraph->new($n,\@x2,\@y2)->keep;
     $gr2->SetLineColor(4);
     $gr2->SetLineWidth(-2002);
     $gr2->SetFillStyle(3004);
     $gr2->SetFillColor(9);

     my $gr3 = TGraph->new($n,\@x3,\@y3)->keep;
     $gr3->SetLineColor(5);
     $gr3->SetLineWidth(-802);
     $gr3->SetFillStyle(3002);
     $gr3->SetFillColor(2);

     $mg->Add($gr1);
     $mg->Add($gr2);
     $mg->Add($gr3);
     $mg->Draw("AC");

     return $c1;
}
