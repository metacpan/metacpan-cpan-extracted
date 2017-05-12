# -*- perl -*-

# 
use Test::More tests => 17;
use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;

BEGIN {
    use_ok( 'TaskForest',               "Can use TaskForest" );
    use_ok( 'TaskForest::Family',       "Can use Family" );
    use_ok( 'TaskForest::LogDir',       "Can use LogDir" );
    use_ok( 'TaskForest::StringHandle', "Can use StringHandle" );
    use_ok( 'TaskForest::Rerun',        "Can use Rerun" );
}

&TaskForest::LocalTime::setTime( { year  => 2009,
                                   month => 05,
                                   day   => 26,
                                   hour  => 0,
                                   min   => 1,
                                   sec   => 0,
                                   tz    => 'GMT',
                                 });
                                       

my $cwd = getcwd();
&TaskForest::Test::cleanup_files("$cwd/t/families");


my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

copy("$src_dir/COLLAPSE", $dest_dir);

$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}); 
&TaskForest::Test::cleanup_files($log_dir);
$log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, "GMT");
&TaskForest::Test::cleanup_files($log_dir);

my $sf = TaskForest::Family->new(name=>'COLLAPSE');

isa_ok($sf,  'TaskForest::Family',  'Created COLLAPSE family');
is($sf->{name},  'COLLAPSE',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'GMT',   '  tz');

my $sh = TaskForest::StringHandle->start(*STDOUT);
my $task_forest = TaskForest->new();
$task_forest->{options}->{collapse} = 1;
$task_forest->status();
my $stdout = $sh->stop();
print "$stdout";
&TaskForest::Test::checkStatusText($stdout, [
                                       ["COLLAPSE", "J10",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["COLLAPSE", "J9",              'Ready', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ]
    );


# simulate a run
print "Simulate running ready jobs\n";
&TaskForest::Test::fakeRun($log_dir, "COLLAPSE", "J9", 0);
&TaskForest::Test::fakeRun($log_dir, "COLLAPSE", "J10", 0);
$sf = TaskForest::Family->new(name=>'COLLAPSE');
$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest->status();
$stdout = '';
$stdout = $sh->stop();
print "$stdout";
&TaskForest::Test::checkStatusText($stdout, [
                                       ["COLLAPSE", "J10",              'Success', "0", "GMT", "00:00", "04:20", "04:20"],
                                       ["COLLAPSE", "J10--Repeat_1--",  'Ready', "-", "GMT", "00:01", "--:--", "--:--"],
                                       ["COLLAPSE", "J9",              'Success', "0", "GMT", "00:00", "04:20", "04:20"],
                                       ]
    );


# now rerun J10.  Repeat should no longer be ready
#  perl -T -I lib blib/script/rerun  --job=COLLAPSE::J10 --log_dir=t/logs
#my $log_dir      = &TaskForest::LogDir::getLogDir($log_dir_root);
&TaskForest::Rerun::rerun("COLLAPSE", "J10", $log_dir);

$sf = TaskForest::Family->new(name=>'COLLAPSE');
$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest->status();
$stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["COLLAPSE", "J10--Orig_1--",   'Success', "0", "GMT", "00:00", "04:20", "04:20"],
                                       ["COLLAPSE", "J10",              'Ready', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["COLLAPSE", "J9",              'Success', "0", "GMT", "00:00", "04:20", "04:20"],
                                       ]
    );

&TaskForest::Test::cleanup_files($log_dir);
