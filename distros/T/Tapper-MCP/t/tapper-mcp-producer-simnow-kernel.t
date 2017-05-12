#! /usr/bin/env perl

use strict;
use warnings;


# get rid of warnings
use Class::C3;
use MRO::Compat;


use Tapper::Model 'model';

use Test::Fixture::DBIC::Schema;
use Tapper::Schema::TestTools;
use Tapper::Producer::SimnowKernel;
use Tapper::Config;

use Test::More;
use YAML;

# --------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_scheduling_run2.yml' );
# --------------------------------------------------------------------------------

Tapper::Config->subconfig->{paths}{package_dir}='t/misc_files/simnowkernel_producer/';
qx(touch t/misc_files/simnowkernel_producer/kernel/simnow/kernel_file3.tar.gz);  # make sure file3 is the newest

my $host = bless{name => 'bullock'};
my $job  = bless{host => $host};

my $producer     = Tapper::Producer::SimnowKernel->new();
my $precondition = $producer->produce($job, {});

is(ref $precondition, 'HASH', 'Producer / returned hash');


my @yaml = Load($precondition->{precondition_yaml});
is( $yaml[0]->{precondition_type}, 'package', 'Precondition 1 / precondition type');
is( $yaml[0]->{filename}, 'kernel/simnow/kernel_file3.tar.gz', 'Precondition 1/ file name');

is( $yaml[1]->{precondition_type}, 'exec', 'Precondition 2/ precondition type');
is( $yaml[1]->{options}->[0], '2.6.29-file3', 'Precondition 2/ options');

done_testing();
