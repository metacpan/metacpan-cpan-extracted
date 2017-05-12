use strict;
use warnings;
use SOOT ':all';

my $c1 = TCanvas->new("c1","Dynamic Filling Example",200,10,700,500);
$c1->SetFillColor(42);

# Create some histograms
my $background = TH1D->new("background","The expected background",30,-4,4);
my $signal     = TH1D->new("signal","the expected signal",30,-4,4);
my $data       = TH1D->new("data","some fake data points",30,-4,4);
$background->SetFillColor(48);
$signal->SetFillColor(41);
$data->SetMarkerStyle(21);
$data->SetMarkerColor(kBlue);
$background->Sumw2; # needed for stat uncertainty
$signal->Sumw2;     # needed for stat uncertainty

# Fill histograms randomly
my $r = TRandom->new;
my ($bg, $sig, $dt);
for (0..24999) {
  $bg  = $r->Gaus(0.,1.)*1.0;
  $sig = $r->Gaus(1.,.2)*1.0;
  $background->Fill($bg,0.02);
  $signal->Fill($sig,0.001);
}
for (0..499) {
  $dt = $r->Gaus(0.,1.)*1.0;
  $data->Fill($dt,1.0);
}

my $hs = THStack->new("hs","Signal and background compared to data...");
$hs->Add($background);
$hs->Add($signal);
$hs->Draw("hist");
$data->Draw("PE1,Same");

$c1->Modified;
$c1->Update;

my $frame = $c1->GetFrame;
$frame->SetFillColor(21); 
$frame->SetBorderSize(6);
$frame->SetBorderMode(-1);
$c1->Modified;
$c1->Update;

$gSystem->ProcessEvents;

# Compute the limits
my $ds = TLimitDataSource->new($signal, $background, $data);
my $l  = TLimit->new();

my $cl = $l->ComputeLimit($ds, 50000);
printCL($cl, "Computing limits...");

# Add stat uncertainty
my $scl = $l->ComputeLimit($ds,50000,1);
printCL($scl, "Computing limits with stat systematics...");


# Add some systematics
my $errorb = TH1D->new("errorb","errors on background",1,0,1);
my $errors = TH1D->new("errors","errors on signal",1,0,1);
my $names  = TObjArray->new;
my $name1  = TObjString->new("bg uncertainty");
my $name2  = TObjString->new("sig uncertainty");
$names->AddLast($name1);
$names->AddLast($name2);
$errorb->SetBinContent(0,0.05); # error source 1: 5%
$errorb->SetBinContent(1,0);    # error source 2: 0%
$errors->SetBinContent(0,0);    # error source 1: 0%
$errors->SetBinContent(1,0.01); # error source 2: 1%

my $nds  = TLimitDataSource->new;
$nds->AddChannel(
  $signal, $background, $data,
  TVectorD->new($errors->GetNbinsX(), $errors->GetArray()), # FIXME AddChannel expects a TVectorD argument, but that's really TVectorT<double>, which is templated and not really supported by SOOT...
  TVectorD->new($errorb->GetNbinsX(), $errorb->GetArray()),
  $names
);

my $ncl = $l->ComputeLimit($nds,50000,1);
printCL($ncl, "Computing limits with systematics...");

# show canonical -2lnQ plots in a new canvas
# - The histogram of -2lnQ for background hypothesis (full)
# - The histogram of -2lnQ for signal and background hypothesis (dashed)
my $c2 = TCanvas->new("c2");
$cl->Draw;

$gApplication->Run;

sub printCL {
  my ($obj, $anot) = @_;
  print "== ", $anot, " ==\n";
  print "CLs    : ", $obj->CLs,  "\n";
  print "CLsb   : ", $obj->CLsb, "\n";
  print "CLb    : ", $obj->CLb,  "\n";
  print "<CLs>  : ", $obj->GetExpectedCLs_b,  "\n";
  print "<CLsb> : ", $obj->GetExpectedCLsb_b, "\n";
  print "<CLb>  : ", $obj->GetExpectedCLb_b,  "\n\n";
}

