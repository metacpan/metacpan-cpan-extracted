# -*- perl -*-

# 
use Test::More tests => 13;
use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;
use TaskForest::LocalTime;

BEGIN {
    use_ok( 'TaskForest',             "Can use TaskForest" );
    use_ok( 'TaskForest::Family',     "Can use Family" );
    use_ok( 'TaskForest::LogDir',     "Can use LogDir" );
    use_ok( 'TaskForest::StringHandle',     "Can use StringHandle" );
}

my $cwd = getcwd();

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;
&TaskForest::Test::cleanup_files("$cwd/t/families");

copy("$src_dir/EXTERNAL_1", $dest_dir);
copy("$src_dir/EXTERNAL_MULTIPLE_SECTIONS", $dest_dir);


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR}     = "$cwd/t/logs";
$ENV{TF_JOB_DIR}     = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR}  = "$cwd/t/families";
$ENV{TF_CONFIG_FILE} = "$cwd/taskforest.test.cfg";
#$ENV{TF_LOG}         = 0;

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, "Europe/London");
&TaskForest::Test::cleanup_files($log_dir);


my $tf = TaskForest->new();
isa_ok($tf,  'TaskForest',  'TaskForest created successfully');

my $sh = TaskForest::StringHandle->start(*STDOUT);
$tf->status();
my $stdout = $sh->stop();


&TaskForest::Test::checkStatusText($stdout, [
                                       ["EXTERNAL_1",                 "J1",          'Ready',    "-", "Europe/London", "00:00", "--:--", "--:--"],
                                       ["EXTERNAL_MULTIPLE_SECTIONS", "J2",          'Waiting',  "-", "Europe/London", "00:00", "--:--", "--:--"],
                                       ["EXTERNAL_MULTIPLE_SECTIONS", "J3",          'Waiting',  "-", "Europe/London", "00:00", "--:--", "--:--"],
                                       ]
    );

$tf->{options}->{once_only} = 1;
print "Running ready jobs\n";



$tf->runMainLoop();
$tf->{options}->{once_only} = 1;

print "Waiting for job to finish\n";
ok(&TaskForest::Test::waitForFiles(file_list => ["$log_dir/EXTERNAL_1.J1.0"]), "After first cycle EXTERNAL_1::J1 has run");



$tf->runMainLoop();
$tf->{options}->{once_only} = 1;

print "Waiting for job to finish\n";
ok(&TaskForest::Test::waitForFiles(file_list => [
                                       "$log_dir/EXTERNAL_MULTIPLE_SECTIONS.J2.0",
                                       "$log_dir/EXTERNAL_MULTIPLE_SECTIONS.J3.0",
                                   ]), "After second cycle EXTERNAL_MULTIPLE_SECTIONS::J[23] have run");



$sh = TaskForest::StringHandle->start(*STDOUT);
$tf->status();
$stdout = $sh->stop();


&TaskForest::Test::checkStatusText($stdout, [
                                       ["EXTERNAL_1",                 "J1",          'Success',  "0", "Europe/London", "00:00", "..:..", "..:.."],
                                       ["EXTERNAL_MULTIPLE_SECTIONS", "J2",          'Success',  "0", "Europe/London", "00:00", "..:..", "..:.."],
                                       ["EXTERNAL_MULTIPLE_SECTIONS", "J3",          'Success',  "0", "Europe/London", "00:00", "..:..", "..:.."],
                                       ]
    );

&TaskForest::Test::cleanup_files($log_dir);

exit 0;
