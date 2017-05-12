use strict;
use warnings;
use Test::More;
use SOOT qw/:all/;

my $th1d = TH1D->new("foo", "bar", 10, 0., 10.);
isa_ok($th1d, $_) for qw(TH1D TH1 TObject); 

my $clone = $th1d->Clone;
isa_ok($clone, $_) for qw(TH1D TH1 TObject); 

#my $cv = TCanvas->new;
$|=1;
print STDERR "#";
$clone = $th1d->DrawClone("l"); # Damn chatty ROOT
print STDERR "#\n";
isa_ok($clone, $_) for qw(TH1D TH1 TObject); 

my $found = $gROOT->FindObject("foo");
isa_ok($found, $_) for qw(TH1D TH1 TObject); 

$found = $gROOT->FindObject("asdasda");
ok(!defined($found));

# Not implemented in ROOT
#$found = $gROOT->FindObject($th1d);
#isa_ok($found, $_) for qw(TH1D TH1 TObject); 

# Test Fit (seen segfaults here)
my $n1 = 10;
my $x1  = [-0.1, 0.05, 0.25, 0.35, 0.5, 0.61,0.7,0.85,0.89,0.95];
my $y1  = [-1.,2.9,5.6,7.4,9,9.6,8.7,6.3,4.5,1];
my $ex1 = [.05,.1,.07,.07,.04,.05,.06,.07,.08,.05];
my $ey1 = [.8,.7,.6,.5,.4,.4,.5,.6,.7,.8];
my $gr1 = TGraphErrors->new($n1,$x1,$y1,$ex1,$ey1);
my $obj = $gr1->Fit("pol6","q");
ok(!defined $obj);
$obj = $gr1->Fit("pol6", "qS");
isa_ok($obj, $_) for qw(TFitResult TObject);


done_testing();
