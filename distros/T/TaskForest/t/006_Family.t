# -*- perl -*-

# 
use Test::More tests => 74;
use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Test;

BEGIN {
    use_ok( 'TaskForest::Family',     "Can use Family" );
    use_ok( 'TaskForest::LogDir',     "Can use LogDir" );
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

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;
&TaskForest::Test::cleanup_files("$cwd/t/families");

copy("$src_dir/SIMPLE", $dest_dir);


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, 'America/Chicago');
&TaskForest::Test::cleanup_files($log_dir);

my $sf = TaskForest::Family->new(name=>'SIMPLE');
isa_ok($sf,  'TaskForest::Family',  'Created SIMPLE family');
is($sf->{name},  'SIMPLE',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'America/Chicago',   '  tz');

foreach my $day qw (Mon Tue Wed Thu Fri Sat Sun) {
    is($sf->{days}->{$day}, 1, "  can run on $day");
}
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); $year += 1900; $mon ++;
is($sf->okToRunToday($wday), 1, '  Is ok to run today');

is(scalar(@{$sf->{time_dependencies}}), 1, '  has 1 time dependency');
is(scalar(keys %{$sf->{jobs}}), 13, '  has 13 jobs');
is(scalar(keys %{$sf->{dependencies}}), 13, '  has 13 dependency lists');

my $num_dep = 0;
foreach my $dep (keys %{$sf->{dependencies}}) {
    $num_dep += scalar(@{$sf->{dependencies}->{$dep}});
}

is ($num_dep, 18, '  has 18 dependencies');

my $d = $sf->{dependencies};
my $td = $sf->{time_dependencies}->[0];

my %deps = (
    J2  => [''],
    J3  => [''],
    J1  => ['J2', 'J3'],
    J4  => ['J1', ''],
    J12 => ['J4'],
    J13 => ['J4'],

    J6  => [''],
    J7  => [''],
    J5  => ['J6', 'J7', ''],
    J8  => ['J5', 'J4'],

    J9  => [''],
    J10 => ['J9'],
    J11 => ['J10'],
    );

foreach my $j (keys %deps) {
    my $n = 0;
    foreach my $jd (@{$deps{$j}}) {
        if ($jd eq '') {
            is($d->{$j}->[$n], $td,   "    $j depends on family time");
        }
        else {
            is($d->{$j}->[$n]->{name}, $jd,   "    $j depends on $jd");
        }
        $n++;
    }
}
            


# All jobs should be in waiting status
my $waiting = $sf->getAllWaitingJobs();
is(scalar(keys %$waiting), 13,   '  All jobs are waiting');


# fool system to think that the family time has started
$td->{status} = 'Success';

$sf->checkAllTimeDependencies();

is($td->check(), 1, "  Family time met");

my @ready1 = qw ( J2 J3 J6 J7 J9 );
my @waiting1 = qw ( J1 J4 J5 J8 J10 J11 J12 J13 );

$sf->getCurrent();

foreach my $j (@ready1) {
    is($sf->{jobs}->{$j}->{status},  "Ready",  "  $j is now ready");
}
foreach my $j (@waiting1) {
    is($sf->{jobs}->{$j}->{status},  "Waiting",  "  $j is still waiting");
}


# place a few semaphore files in the log directory and getCurrent again
touch_job("$log_dir/SIMPLE.J2", 0);
touch_job("$log_dir/SIMPLE.J3", 0);
touch_job("$log_dir/SIMPLE.J6", 0);
touch_job("$log_dir/SIMPLE.J7", 0);
touch_job("$log_dir/SIMPLE.J9", 0);
$sf->{current} = 0;

$sf->getCurrent();


my @ready2 = qw ( J1 J5 J10 );
my @waiting2 = qw ( J4 J8 J11 J12 J13 );
my @success2 = qw ( J2 J3 J6 J7 J9 );

foreach my $j (@ready2) {
    is($sf->{jobs}->{$j}->{status},  "Ready",  "  $j is now ready");
}
foreach my $j (@waiting2) {
    is($sf->{jobs}->{$j}->{status},  "Waiting",  "  $j is still waiting");
}
foreach my $j (@success2) {
    is($sf->{jobs}->{$j}->{status},  "Success",  "  $j is has succeeded");
}


#print Dumper($sf);


&TaskForest::Test::cleanup_files($log_dir);


sub touch_job {
    my ($file, $result) = @_;
    my $opened = open(O, ">$file.$result");
    ok($opened, "  file $file.$result opened");
    print O "$result\n";
    close O;

    $opened = open(O, ">$file.pid");
    ok($opened, "  file $file.pid opened");
    print O "pid: 111\n";
    print O "rc: $result\n";
    close O;

    
}
    


