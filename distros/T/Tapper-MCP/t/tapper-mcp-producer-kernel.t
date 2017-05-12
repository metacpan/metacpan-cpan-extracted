#! /usr/bin/env perl

use strict;
use warnings;


# get rid of warnings
use Class::C3;
use MRO::Compat;


use Tapper::Model 'model';

use Test::Fixture::DBIC::Schema;
use Tapper::Schema::TestTools;
use Tapper::Producer::Kernel;
use Tapper::Config;

use Test::More;
use YAML;

# --------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema,  fixture => 't/fixtures/testrundb/testrun_with_scheduling_run2.yml' );
# --------------------------------------------------------------------------------

Tapper::Config->subconfig->{paths}{package_dir}='t/misc_files/kernel_producer/';
qx(touch t/misc_files/kernel_producer/kernel/x86_64/kernel_file3.tar.gz);  # make sure file3 is the newest

my $host = bless{name => 'bullock'};
my $job  = bless{host => $host};

my $producer     = Tapper::Producer::Kernel->new();
my $precondition = $producer->produce($job, {});

is(ref $precondition, 'HASH', 'Producer / returned hash');


my @yaml = Load($precondition->{precondition_yaml});
is( $yaml[0]->{precondition_type}, 'package', 'Precondition 1 / precondition type');
is( $yaml[0]->{filename}, 'kernel/x86_64/kernel_file3.tar.gz', 'Precondition 1/ file name');

is( $yaml[1]->{precondition_type}, 'exec', 'Precondition 2/ precondition type');
is( $yaml[1]->{options}->[0], '2.6.29-file3', 'Precondition 2/ options');

# enforce date order
qx(touch -d "010101" t/misc_files/kernel_producer/kernel/stable/i686/kernel-2.6.31-dontuse.tar.gz);
qx(touch -d "020202" t/misc_files/kernel_producer/kernel/stable/i686/kernel-2.6.31-use.tar.gz);
qx(touch -d "030303" t/misc_files/kernel_producer/kernel/stable/i686/kernel-2.6.32-dontuse.tar.gz);

$precondition = $producer->produce($job,
                                   { precondition_type => 'produce',
                                     producer => 'Kernel',
                                     arch=> 'i686',
                                     version=> '2.6.31',
                                     stable => 1,
                                   });
is(ref $precondition, 'HASH', 'Producer / returned hash');


@yaml = Load($precondition->{precondition_yaml});
is( $yaml[0]->{precondition_type}, 'package', 'Precondition 1 / precondition type');
is( $yaml[0]->{filename}, 'kernel/stable/i686/kernel-2.6.31-use.tar.gz', 'Precondition 1/ file name');

is( $yaml[1]->{precondition_type}, 'exec', 'Precondition 2/ precondition type');
is( $yaml[1]->{options}->[0], '2.6.31-file2', 'Precondition 2/ options');

done_testing();
