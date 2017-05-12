#!/usr/bin/env perl

use File::Which;
use Test::More tests => 2;
use File::Temp qw{ tempdir };

########################################
use_ok('Monitoring::Generator::TestConfig');
my $test_dir = tempdir(CLEANUP => 1);

my $mgt = Monitoring::Generator::TestConfig->new( 'output_dir' => $test_dir, 'overwrite_dir' => 1 );
isa_ok($mgt, 'Monitoring::Generator::TestConfig');
$mgt->create();
