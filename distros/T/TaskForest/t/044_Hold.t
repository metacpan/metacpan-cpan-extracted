# -*- perl -*-

# 
use Test::More tests => 35;
use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;
use TaskForest::Hold;
use TaskForest::LocalTime;
use DateTime;

BEGIN {
    use_ok( 'TaskForest',               "Can use TaskForest" );
    use_ok( 'TaskForest::Family',       "Can use Family" );
    use_ok( 'TaskForest::LogDir',       "Can use LogDir" );
    use_ok( 'TaskForest::StringHandle', "Can use StringHandle" );
    use_ok( 'TaskForest::Release',      "Can use Release" );
    use_ok( 'TaskForest::Hold',         "Can use Hold" );
}

my $cwd = getcwd();
&TaskForest::Test::cleanup_files("$cwd/t/families");

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

copy("$src_dir/SMALL_CASCADE", $dest_dir);

&TaskForest::LocalTime::setTime( { year  => 2009,
                                   month => 05,
                                   day   => 03,
                                   hour  => 10,
                                   min   => 10,
                                   sec   => 10,
                                   tz    => 'America/Chicago',
                                 });
                                       


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR}     = "$cwd/t/logs";
$ENV{TF_JOB_DIR}     = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR}  = "$cwd/t/families";
$ENV{TF_CONFIG_FILE} = "$cwd/taskforest.test.cfg";

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}); 
&TaskForest::Test::cleanup_files($log_dir);
$log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, "America/Chicago");
&TaskForest::Test::cleanup_files($log_dir);

my $sf = TaskForest::Family->new(name=>'SMALL_CASCADE');

isa_ok($sf,  'TaskForest::Family',  'Created SMALL_CASCADE family');
is($sf->{name},  'SMALL_CASCADE',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'America/Chicago',   '  tz');

my $sh = TaskForest::StringHandle->start(*STDOUT);
my $task_forest = TaskForest->new();
$task_forest->status();
my $stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["SMALL_CASCADE", "J2",              'Ready', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ["SMALL_CASCADE", "J7",              'Waiting', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ["SMALL_CASCADE", "J8",              'Waiting', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ]
    );


&TaskForest::Hold::hold('SMALL_CASCADE', 'J7', $log_dir, $ENV{TF_FAMILY_DIR}, 1);

$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest->status();
$stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["SMALL_CASCADE", "J2",              'Ready', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ["SMALL_CASCADE", "J7",              'Hold', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ["SMALL_CASCADE", "J8",              'Waiting', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ]
    );



eval { 
    &TaskForest::Release::release('SMALL_CASCADE', 'J7', $log_dir, 0, 0, $ENV{TF_FAMILY_DIR});
};
my $retval = $@;
ok($retval, "release died");
$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest->status();
$stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["SMALL_CASCADE", "J2",              'Ready', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ["SMALL_CASCADE", "J7",              'Hold', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ["SMALL_CASCADE", "J8",              'Waiting', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ]
    );





$task_forest->{options}->{once_only} = 1;
print "Running ready jobs\n";
$task_forest->runMainLoop();
$task_forest->{options}->{once_only} = 1;


print "Waiting for job to finish\n";
ok(&TaskForest::Test::waitForFiles(file_list => ["$log_dir/SMALL_CASCADE.J2.0"]), "After first cycle SMALL_CASCADE::J2 has run");



$sf->{current} = 0;
$sf->getCurrent();




$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest->status();
$stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["SMALL_CASCADE", "J2",              'Success', "0", "America/Chicago", "00:00", "..:..", "..:.."],
                                       ["SMALL_CASCADE", "J7",              'Hold', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ["SMALL_CASCADE", "J8",              'Ready', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ]
    );



$task_forest->{options}->{once_only} = 1;
print "Running ready jobs\n";
$task_forest->runMainLoop();

$task_forest->{options}->{once_only} = 1;

print "Waiting for job to finish\n";
ok(&TaskForest::Test::waitForFiles(file_list => ["$log_dir/SMALL_CASCADE.J8.0"]), "After first cycle SMALL_CASCADE::J8 has run");




$sf->{current} = 0;
$sf->getCurrent();




$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest->status();
$stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["SMALL_CASCADE", "J2",              'Success', "0", "America/Chicago", "00:00", "..:..", "..:.."],
                                       ["SMALL_CASCADE", "J7",              'Hold', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ["SMALL_CASCADE", "J8",              'Success', "0", "America/Chicago", "00:00", "..:..", "..:.."],
                                       ]
    );


&TaskForest::Hold::releaseHold('SMALL_CASCADE', 'J7', $log_dir, $ENV{TF_FAMILY_DIR}, 1);


$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest->status();
$stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["SMALL_CASCADE", "J2",              'Success', "0", "America/Chicago", "00:00", "..:..", "..:.."],
                                       ["SMALL_CASCADE", "J7",              'Ready', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ["SMALL_CASCADE", "J8",              'Success', "0", "America/Chicago", "00:00", "..:..", "..:.."],
                                       ]
    );






$task_forest->{options}->{once_only} = 1;
print "Running ready jobs\n";
$task_forest->runMainLoop();

$task_forest->{options}->{once_only} = 1;

print "Waiting for job to finish\n";
ok(&TaskForest::Test::waitForFiles(file_list => ["$log_dir/SMALL_CASCADE.J7.0"]), "After first cycle SMALL_CASCADE::J7 has run");

$sf->{current} = 0;
$sf->getCurrent();





$sh = TaskForest::StringHandle->start(*STDOUT);
$task_forest->status();
$stdout = $sh->stop();
&TaskForest::Test::checkStatusText($stdout, [
                                       ["SMALL_CASCADE", "J2",              'Success', "0", "America/Chicago", "00:00", "..:..", "..:.."],
                                       ["SMALL_CASCADE", "J7",              'Success', "0", "America/Chicago", "00:00", "..:..", "..:.."],
                                       ["SMALL_CASCADE", "J8",              'Success', "0", "America/Chicago", "00:00", "..:..", "..:.."],
                                       ]
    );







&TaskForest::Test::cleanup_files($log_dir);
