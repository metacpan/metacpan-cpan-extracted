# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

###################################################################################################
use strict;

use File::Compare;

use Test::More tests => 15;
use Test::Exception;

use Shatterproof;

my $SD;
my $mean;
my $expected_SD;
my $expected_mean;

my $delta = 1;

my @test_array;
my %test_hash;

dies_ok(sub{Shatterproof::standard_deviation_and_mean(\@test_array,1)}, 'standard_deviation_and_mean-1');
dies_ok(sub{Shatterproof::standard_deviation_and_mean(\@test_array,0)}, 'standard_deviation_and_mean-2');
dies_ok(sub{Shatterproof::standard_deviation_and_mean(\%test_hash,0)}, 'standard_deviation_and_mean-3');
dies_ok(sub{Shatterproof::standard_deviation_and_mean(\%test_hash,1)}, 'standard_deviation_and_mean-4');
dies_ok(sub{Shatterproof::standard_deviation_and_mean(\%test_hash,9)}, 'standard_deviation_and_mean-5');

@test_array = (13,23,12,44,55);
$expected_SD = 17.2116239791601;
$expected_mean = 29.4;

($SD,$mean) = Shatterproof::standard_deviation_and_mean(\@test_array,1);
ok(abs($SD - $expected_SD) < $delta, 'standard_deviation_and_mean-6');
ok(abs($mean - $expected_mean) < $delta, 'standard_deviation_and_mean-7');
dies_ok(sub{Shatterproof::standard_deviation_and_mean(\@test_array,0)}, 'standard_deviation_and_mean-8');

$test_hash{'key1'} = 13;
$test_hash{'key2'} = 23;
$test_hash{'key3'} = 12;
$test_hash{'key4'} = 44;
$test_hash{'key5'} = 55;

($SD,$mean) = Shatterproof::standard_deviation_and_mean(\%test_hash,0);
ok(abs($SD - $expected_SD) < $delta, 'standard_deviation_and_mean-9');
ok(abs($mean - $expected_mean) < $delta, 'standard_deviation_and_mean-10');
dies_ok(sub{Shatterproof::standard_deviation_and_mean(\%test_hash,1)}, 'standard_deviation_and_mean-11');

@test_array = (15,58,69,50,47,73);
$expected_SD = 18.9912260443255;
$expected_mean = 52;

($SD,$mean) = Shatterproof::standard_deviation_and_mean(\@test_array,1);
ok(abs($SD - $expected_SD) < $delta, 'standard_deviation_and_mean-12');
ok(abs($mean - $expected_mean) < $delta, 'standard_deviation_and_mean-13');

$test_hash{'key1'} = 15;
$test_hash{'key2'} = 58;
$test_hash{'key3'} = 69;
$test_hash{'key4'} = 50;
$test_hash{'key5'} = 47;
$test_hash{'key6'} = 73;

($SD,$mean) = Shatterproof::standard_deviation_and_mean(\%test_hash,0);
ok(abs($SD - $expected_SD) < $delta, 'standard_deviation_and_mean-14');
ok(abs($mean - $expected_mean) < $delta, 'standard_deviation_and_mean-15');
