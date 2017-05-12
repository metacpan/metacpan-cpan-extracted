use strict;
use warnings;
use SOOT ':all';

$gROOT->Reset();
my $c1 = TCanvas->new("c1","Dictionary Architecture",20,10,750,930);
$c1->SetBorderSize(0);
$c1->Range(0,0,20.5,26);

my $title = TPaveLabel->new(4,24,16,25.5,$c1->GetTitle());
$title->SetFillColor(46);
$title->Draw();

my $dll = TPavesText->new(0.5,19,4.5,23,5,"tr");
$dll->SetFillColor(39);
$dll->SetTextSize(0.023);
$dll->AddText(" ");
$dll->AddText("Dynamically");
$dll->AddText("Linked");
$dll->AddText("Libraries");
$dll->Draw();

my $dlltitle = TPaveLabel->new(1.5,22.6,3.5,23.3,"DLLs");
$dlltitle->SetFillColor(28);
$dlltitle->Draw();

my $cpp = TPavesText->new(5.5,19,9.5,23,5,"tr");
$cpp->SetTextSize(0.023);
$cpp->AddText(" ");
$cpp->AddText("Commented");
$cpp->AddText("Header");
$cpp->AddText("Files");
$cpp->Draw();

my $ cpptitle = TPaveLabel->new(6.5,22.6,8.5,23.3,"C++");
$cpptitle->SetFillColor(28);
$cpptitle->Draw();

my $odl = TPavesText->new(10.5,19,14.5,23,5,"tr");
$odl->SetTextSize(0.023);
$odl->AddText(" ");
$odl->AddText("Objects");
$odl->AddText("Description");
$odl->AddText("Files");
$odl->Draw();

my $odltitle = TPaveLabel->new(11.5,22.6,13.5,23.3,"ODL");
$odltitle->SetFillColor(28);
$odltitle->Draw();

my $idl = TPavesText->new(15.5,19,19.5,23,5,"tr");
$idl->SetTextSize(0.023);
$idl->AddText(" ");
$idl->AddText("Interface");
$idl->AddText("Definition");
$idl->AddText("Language");
$idl->Draw();

my $idltitle = TPaveLabel->new(16.5,22.6,18.5,23.3,"IDL");
$idltitle->SetFillColor(28);
$idltitle->Draw();

my $p1  = TWbox->new(7.8,10,13.2,17,11,12,1);
$p1->Draw();
my $pro1 = TText->new(10.5,15.8,"Process 1");
$pro1->SetTextAlign(21);
$pro1->SetTextSize(0.03);
$pro1->Draw();

my $p1dict = TPaveText->new(8.8,13.8,12.2,15.6);
$p1dict->SetTextSize(0.023);
$p1dict->AddText("Dictionary");
$p1dict->AddText("in memory");
$p1dict->Draw();

my $p1object = TPavesText->new(8.6,10.6,12.1,13.0,5,"tr");
$p1object->SetTextSize(0.023);
$p1object->AddText("Objects");
$p1object->AddText("in memory");
$p1object->Draw();

my $p2 = TWbox->new(15.5,10,20,17,11,12,1);
$p2->Draw();

my $pro2 = TText->new(17.75,15.8,"Process 2");
$pro2->SetTextAlign(21);
$pro2->SetTextSize(0.03);
$pro2->Draw();

my $p2dict = TPaveText->new(16,13.8,19.5,15.6);
$p2dict->SetTextSize(0.023);
$p2dict->AddText("Dictionary");
$p2dict->AddText("in memory");
$p2dict->Draw();

my $p2object = TPavesText->new(16.25,10.6,19.25,13.0,5,"tr");
$p2object->SetTextSize(0.023);
$p2object->AddText("Objects");
$p2object->AddText("in memory");
$p2object->Draw();

my $stub1 = TWbox->new(12.9,11.5,13.6,15.5,49,3,1);
$stub1->Draw();
my $tstub1 = TText->new(13.25,13.5,"Stub1");
$tstub1->SetTextSize(0.025);
$tstub1->SetTextAlign(22);
$tstub1->SetTextAngle(90);
$tstub1->Draw();

my $stub2 = TWbox->new(15.1,11.5,15.8,15.5,49,3,1);
$stub2->Draw();

my $tstub2 = TText->new(15.45,13.5,"Stub2");
$tstub2->SetTextSize(0.025);
$tstub2->SetTextAlign(22);
$tstub2->SetTextAngle(-90);
$tstub2->Draw();

my $ar1 = TArrow->new;
$ar1->SetLineWidth(6);
$ar1->SetLineColor(1);
$ar1->SetFillStyle(1001);
$ar1->SetFillColor(1);
$ar1->DrawArrow(13.5,14,15,14,0.012,"|>");
$ar1->DrawArrow(15.1,13,13.51,13,0.012,"|>");

