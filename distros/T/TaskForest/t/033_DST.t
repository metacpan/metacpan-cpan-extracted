# -*- perl -*-

my $SLEEP_TIME = 1;
use Test::More tests => 234;

use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;
use DateTime;

BEGIN {
    use_ok( 'TaskForest'  );
}


my $cwd = getcwd();
my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

&TaskForest::Test::cleanup_files($dest_dir);
copy("$src_dir/DST_START_US", $dest_dir);


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";
$ENV{TF_CONFIG_FILE} = "$cwd/taskforest.test.cfg";
$ENV{TF_ONCE_ONLY} = 1;
$ENV{TF_LOG} = 0;

my ($dt, $log_dir, $tf, $sf, $num_dep);


$dt = DateTime->new(year => 2009, month => 03, day => 8, hour => 0, minute => 0, second => 0, time_zone => 'America/Chicago');
&TaskForest::LocalTime::setTime( { year => $dt->year, month => $dt->month, day => $dt->day, hour => $dt->hour, min => $dt->minute, sec => $dt->second, tz => $dt->time_zone, });

$log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR});
&TaskForest::Test::cleanup_files($log_dir);


$tf = TaskForest->new();
isa_ok($tf,  'TaskForest',  'TaskForest created successfully');


$sf = TaskForest::Family->new(name=>'DST_START_US');
isa_ok($sf,  'TaskForest::Family',  'Created DST_START_US family');
is(scalar(@{$sf->{time_dependencies}}), 1, '  has 1 time dependencies');
is(scalar(keys %{$sf->{jobs}}), 23, '  has 23 jobs');

$num_dep = 0;
foreach my $dep (keys %{$sf->{dependencies}}) {
    $num_dep += scalar(@{$sf->{dependencies}->{$dep}});
}
is ($num_dep, 45, '  has 45 dependencies');

ok(defined($sf->{jobs}->{J2}), "J2 exists");
foreach my $repeat (1..22) {
    ok(defined($sf->{jobs}->{"J2--Repeat_$repeat--"}), "J2--Repeat_$repeat-- exists");
}
ok(!defined($sf->{jobs}->{"J2--Repeat_23--"}), "J2--Repeat_23-- does not exist");








&TaskForest::Test::cleanup_files($dest_dir);
copy("$src_dir/DST_START_EU", $dest_dir);

$dt = DateTime->new(year => 2009, month => 03, day => 29, hour => 0, minute => 0, second => 0, time_zone => 'Europe/London');
&TaskForest::LocalTime::setTime( { year => $dt->year, month => $dt->month, day => $dt->day, hour => $dt->hour, min => $dt->minute, sec => $dt->second, tz => $dt->time_zone, });

$log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR});
&TaskForest::Test::cleanup_files($log_dir);


$sf = TaskForest::Family->new(name=>'DST_START_EU');
isa_ok($sf,  'TaskForest::Family',  'Created DST_START_EU family');
is(scalar(@{$sf->{time_dependencies}}), 1, '  has 1 time dependencies');
is(scalar(keys %{$sf->{jobs}}), 23, '  has 23 jobs');

$num_dep = 0;
foreach my $dep (keys %{$sf->{dependencies}}) {
    $num_dep += scalar(@{$sf->{dependencies}->{$dep}});
}
is ($num_dep, 45, '  has 45 dependencies');

ok(defined($sf->{jobs}->{J2}), "J2 exists");
foreach my $repeat (1..22) {
    ok(defined($sf->{jobs}->{"J2--Repeat_$repeat--"}), "J2--Repeat_$repeat-- exists");
}
ok(!defined($sf->{jobs}->{"J2--Repeat_23--"}), "J2--Repeat_23-- does not exist");










&TaskForest::Test::cleanup_files($dest_dir);
copy("$src_dir/DST_END_US", $dest_dir);

$dt = DateTime->new(year => 2009, month => 11, day => 1, hour => 0, minute => 0, second => 0, time_zone => 'America/Chicago');
&TaskForest::LocalTime::setTime( { year => $dt->year, month => $dt->month, day => $dt->day, hour => $dt->hour, min => $dt->minute, sec => $dt->second, tz => $dt->time_zone, });

