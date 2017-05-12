use strict;
use warnings;
use SOOT ':all';

my $DistCanvas = TCanvas->new("DistCanvas", "Distribution graphs", 10, 10, 1000, 800);  
$DistCanvas->SetFillColor(17);
$DistCanvas->Divide(2, 2);
my $pad1 = $DistCanvas->cd(1);
$pad1->SetGrid();
$pad1->SetFrameFillColor(19);

my $leg = TLegend->new(0.6, 0.7, 0.89, 0.89); 

my $fgaus = TF1->new("gaus", "TMath::Gaus(x, [0], [1], [2])", -5, 5);
$fgaus->SetTitle("Student density");  
$fgaus->SetLineStyle(2);
$fgaus->SetLineWidth(1);
$fgaus->SetParameters(0, 1, 1);
$leg->AddEntry($fgaus->DrawCopy(), "Normal(0,1)", "l");

my $student = TF1->new("student", "TMath::Student(x,[0])", -5, 5);
$student->SetTitle("Student density");  
$student->SetLineWidth(1); 
$student->SetParameter(0, 10);
$student->SetLineColor(4);  
$leg->AddEntry($student->DrawCopy("lsame"), "10 degrees of freedom", "l");

$student->SetParameter(0, 3);
$student->SetLineColor(2);
$leg->AddEntry($student->DrawCopy("lsame"), "3 degrees of freedom", "l");

$student->SetParameter(0, 1);
$student->SetLineColor(1);
$leg->AddEntry($student->DrawCopy("lsame"), "1 degree of freedom", "l");

$leg->Draw();

#drawing the set of student cumulative probability functions
my $pad2 = $DistCanvas->cd(2);
$pad2->SetFrameFillColor(19);
$pad2->SetGrid();

my $studentI = TF1->new("studentI", "TMath::StudentI(x, [0])", -5, 5);
$studentI->SetTitle("Student cumulative dist.");  
$studentI->SetLineWidth(1); 
my $leg2 = TLegend->new(0.6, 0.4, 0.89, 0.6); 

$studentI->SetParameter(0, 10);
$studentI->SetLineColor(4);
$leg2->AddEntry($studentI->DrawCopy(), "10 degrees of freedom", "l");
  
$studentI->SetParameter(0, 3);
$studentI->SetLineColor(2);
$leg2->AddEntry($studentI->DrawCopy("lsame"), "3 degrees of freedom", "l");

$studentI->SetParameter(0, 1);
$studentI->SetLineColor(1);
$leg2->AddEntry($studentI->DrawCopy("lsame"), "1 degree of freedom", "l");
$leg2->Draw();

#drawing the set of F-dist. densities  
my $fDist = TF1->new("fDist", "TMath::FDist(x, [0], [1])", 0, 2);
$fDist->SetTitle("F-Dist. density");
$fDist->SetLineWidth(1);
my $legF1 = TLegend->new(0.7, 0.7, 0.89, 0.89);
  
my $pad3 = $DistCanvas->cd(3);
$pad3->SetFrameFillColor(19);
$pad3->SetGrid();
 
$fDist->SetParameters(1, 1);
$fDist->SetLineColor(1);
$legF1->AddEntry($fDist->DrawCopy(), "N=1 M=1", "l");

$fDist->SetParameter(1, 10); 
$fDist->SetLineColor(2);
$legF1->AddEntry($fDist->DrawCopy("lsame"), "N=1 M=10", "l");

$fDist->SetParameters(10, 1);
$fDist->SetLineColor(8);
$legF1->AddEntry($fDist->DrawCopy("lsame"), "N=10 M=1", "l");

$fDist->SetParameters(10, 10);
$fDist->SetLineColor(4);
$legF1->AddEntry($fDist->DrawCopy("lsame"), "N=10 M=10", "l");

$legF1->Draw();

# drawing the set of F cumulative dist.functions
my $fDistI = TF1->new("fDist", "TMath::FDistI(x, [0], [1])", 0, 2);
$fDistI->SetTitle("Cumulative dist. function for F");
$fDistI->SetLineWidth(1);
my $legF2 = TLegend->new(0.7, 0.3, 0.89, 0.5);

my $pad4 = $DistCanvas->cd(4);
$pad4->SetFrameFillColor(19);
$pad4->SetGrid();
$fDistI->SetParameters(1, 1);
$fDistI->SetLineColor(1);
$legF2->AddEntry($fDistI->DrawCopy(), "N=1 M=1", "l");

$fDistI->SetParameters(1, 10); 
$fDistI->SetLineColor(2);
$legF2->AddEntry($fDistI->DrawCopy("lsame"), "N=1 M=10", "l");
  
$fDistI->SetParameters(10, 1); 
$fDistI->SetLineColor(8);
$legF2->AddEntry($fDistI->DrawCopy("lsame"), "N=10 M=1", "l");
 
$fDistI->SetParameters(10, 10); 
$fDistI->SetLineColor(4);
$legF2->AddEntry($fDistI->DrawCopy("lsame"), "N=10 M=10", "l");

$legF2->Draw();
$DistCanvas->Update();

$gApplication->Run;

