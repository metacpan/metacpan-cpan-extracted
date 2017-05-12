use strict;
use warnings;
use SOOT ':all';
$gApplication->AsyncRun;

$gROOT->Reset();
my $c1 = TCanvas->new("c1","Analyze.mac",620,790);
$c1->Range(-1,0,19,30);
my $pl1 = TPaveLabel->new(0,27,3.5,29,"Analyze");
$pl1->SetFillColor(42);
$pl1->Draw();

my $pt1 = TPaveText->new(0,22.8,4,25.2);
my $t1  = $pt1->AddText("Parenthesis matching");
my $t2  = $pt1->AddText("Remove unnecessary");
my $t2a = $pt1->AddText("parenthesis");
$pt1->Draw();

my $pt2 = TPaveText->new(6,23,10,25);
my $t3  = $pt2->AddText("break of");
my $t3a = $pt2->AddText("Analyze");
$pt2->Draw();

my $pt3 = TPaveText->new(0,19,4,21);
my $t4  = $pt3->AddText("look for simple");
my $t5  = $pt3->AddText("operators");
$pt3->Draw();

my $pt4 = TPaveText->new(0,15,4,17);
my $t6  = $pt4->AddText("look for an already");
my $t7  = $pt4->AddText("defined expression");
$pt4->Draw();

my $pt5 = TPaveText->new(0,11,4,13);
my $t8  = $pt5->AddText("look for usual");
my $t9  = $pt5->AddText("functions :cos sin ..");
$pt5->Draw();

my $pt6 = TPaveText->new(0,7,4,9);
my $t10 = $pt6->AddText("look for a");
my $t11 = $pt6->AddText("numeric value");
$pt6->Draw();

my $pt7 = TPaveText->new(6,18.5,10,21.5);
my $t12 = $pt7->AddText("Analyze left and");
my $t13 = $pt7->AddText("right part of");
my $t14 = $pt7->AddText("the expression");
$pt7->Draw();

my $pt8 = TPaveText->new(6,15,10,17);
my $t15 = $pt8->AddText("Replace expression");
$pt8->Draw();

my $pt9 = TPaveText->new(6,11,10,13);
my $t16 = $pt9->AddText("Analyze");
$pt9->SetFillColor(42);
$pt9->Draw();

my $pt10 = TPaveText->new(6,7,10,9);
my $t17  = $pt10->AddText("Error");
my $t18  = $pt10->AddText("Break of Analyze");
$pt10->Draw();

my $pt11 = TPaveText->new(14,22,17,24);
$pt11->SetFillColor(42);
my $t19  = $pt11->AddText("Analyze");
my $t19a = $pt11->AddText("Left");
$pt11->Draw();

my $pt12 = TPaveText->new(14,19,17,21);
$pt12->SetFillColor(42);
my $t20  = $pt12->AddText("Analyze");
my $t20a = $pt12->AddText("Right");
$pt12->Draw();

my $pt13 = TPaveText->new(14,15,18,18);
my $t21  = $pt13->AddText("StackNumber++");
my $t22  = $pt13->AddText("operator[StackNumber]");
my $t23  = $pt13->AddText("= operator found");
$pt13->Draw();

my $pt14 = TPaveText->new(12,10.8,17,13.2);
my $t24  = $pt14->AddText("StackNumber++");
my $t25  = $pt14->AddText("operator[StackNumber]");
my $t26  = $pt14->AddText("= function found");
$pt14->Draw();

my $pt15 = TPaveText->new(6,7,10,9);
my $t27  = $pt15->AddText("Error");
my $t28  = $pt15->AddText("break of Analyze");
$pt15->Draw();

my $pt16 = TPaveText->new(0,2,7,5);
my $t29 = $pt16->AddText("StackNumber++");
my $t30 = $pt16->AddText("operator[StackNumber] = 0");
my $t31 = $pt16->AddText("value[StackNumber] = value found");
$pt16->Draw();

my $ar = TArrow->new(2,27,2,25.4,0.012,"|>");
$ar->SetFillColor(1);
$ar->Draw();
$ar->DrawArrow(2,22.8,2,21.2,0.012,"|>");
$ar->DrawArrow(2,19,2,17.2,0.012,"|>");
$ar->DrawArrow(2,15,2,13.2,0.012,"|>");
$ar->DrawArrow(2,11,2, 9.2,0.012,"|>");
$ar->DrawArrow(2, 7,2, 5.2,0.012,"|>");
$ar->DrawArrow(4,24,6,24,0.012,"|>");
$ar->DrawArrow(4,20,6,20,0.012,"|>");
$ar->DrawArrow(4,16,6,16,0.012,"|>");
$ar->DrawArrow(4,12,6,12,0.012,"|>");
$ar->DrawArrow(4, 8,6, 8,0.012,"|>");
$ar->DrawArrow(10,20,14,20,0.012,"|>");
$ar->DrawArrow(12,23,14,23,0.012,"|>");
$ar->DrawArrow(12,16.5,14,16.5,0.012,"|>");
$ar->DrawArrow(10,12,12,12,0.012,"|>");

my $ta = TText->new(2.2,22.2,"err = 0");
$ta->SetTextFont(71);
$ta->SetTextSize(0.015);
$ta->SetTextColor(4);
$ta->SetTextAlign(12);
$ta->Draw();
$ta->DrawText(2.2,18.2,"not found");
$ta->DrawText(2.2,6.2,"found");

my $tb = TText->new(4.2,24.1,"err != 0");
$tb->SetTextFont(71);
$tb->SetTextSize(0.015);
$tb->SetTextColor(4);
$tb->SetTextAlign(11);
$tb->Draw();
$tb->DrawText(4.2,20.1,"found");
$tb->DrawText(4.2,16.1,"found");
$tb->DrawText(4.2,12.1,"found");
$tb->DrawText(4.2, 8.1,"not found");
my $l1 = TLine->new(12,16.5,12,23);
$l1->Draw();

$c1->Update();
$gApplication->wait;

