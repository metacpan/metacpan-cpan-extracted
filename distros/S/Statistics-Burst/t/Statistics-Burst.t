# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Statistics-Burst.t'

#########################

# change 'tests => 3' to 'tests => last_test_to_print';
use Data::Dumper;
use Test::More tests => 3;
BEGIN { use_ok('Statistics::Burst') };

#########################

my $inputData=[9,9,10,10,14,5,2,2,2,2,7,5,9,9,9];
my $burstObj=Statistics::Burst::new();
$burstObj->generateStates(3,.111,2);
#Test to see if two states exists and verify their values
$burstObj->gamma(.5);
ok ($burstObj->{gamma}==0.5);
$burstObj->setData($inputData);
$burstObj->process();
my $i=0;
my $value=0;
map {$value+=(($_*3) ** $i);$i++} @{$burstObj->getStatesUsed()};
ok($value==29161, 'Final Calculation');
