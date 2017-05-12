# -*- perl -*-

my $SLEEP_TIME = 5;
use Test::More tests => 3;

use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;

BEGIN {
    use_ok( 'TaskForest'  );
}


my $cwd = getcwd();
my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

&TaskForest::Test::cleanup_files($dest_dir);
copy("$src_dir/SIMPLE_C_WEEKDAYS", $dest_dir);


&TaskForest::LocalTime::setTime( { year  => 2009,
                                   month => 05,
                                   day   => 03,
                                   hour  => 10,
                                   min   => 10,
                                   sec   => 10,
                                   tz    => 'America/Chicago',
                                 });
                                       


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";
$ENV{TF_CONFIG_FILE} = "$cwd/taskforest.test.cfg";
$ENV{TF_ONCE_ONLY} = 1;

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, 'America/Chicago');
&TaskForest::Test::cleanup_files($log_dir);


my $tf = TaskForest->new();
isa_ok($tf,  'TaskForest',  'TaskForest created successfully');

$tf->{options}->{once_only} = 1;

print "Running ready jobs\n";
$tf->runMainLoop();

$tf->{options}->{once_only} = 1;

print "Waiting $SLEEP_TIME seconds for job to finish\n";

my $num_tries = 10;
sleep $SLEEP_TIME;
my $a = 0;
if (-e "$log_dir/SIMPLE_C_WEEKDAYS.J2.pid" or
    -e "$log_dir/SIMPLE_C_WEEKDAYS.J3.pid" or
    -e "$log_dir/SIMPLE_C_WEEKDAYS.J6.pid" or
    -e "$log_dir/SIMPLE_C_WEEKDAYS.J7.pid" or
    -e "$log_dir/SIMPLE_C_WEEKDAYS.J9.pid") {
    $a = 1;
}

ok($a == 0, "Nothing ran");




&TaskForest::Test::cleanup_files($log_dir);
