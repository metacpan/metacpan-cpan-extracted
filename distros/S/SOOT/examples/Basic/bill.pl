use strict;
use warnings;
use Math::Trig;
use SOOT ':all';

my ($kFALSE, $kTRUE) = (0,1);

##// benchmark comparing write/read to/from keys or trees
##// for example for N=10000, the following output is produced
##// on a P IV 62.4GHz
##   
##// root -b -q bill.C    or root -b -q bill.C++
##//
##//billw0  : RT=  1.070 s, Cpu=  1.050 s, File size=  45508003 bytes, CX= 1
##//billr0  : RT=  0.740 s, Cpu=  0.730 s
##//billtw0 : RT=  0.720 s, Cpu=  0.660 s, File size=  45163959 bytes, CX= 1
##//billtr0 : RT=  0.420 s, Cpu=  0.420 s
##//billw1  : RT=  6.600 s, Cpu=  6.370 s, File size=  16215349 bytes, CX= 2.80687
##//billr1  : RT=  2.290 s, Cpu=  2.270 s
##//billtw1 : RT=  3.260 s, Cpu=  3.230 s, File size=   6880273 bytes, CX= 6.5642
##//billtr1 : RT=  0.990 s, Cpu=  0.980 s
##//billtot : RT= 18.290 s, Cpu= 15.920 s
##//******************************************************************
##//*  ROOTMARKS = 600.9   *  Root3.05/02   20030201/1840
##//******************************************************************

my $N = 10000;       #number of events to be processed
my $timer = TStopwatch->new();
print $timer, "\n";
bill();

# write N histograms as keys
sub billw {
  my $compress = shift;
  $timer->Start();
  my $f = TFile->new("/tmp/bill.root","recreate","bill benchmark with keys",$compress);
  my $h = TH1F->new("h","h",1000,-3,3);
  $h->FillRandom("gaus", 50000);
   
  for my $i (0..$N-1) {
    my $name = sprintf("h%d", $i);
    $h->SetName($name);
    $h->Fill(2*$gRandom->Rndm());
    $h->Write();
  }
  $timer->Stop();
  printf("billw%d  : RT=%7.3f s, Cpu=%7.3f s, File size= %9d bytes, CX= %g\n",
           $compress,
           $timer->RealTime(), 
           $timer->CpuTime(),
           $f->GetBytesWritten(),
           $f->GetCompressionFactor());

  $f->Close();
}

# read N histograms from keys
sub billr {
  my $compress = shift;
  $timer->Start();
  my $f = TFile->new("/tmp/bill.root");
  my $lst = $f->GetListOfKeys();
  my $nobj = $lst->GetSize();

  my $hx = TH1F->new('hx','h',100,0,1);
  $hx->AddDirectory($kFALSE);

  my $hmean = TH1F->new("hmean","hist mean from keys",100,0,1);
   
  my $h;
  for my $i (0..$nobj-1) {
    my $name = sprintf("h%d", $i);
    $h = $f->Get($name);
    $hmean->Fill($h->GetMean(), 1.0);
  }
  $timer->Stop();
  printf("billr%d  : RT=%7.3f s, Cpu=%7.3f s\n", $compress, $timer->RealTime(), 
                                                            $timer->CpuTime());
}
# write N histograms to a Tree
sub billtw {
  my $compress = shift;
  $timer->Start();
  my $f = TFile->new("/tmp/billt.root","recreate","bill benchmark with trees",$compress);
  my $h = TH1F->new("h","h",1000,-3,3);
  $h->FillRandom("gaus",50000);
  my $T = TTree->new("T","test bill");
  $T->Branch("event","TH1F",$h,64000,0);
  for my $i (0..$N) {
    my $name = sprintf("h%d",$i);
    $h->SetName($name);
    $h->Fill(2*$gRandom->Rndm());
    $T->Fill();
  }
  $T->Write();
  $timer->Stop();
  printf("billtw%d : RT=%7.3f s, Cpu=%7.3f s, File size= %9d bytes, CX= %g\n",
    $compress,
    $timer->RealTime(),
    $timer->CpuTime(),
    $f->GetBytesWritten(),
    $f->GetCompressionFactor());
}
sub billtr {
  my $compress = shift;
}
sub bill {
   my $totaltimer = TStopwatch->new();
   $totaltimer->Start();
   for my $compress (0..2) {
     billw($compress);
     billr($compress);
#     billtw($compress);
#     billtr($compress);
   }
   $gSystem->Unlink("/tmp/bill.root");
   $gSystem->Unlink("/tmp/billt.root");
   $totaltimer->Stop();
   my $rtime = $totaltimer->RealTime();
   my $ctime = $totaltimer->CpuTime();
   printf("billtot : RT=%7.3f s, Cpu=%7.3f s\n",$rtime,$ctime);
   # reference is a P IV 2.4 GHz
   my $rootmarks = 600*(16.98 + 14.40)/($rtime + $ctime);
   printf("******************************************************************\n");
   printf("*  ROOTMARKS =%6.1f   *  Root%-8s  %d/%d\n",
        $rootmarks, $gROOT->GetVersion(),
                    $gROOT->GetVersionDate(), 
                    $gROOT->GetVersionTime());
   printf("******************************************************************\n");
}
