# -*- perl -*-

# 
use Test::More tests => 51;
use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;
use TaskForest::Release;

BEGIN {
    use_ok( 'TaskForest',               "Can use TaskForest" );
    use_ok( 'TaskForest::Family',       "Can use Family" );
    use_ok( 'TaskForest::LogDir',       "Can use LogDir" );
    use_ok( 'TaskForest::StringHandle', "Can use StringHandle" );
    use_ok( 'TaskForest::Rerun',        "Can use Rerun" );
}

my $cwd = getcwd();
&TaskForest::Test::cleanup_files("$cwd/t/families");

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

copy("$src_dir/GMTC", $dest_dir);

$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}); 
&TaskForest::Test::cleanup_files($log_dir);
$log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, "GMT");
&TaskForest::Test::cleanup_files($log_dir);

my $sf = TaskForest::Family->new(name=>'GMTC');

isa_ok($sf,  'TaskForest::Family',  'Created GMTC family');
is($sf->{name},  'GMTC',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'GMT',   '  tz');

my $sh = TaskForest::StringHandle->start(*STDOUT);
my $task_forest = TaskForest->new();
$task_forest->status();
my $stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["GMTC", "J1",              'Ready',   "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J10",             'Ready',   "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J12",             'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_1--", 'Waiting', "-", "GMT", "01:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_2--", 'Waiting', "-", "GMT", "02:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_3--", 'Waiting', "-", "GMT", "03:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_4--", 'Waiting', "-", "GMT", "04:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_5--", 'Waiting', "-", "GMT", "05:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_6--", 'Waiting', "-", "GMT", "06:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_7--", 'Waiting', "-", "GMT", "07:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_8--", 'Waiting', "-", "GMT", "08:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_9--", 'Waiting', "-", "GMT", "09:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_10--",'Waiting', "-", "GMT", "10:00", "--:--", "--:--"],
                                       ["GMTC", "J13",             'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J2",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J3",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J4",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J5",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J7",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J8",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J9",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ]
    );



&TaskForest::Release::release('GMTC', 'J2', $log_dir, 0, 0, $ENV{TF_FAMILY_DIR});

$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest = TaskForest->new();
$task_forest->status();
$stdout = $sh->stop();
print $stdout;
&TaskForest::Test::checkStatusText($stdout, [
                                       ["GMTC", "J1",              'Ready',   "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J10",             'Ready',   "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J12",             'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_1--", 'Waiting', "-", "GMT", "01:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_2--", 'Waiting', "-", "GMT", "02:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_3--", 'Waiting', "-", "GMT", "03:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_4--", 'Waiting', "-", "GMT", "04:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_5--", 'Waiting', "-", "GMT", "05:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_6--", 'Waiting', "-", "GMT", "06:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_7--", 'Waiting', "-", "GMT", "07:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_8--", 'Waiting', "-", "GMT", "08:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_9--", 'Waiting', "-", "GMT", "09:00", "--:--", "--:--"],
                                       ["GMTC", "J12--Repeat_10--",'Waiting', "-", "GMT", "10:00", "--:--", "--:--"],
                                       ["GMTC", "J13",             'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J2",              'Ready',   "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J3",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J4",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J5",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J7",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J8",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["GMTC", "J9",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ]
    );

&TaskForest::Test::cleanup_files($log_dir);
