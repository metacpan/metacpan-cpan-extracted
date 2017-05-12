# -*- perl -*-

# 
use Test::More tests => 19;
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

# Make sure that family that runs before midnight continues after midnight.

&TaskForest::LocalTime::setTime( { year  => 2009,
                                   month => 04,
                                   day   => 12,
                                   hour  => 23,
                                   min   => 59,
                                   sec   => 57,
                                   tz    => 'America/Chicago',
                                 });
                                       


my $cwd = getcwd();
&TaskForest::Test::cleanup_files("$cwd/t/families");

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

copy("$src_dir/MIDNIGHT", $dest_dir);

$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run_with_log";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";
$ENV{TF_ONCE_ONLY} = 1;

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}); 
&TaskForest::Test::cleanup_files($log_dir);
$log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, 'GMT');
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

&TaskForest::Test::checkStatusText($stdout, [
                                       ["MIDNIGHT", "J1",              'Waiting', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["MIDNIGHT", "J_005",           'Ready',  "-", "GMT", "04:59", "--:--", "--:--"],
                                       ]
    );



$task_forest->{options}->{once_only} = 1;

print "Running ready jobs\n";
$task_forest->runMainLoop();

# get 'current' time to fake out r.pid file
my $ep = &TaskForest::LocalTime::epoch();

ok(&TaskForest::Test::waitForFiles(file_list => ["$log_dir/MIDNIGHT.J_005.pid"]), "Found expected files");
my $num_tries = 10;

$task_forest->{options}->{once_only} = 1;

ok(&TaskForest::Test::waitForFiles(file_list => [
                                       "$log_dir/MIDNIGHT.J_005.pid"
                                       ]
   ), "Found pid file");


sleep 2;

# fake out pid file
ok( (open (F, "$log_dir/MIDNIGHT.J_005.pid")), "opened pid file for reading");
my @lines = <F>;
ok( (close F), "closed file");

ok((open (F, "> $log_dir/MIDNIGHT.J_005.pid")), "opened pid file for writing");
foreach (@lines) {
    if (/^actual_start:/) { print  F "actual_start: $ep\n"; }
    elsif (/^stop:/)      { printf F "stop: %d\n", $ep + 5; }
    else                  { print  F $_;                    }
}
ok((close F), "closed file");
    


$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest->status();
$stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                        ["MIDNIGHT", "J1",              'Ready', "-", "GMT", "00:00", "--:--", "--:--"],
                                        ["MIDNIGHT", "J_005",           'Success',  "0", "GMT", "04:59", "..:..", "..:.."],
                                        ]
     );



#print Dumper($sf);
&TaskForest::Test::cleanup_files($log_dir);
