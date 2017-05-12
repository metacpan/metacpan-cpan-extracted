use strict;
use warnings;
use SOOT ':all';
use threads;
use Time::HiRes 'usleep';

my $sw = TStopwatch->new(); 
$sw->Start();

# set time offset
#my $dtime = TDatime->new(); # FIXME TDatime not wrapped (not a TObject), but utterly superseded by Perl-tools
$gStyle->SetTimeOffset(time()); # We could be more elaborate. Check out DateTime.pm

my $c1 = TCanvas->new("c1","Time on axis",10,10,1000,500);
$c1->SetFillColor(42);
$c1->SetFrameFillColor(33);
$c1->SetGrid();
   
my $bintime = 1; # one bin = 1 second. change it to set the time scale
my $ht = TH1F->new("ht","The ROOT seism",10,0,10*$bintime);
my $signal = 1000.0;

$ht->SetMaximum($signal);
$ht->SetMinimum(-$signal);
$ht->SetStats(0);
$ht->SetLineColor(2);
$ht->GetXaxis()->SetTimeDisplay(1);
$ht->GetYaxis()->SetNdivisions(520);
$ht->Draw();
   
my $thr = threads->new(sub {$gApplication->Run()}); #canvas can be edited during the loop
usleep(5000); # FIXME find better way to fix this
$gApplication->SetReturnFromRun(1);

for my $i (1..2299) {
  #======= Build a signal : noisy damped sine ======
  my $noise = $gRandom->Gaus(0,120);
  $noise += $signal*sin(($i-700.)*6.28/30)*exp((700.-$i)/300.) if $i > 700;
  $ht->SetBinContent($i,$noise);
  $c1->Modified();
  $c1->Update();
}
print sprintf("Real Time = %8.3fs, Cpu Time = %8.3fs\n",$sw->RealTime(),$sw->CpuTime());

$gApplication->Terminate();
$thr->join();

