# -*- perl -*-

# 
use Test::More tests => 50;
use strict;
use warnings;
use Cwd;
use File::Copy;
use TaskForest::Test;

BEGIN {
    use_ok( 'TaskForest::Family',     "Can use Family" );
    use_ok( 'TaskForest::LogDir',     "Can use LogDir" );
}

my $cwd = getcwd();
&TaskForest::Test::cleanup_files("$cwd/t/families");

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

copy("$src_dir/NOT_ENOUGH_TIME", $dest_dir);


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR});
&TaskForest::Test::cleanup_files($log_dir);

my $sf = TaskForest::Family->new(name=>'NOT_ENOUGH_TIME');
isa_ok($sf,  'TaskForest::Family',  'Created NOT_ENOUGH_TIME family');
is($sf->{name},  'NOT_ENOUGH_TIME',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'America/Chicago',   '  tz');

foreach my $day qw (Mon Tue Wed Thu Fri Sat Sun) {
    is($sf->{days}->{$day}, 1, "  can run on $day");
}
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); $year += 1900; $mon ++;
is($sf->okToRunToday($wday), 1, '  Is ok to run today');

is(scalar(@{$sf->{time_dependencies}}), 1, '  has 1 time dependencies');
is(scalar(keys %{$sf->{jobs}}), 11, '  has 11 jobs');
is(scalar(keys %{$sf->{dependencies}}), 11, '  has 11 dependency lists');

my $num_dep = 0;
foreach my $dep (keys %{$sf->{dependencies}}) {
    $num_dep += scalar(@{$sf->{dependencies}->{$dep}});
}

is ($num_dep, 21, '  has 21 dependencies');

my $d = $sf->{dependencies};
my $td = $sf->{time_dependencies}->[0];

isa_ok($d->{J10}->[0], 'TaskForest::TimeDependency',     'J10 has a time dependency');
is(scalar(@{$d->{J10}}), 1, '  and only that one');

my $last_job = $sf->{jobs}->{J10};

foreach my $n (1..10) {
    isa_ok($d->{"J10--Repeat_$n--"}->[0], 'TaskForest::TimeDependency',     "J10--Repeat_$n-- has a time dependency");
    is(scalar(@{$d->{"J10--Repeat_$n--"}}), 2, '    and has one more');
    is($d->{"J10--Repeat_$n--"}->[1]->{name}, $last_job->{name}, "    which is $last_job->{name}");
    $last_job = $sf->{jobs}->{"J10--Repeat_$n--"};
}


&TaskForest::Test::cleanup_files($log_dir);
