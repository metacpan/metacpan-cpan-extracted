# -*- perl -*-

# 
use Test::More tests => 17;
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
&TaskForest::Test::cleanup_files("$cwd/t/families");

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

copy("$src_dir/COLLAPSE", $dest_dir);

$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";

&TaskForest::LocalTime::setTime( { year  => 2009,
                                   month => 04,
                                   day   => 12,
                                   hour  => 10,
                                   min   => 01,
                                   sec   => 01,
                                   tz    => 'America/Chicago',
                                 });
                                       



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
                                       ["COLLAPSE", "J9",               'Ready',   "-", "GMT", "00:00", "--:--", "--:--"],
                                       ]
    );

# fake a run of a job that's not in the COLLAPSE Family.
&TaskForest::Test::fakeRun($log_dir, "PHANTOM", 'J1', 0);
$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest->status();
$stdout = $sh->stop();
print "$stdout";
&TaskForest::Test::checkStatusText($stdout, [
                                       ["COLLAPSE", "J10",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["COLLAPSE", "J9",               'Ready',   "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["PHANTOM",  "J1",               'Success',   "0", "America/Chicago", "--:--", "23:20", "23:20"],
                                       ]
    );



# fake a run of a job that is in the COLLAPSE Family.
&TaskForest::Test::fakeRun($log_dir, "COLLAPSE", 'J2', 0);
$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest->status();
$stdout = $sh->stop();
print "$stdout";
&TaskForest::Test::checkStatusText($stdout, [
                                       ["COLLAPSE", "J10",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["COLLAPSE",  "J2",              'Success',   "0", "America/Chicago", "--:--", "23:20", "23:20"],
                                       ["COLLAPSE", "J9",               'Ready',   "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["PHANTOM",  "J1",               'Success',   "0", "America/Chicago", "--:--", "23:20", "23:20"],
                                       ]
    );

&TaskForest::Test::cleanup_files($log_dir);
