
use strict;
use warnings;
use SOOT qw/:all/;
SOOT::Init(1);
use SOOT::Struct;
use Data::Dumper;
my $struct = SOOT::Struct->new(
  name => 'car_t',
  fields => [
    'age_years'  => 'UInt_t',
    'top_speed' => 'Double_t',
  ],
);
$struct->compile;

my $file = TFile->new("t.root","recreate");
my $tree = TTree->new("T", "test");
my $car = car_t->new;
my $branch = $tree->StructBranch("car", $car);

foreach (0..50000) {
  my $age = int(rand 20);
  my $top_speed = 250-$age*15 + rand($age*10); # whatever
  $car->age_years($age);
  $car->top_speed($top_speed);
  $tree->Fill;
}

$tree->Write();
$tree->Draw("top_speed:age_years", "", "COLZ");
SOOT->Run;


