# -*- perl -*-

my $SLEEP_TIME = 2;
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
copy("$src_dir/SIMPLE_C", $dest_dir);


&TaskForest::LocalTime::setTime( { year  => 2009,
                                   month => 05,
                                   day   => 04,
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

print "Waiting  for job to finish\n";

ok(&TaskForest::Test::waitForFiles(file_list => [
                                       "$log_dir/SIMPLE_C.J2.0",
                                       "$log_dir/SIMPLE_C.J3.0",
                                       "$log_dir/SIMPLE_C.J6.0",
                                       "$log_dir/SIMPLE_C.J7.0",
                                       "$log_dir/SIMPLE_C.J9.0",
                                   ]), "After first cycle, jobs J2, J3, J6, J7 and J9 ran successfully");




&TaskForest::Test::cleanup_files($log_dir);
