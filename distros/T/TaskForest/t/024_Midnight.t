# -*- perl -*-

# 
use Test::More tests => 17;
use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;
use TaskForest::Release;
use TaskForest::LocalTime;

BEGIN {
    use_ok( 'TaskForest',               "Can use TaskForest" );
    use_ok( 'TaskForest::Family',       "Can use Family" );
    use_ok( 'TaskForest::LogDir',       "Can use LogDir" );
    use_ok( 'TaskForest::StringHandle', "Can use StringHandle" );
    use_ok( 'TaskForest::Rerun',        "Can use Rerun" );
}

&TaskForest::LocalTime::setTime( { year  => 2009,
                                   month => 04,
                                   day   => 19,
                                   hour  => 22,
                                   min   => 30,
                                   sec   => 0,
                                   tz    => 'America/Chicago',
                                 });
                                       


my $cwd = getcwd();
&TaskForest::Test::cleanup_files("$cwd/t/families");

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

copy("$src_dir/MIDNIGHT", $dest_dir);

$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}); 
&TaskForest::Test::cleanup_files($log_dir);
$log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, "GMT");
&TaskForest::Test::cleanup_files($log_dir);

my $sf = TaskForest::Family->new(name=>'MIDNIGHT');

#print Dumper($sf);

isa_ok($sf,  'TaskForest::Family',  'Created MIDNIGHT family');
is($sf->{name},  'MIDNIGHT',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'GMT',   '  tz');


my $sh = TaskForest::StringHandle->start(*STDOUT);
my $task_forest = TaskForest->new();
$task_forest->status();
my $stdout = $sh->stop();
#print "STDOUT is $stdout\n";
&TaskForest::Test::checkStatusText($stdout, [
                                       ["MIDNIGHT", "J1",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["MIDNIGHT", "J_005",           'Waiting',  "-", "GMT", "04:59", "--:--", "--:--"],
                                       ]
    );




# now check for a ready J_005
&TaskForest::LocalTime::setTime( { year  => 2009,
                                   month => 04,
                                   day   => 19,
                                   hour  => 23,
                                   min   => 59,
                                   sec   => 57,
                                   tz    => 'America/Chicago',
                                 });


                                       

my $sf2 = TaskForest::Family->new(name=>'MIDNIGHT');

#print Dumper($sf2);

isa_ok($sf2,  'TaskForest::Family',  'Created MIDNIGHT family');
is($sf2->{name},  'MIDNIGHT',   '  name');
is($sf2->{start},  '00:00',   '  start');
is($sf2->{tz},  'GMT',   '  tz');


my $sh2 = TaskForest::StringHandle->start(*STDOUT);
my $task_forest2 = TaskForest->new();
$task_forest2->status();
my $stdout2 = $sh2->stop();
#print "STDOUT is $stdout2\n";
&TaskForest::Test::checkStatusText($stdout2, [
                                       ["MIDNIGHT", "J1",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["MIDNIGHT", "J_005",           'Ready',   "-", "GMT", "04:59", "--:--", "--:--"],
                                       ]
    );

&TaskForest::Test::cleanup_files($log_dir);
