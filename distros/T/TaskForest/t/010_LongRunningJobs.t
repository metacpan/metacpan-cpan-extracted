# -*- perl -*-

# 
use Test::More tests => 6;
use strict;
use warnings;
use Cwd;
use File::Copy;
use TaskForest::Test;

BEGIN {
    use_ok( 'TaskForest',     "Can use TaskForest" );
    use_ok( 'TaskForest::LogDir',     "Can use LogDir" );
    use_ok( 'TaskForest::StringHandle',     "Can use StringHandle" );
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
&TaskForest::Test::cleanup_files("$cwd/t/families");

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

copy("$src_dir/LONG_RUNNING", $dest_dir);


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, 'America/Chicago');
&TaskForest::Test::cleanup_files($log_dir);


my $tf = TaskForest->new();
isa_ok($tf,  'TaskForest',  'TaskForest created successfully');

$tf->{options}->{once_only} = 1;


my $sh = TaskForest::StringHandle->start(*STDOUT);
$tf->status();
my $stdout = $sh->stop();

&TaskForest::Test::checkStatusText($stdout, [
                                       ["LONG_RUNNING", "JLongRunning",              'Ready', "-", "America/Chicago", "00:00", "--:--", "--:--"],
                                       ]
    );

print "Simulate running ready jobs\n";
open (OUT, ">$log_dir/LONG_RUNNING.JLongRunning.pid") || die "Couldn't open pid file\n";
print OUT "pid: 111\nactual_start: 111\n";
close OUT;

open (OUT, ">$log_dir/LONG_RUNNING.JLongRunning.started") || die "Couldn't open started file\n";
print OUT "00:00\n";
close OUT;


$sh = TaskForest::StringHandle->start(*STDOUT);
$tf->status();
$stdout = $sh->stop();

&TaskForest::Test::checkStatusText($stdout, [
                                       ["LONG_RUNNING", "JLongRunning",              'Running', "-", "America/Chicago", "00:00", "\\d\\d:\\d\\d", "--:--"],
                                       ]
    );






&TaskForest::Test::cleanup_files($log_dir);