$log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR});
&TaskForest::Test::cleanup_files($log_dir);


$sf = TaskForest::Family->new(name=>'DST_END_US');
isa_ok($sf,  'TaskForest::Family',  'Created DST_END_US family');
is(scalar(@{$sf->{time_dependencies}}), 1, '  has 1 time dependencies');
is(scalar(keys %{$sf->{jobs}}), 25, '  has 25 jobs');

$num_dep = 0;
foreach my $dep (keys %{$sf->{dependencies}}) {
    $num_dep += scalar(@{$sf->{dependencies}->{$dep}});
}
is ($num_dep, 49, '  has 49 dependencies');

ok(defined($sf->{jobs}->{J2}), "J2 exists");
foreach my $repeat (1..24) {
    ok(defined($sf->{jobs}->{"J2--Repeat_$repeat--"}), "J2--Repeat_$repeat-- exists");
}
ok(!defined($sf->{jobs}->{"J2--Repeat_25--"}), "J2--Repeat_25-- does not exist");











&TaskForest::Test::cleanup_files($dest_dir);
copy("$src_dir/DST_END_EU", $dest_dir);

$dt = DateTime->new(year => 2009, month => 10, day => 25, hour => 0, minute => 0, second => 0, time_zone => 'Europe/London');
&TaskForest::LocalTime::setTime( { year => $dt->year, month => $dt->month, day => $dt->day, hour => $dt->hour, min => $dt->minute, sec => $dt->second, tz => $dt->time_zone, });

$log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR});
&TaskForest::Test::cleanup_files($log_dir);


$sf = TaskForest::Family->new(name=>'DST_END_EU');
isa_ok($sf,  'TaskForest::Family',  'Created DST_END_EU family');
is(scalar(@{$sf->{time_dependencies}}), 1, '  has 1 time dependencies');
is(scalar(keys %{$sf->{jobs}}), 25, '  has 25 jobs');

$num_dep = 0;
foreach my $dep (keys %{$sf->{dependencies}}) {
    $num_dep += scalar(@{$sf->{dependencies}->{$dep}});
}
is ($num_dep, 49, '  has 49 dependencies');

ok(defined($sf->{jobs}->{J2}), "J2 exists");
foreach my $repeat (1..24) {
    ok(defined($sf->{jobs}->{"J2--Repeat_$repeat--"}), "J2--Repeat_$repeat-- exists");
}
ok(!defined($sf->{jobs}->{"J2--Repeat_25--"}), "J2--Repeat_25-- does not exist");









foreach my $d ([3,8], [3,29], [11,1], [10,25]) { 
    
    
    &TaskForest::Test::cleanup_files($dest_dir);
    copy("$src_dir/DST_GMT", $dest_dir);
    
    $dt = DateTime->new(year => 2009, month => $d->[0], day => $d->[1], hour => 0, minute => 0, second => 0, time_zone => 'GMT');
    &TaskForest::LocalTime::setTime( { year => $dt->year, month => $dt->month, day => $dt->day, hour => $dt->hour, min => $dt->minute, sec => $dt->second, tz => $dt->time_zone, });
    
    $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR});
    &TaskForest::Test::cleanup_files($log_dir);
    
    
    $sf = TaskForest::Family->new(name=>'DST_GMT');
    isa_ok($sf,  'TaskForest::Family',  'Created DST_GMT family');
    is(scalar(@{$sf->{time_dependencies}}), 1, '  has 1 time dependencies');
    is(scalar(keys %{$sf->{jobs}}), 24, '  has 24 jobs');
    
    $num_dep = 0;
    foreach my $dep (keys %{$sf->{dependencies}}) {
        $num_dep += scalar(@{$sf->{dependencies}->{$dep}});
    }
    is ($num_dep, 47, '  has 47 dependencies');
    
    ok(defined($sf->{jobs}->{J2}), "J2 exists");
    foreach my $repeat (1..23) {
    ok(defined($sf->{jobs}->{"J2--Repeat_$repeat--"}), "J2--Repeat_$repeat-- exists");
    }
    ok(!defined($sf->{jobs}->{"J2--Repeat_24--"}), "J2--Repeat_24-- does not exist");
}







&TaskForest::Test::cleanup_files($log_dir);



exit;
