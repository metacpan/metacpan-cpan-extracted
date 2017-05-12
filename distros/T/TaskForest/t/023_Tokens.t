# -*- perl -*-

my $SLEEP_TIME = 2;
use Test::More tests => 5;

use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;

BEGIN {
    use_ok( 'TaskForest'  );
}

&TaskForest::LocalTime::setTime( { year  => 2009,
                                   month => 04,
                                   day   => 12,
                                   hour  => 22,
                                   min   => 30,
                                   sec   => 57,
                                   tz    => 'America/Chicago',
                                 });
                                       
my $cwd = getcwd();
my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

&TaskForest::Test::cleanup_files($dest_dir);
copy("$src_dir/TOKENS", $dest_dir);


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";
$ENV{TF_CONFIG_FILE} = "$cwd/taskforest.test.cfg";
$ENV{TF_ONCE_ONLY} = 1;

#exit; 

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, 'America/Chicago');
&TaskForest::Test::cleanup_files($log_dir);

my $tf = TaskForest->new();
isa_ok($tf,  'TaskForest',  'TaskForest created successfully');

$tf->{options}->{once_only} = 1;

my $options = &TaskForest::Options::getOptions();

print Dumper($options);
#exit 0;

print "Running ready jobs\n";
$tf->runMainLoop();
$tf->{options}->{once_only} = 1;
ok(&TaskForest::Test::waitForFiles(file_list => [
                                       "$log_dir/TOKENS.J1.0",
                                       "$log_dir/TOKENS.J3.0",
                                       "$log_dir/TOKENS.J4.0",
                                       "$log_dir/TOKENS.J7.0",
                                       "$log_dir/TOKENS.J8.0",
                                   ]), "After first cycle, jobs J1, J3, J4, J7, J8 ran successfully");

print "Running ready jobs\n";
$tf->runMainLoop();
$tf->{options}->{once_only} = 1;
ok(&TaskForest::Test::waitForFiles(file_list => [
                                       "$log_dir/TOKENS.J2.0",
                                       "$log_dir/TOKENS.J5.0",
                                       "$log_dir/TOKENS.J9.0",
                                   ]), "After second cycle, jobs J2, J5 and J9 ran successfully");

print "Running ready jobs\n";
$tf->runMainLoop();
$tf->{options}->{once_only} = 1;
ok(&TaskForest::Test::waitForFiles(file_list => [
                                       "$log_dir/TOKENS.J6.0",
                                       "$log_dir/TOKENS.J10.0",
                                       "$log_dir/TOKENS.J11.0",
                                   ]), "After third cycle, jobs J6, J10 and J11 ran successully");





&TaskForest::Test::cleanup_files($log_dir);
