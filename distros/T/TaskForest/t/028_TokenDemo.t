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

my $cwd = getcwd();
my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

&TaskForest::Test::cleanup_files($dest_dir);
copy("$src_dir/TOKENDEMO", $dest_dir);


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run_with_log";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";
$ENV{TF_CONFIG_FILE} = "$cwd/taskforest.test.cfg";
$ENV{TF_ONCE_ONLY} = 1;

#exit; 

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, "GMT");
&TaskForest::Test::cleanup_files($log_dir);

my $tf = TaskForest->new();
isa_ok($tf,  'TaskForest',  'TaskForest created successfully');

$tf->{options}->{once_only} = 1;

my $options = &TaskForest::Options::getOptions();

#print Dumper($options);
#exit 0;

print "Looking for $log_dir/TOKENDEMO.J1.0\n";
print "Running ready jobs - first cycle\n";
$tf->runMainLoop();
$tf->{options}->{once_only} = 1;
ok(&TaskForest::Test::waitForFiles(file_list => [
                                       "$log_dir/TOKENDEMO.J1.0",
                                       "$log_dir/TOKENDEMO.J3.0",
                                       "$log_dir/TOKENDEMO.J4.0",
                                       "$log_dir/TOKENDEMO.J5.0",                                       
                                   ]), "After first cycle, J1, J3, J4, J5 ran successfully" );

print "\n\nRunning ready jobs - second cycle\n";
$tf->runMainLoop();
$tf->{options}->{once_only} = 1;
ok(&TaskForest::Test::waitForFiles(file_list => [
                                       "$log_dir/TOKENDEMO.J2.0",
                                       "$log_dir/TOKENDEMO.J6.0",
                                   ]), " After second cycle, J2 and J6 ran successfully");

print "\n\nRunning ready jobs - third cycle\n";
$tf->runMainLoop();
$tf->{options}->{once_only} = 1;
ok(&TaskForest::Test::waitForFiles(file_list => ["$log_dir/TOKENDEMO.J8.0"]), "After third cycle, J8 ran successfully");

&TaskForest::Test::cleanup_files($log_dir);
