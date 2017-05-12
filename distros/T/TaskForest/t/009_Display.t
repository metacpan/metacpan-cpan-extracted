# -*- perl -*-

# 
use Test::More tests => 25;
use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;

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

copy("$src_dir/REPEAT", $dest_dir);

$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR});
&TaskForest::Test::cleanup_files($log_dir);

my $sf = TaskForest::Family->new(name=>'REPEAT');
isa_ok($sf,  'TaskForest::Family',  'Created REPEAT family');
is($sf->{name},  'REPEAT',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'GMT',   '  tz');

my $sh = TaskForest::StringHandle->start(*STDOUT);
my $task_forest = TaskForest->new();
$task_forest->status();
my $stdout = $sh->stop();

&TaskForest::Test::checkStatusText($stdout, [
                                       ["REPEAT", "J10",              '\S+', "-", "GMT", "00:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_1--",  '\S+', "-", "GMT", "01:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_2--",  '\S+', "-", "GMT", "02:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_3--",  '\S+', "-", "GMT", "03:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_4--",  '\S+', "-", "GMT", "04:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_5--",  '\S+', "-", "GMT", "05:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_6--",  '\S+', "-", "GMT", "06:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_7--",  '\S+', "-", "GMT", "07:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_8--",  '\S+', "-", "GMT", "08:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_9--",  '\S+', "-", "GMT", "09:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_10--", '\S+', "-", "GMT", "10:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_11--", '\S+', "-", "GMT", "11:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_12--", '\S+', "-", "GMT", "12:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_13--", '\S+', "-", "GMT", "13:01", "--:--", "--:--"],
                                       ["REPEAT", "J10--Repeat_14--", '\S+', "-", "GMT", "14:01", "--:--", "--:--"],
                                       ["REPEAT", "J11",              '\S+', "-", "GMT", "00:00", "--:--", "--:--"],
                                       ["REPEAT", "J9",               '\S+',   "-", "GMT", "00:00", "--:--", "--:--"],
                                   ]);
&TaskForest::Test::cleanup_files($log_dir);