my $cint = TPaveText->new(1.0,15.0,8.0,17.5);
$cint->SetFillColor(39);
$cint->SetBorderSize(1);
$cint->SetTextSize(0.023);
$cint->AddText("C++ Interpreter");
$cint->AddText("and program builder");
$cint->Draw();

my $command = TPaveText->new(2.5,13.4,8.0,14.5);
$command->SetTextSize(0.023);
$command->SetFillColor(39);
$command->SetBorderSize(1);
$command->AddText("Command Thread");
$command->Draw();

my $view = TPavesText->new(1.0,9.5,7.7,12.6,3,"tr");
$view->SetFillColor(39);
$view->SetBorderSize(2);
$view->SetTextSize(0.023);
$view->AddText("Viewer Thread(s)");
$view->AddText("Picking");
$view->AddText("Context Menus");
$view->AddText("Inspector/Browser");
$view->Draw();

my $web = TPavesText->new(0.5,5,6,8.5,5,"tr");
$web->SetTextSize(0.023);
$web->AddText(" ");
$web->AddText("generated");
$web->AddText("automatically");
$web->AddText("from dictionary");
$web->AddText("and source files");
$web->Draw();

my $webtitle = TPaveLabel->new(1.5,8.1,5.0,8.8,"HTML Files");
$webtitle->SetFillColor(28);
$webtitle->Draw();

my $printed = TPavesText->new(0.5,1.0,6,4,5,"tr");
$printed->SetTextSize(0.023);
$printed->AddText(" ");
$printed->AddText("generated");
$printed->AddText("automatically");
$printed->AddText("from HTML files");
$printed->Draw();

my $printedtitle = TPaveLabel->new(1.5,3.6,5.0,4.3,"Printed Docs");
$printedtitle->SetFillColor(28);
$printedtitle->Draw();

my $box1 = TBox->new(0.2,9.2,14.25,17.8);
$box1->SetFillStyle(0);
$box1->SetLineStyle(2);
$box1->Draw();

my $box2 = TBox->new(10.2,18.7,20.2,23.6);
$box2->SetFillStyle(0);
$box2->SetLineStyle(3);
$box2->Draw();

$ar1->DrawArrow(2.5,17.5,2.5,18.9,0.012,"|>");
$ar1->DrawArrow(5.5,9.2,5.5,8.7,0.012,"|>");
$ar1->DrawArrow(5.5,5,5.5,4.2,0.012,"|>");
$ar1->DrawArrow(8.5,9.2,8.5,8.2,0.012,"|>");
$ar1->DrawArrow(9.5,8.1,9.5,9.0,0.012,"|>");
$ar1->DrawArrow(6.5,19,6.5,17.6,0.012,"|>");
$ar1->DrawArrow(8.5,19,8.5,17.1,0.012,"|>");
$ar1->DrawArrow(11.5,19,11.5,17.1,0.012,"|>");


my $ootitle = TPaveLabel->new(10.5,7.8,17,8.8,"Objects Data Base");
$ootitle->SetFillColor(28);
$ootitle->Draw();

my $pio = TPad->new("pio","pio",0.37,0.02,0.95,0.31,49);
$pio->Range(0,0,12,8);
$pio->Draw();
$pio->cd();

my $raw = TPavesText->new(0.5,1,2.5,6,7,"tr");
$raw->Draw();

my $dst1 = TPavesText->new(4,1,5,3,7,"tr");
$dst1->Draw();

my $dst2 = TPavesText->new(6,1,7,3,7,"tr");
$dst2->Draw();

my $dst3 = TPavesText->new(4,4,5,6,7,"tr");
$dst3->Draw();

my $dst4 = TPavesText->new(6,4,7,6,7,"tr");
$dst4->Draw();

my $xlow = 8.5;
my $ylow = 1;
my $dx   = 0.5;
my $dy   = 0.5;
for my $j (1..8) {
  my $y0 = $ylow + ($j-1)*0.7;
  my $y1 = $y0 + $dy;
  for my $i (1..4) {
     my $x0 = $xlow +($i-1)*0.6;
     my $x1 = $x0 + $dx;
     my $anal = TPavesText->new($x0,$y0,$x1,$y1,7,"tr");
     $anal->Draw();
  }
}
my $daq = TText->new();
$daq->SetTextSize(0.07);
$daq->SetTextAlign(22);
$daq->DrawText(1.5,7.3,"DAQ");
$daq->DrawText(6,7.3,"DST");
$daq->DrawText(10.,7.3,"Physics Analysis");
$daq->DrawText(1.5,0.7,"Events");
$daq->DrawText(1.5,0.3,"Containers");
$daq->DrawText(6,0.7,"Tracks/Hits");
$daq->DrawText(6,0.3,"Containers");
$daq->DrawText(10.,0.7,"Attributes");
$daq->DrawText(10.,0.3,"Containers");

$c1->cd();

$gApplication->Run;
