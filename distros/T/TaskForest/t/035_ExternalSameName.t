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
}

my $cwd = getcwd();

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;
&TaskForest::Test::cleanup_files("$cwd/t/families");

copy("$src_dir/EXTERNAL_1", $dest_dir);
copy("$src_dir/EXTERNAL_3", $dest_dir);


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR}     = "$cwd/t/logs";
$ENV{TF_JOB_DIR}     = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR}  = "$cwd/t/families";
$ENV{TF_CONFIG_FILE} = "$cwd/taskforest.test.cfg";
#$ENV{TF_LOG}         = 0;

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR}, "Europe/London");
&TaskForest::Test::cleanup_files($log_dir);

my $sf = TaskForest::Family->new(name=>'EXTERNAL_3');
isa_ok($sf,  'TaskForest::Family',  'Created EXTERNAL_3 family');
is($sf->{name},  'EXTERNAL_3',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'Europe/London',   '  tz');

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = &TaskForest::LocalTime::ft("Europe/London");

#print Dumper($sf);

# 7 
is(scalar(@{$sf->{time_dependencies}}), 2, '  has 2 time dependencies');

is(scalar(keys %{$sf->{jobs}}), 1, '  has 1 job');
is(scalar(keys %{$sf->{dependencies}}), 1, '  has 1 dependency list');


my $num_dep = 0;
foreach my $dep (keys %{$sf->{dependencies}}) {
    $num_dep += scalar(@{$sf->{dependencies}->{$dep}});
}

is ($num_dep, 2, '  has 2 dependencies');

my $d = $sf->{dependencies};
my $td = $sf->{time_dependencies}->[0];

my %deps = (
    J1  => ['J1'],
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
is(scalar(keys %$waiting), 1,   '  All jobs are waiting');


my $tf = TaskForest->new();
isa_ok($tf,  'TaskForest',  'TaskForest created successfully');

$tf->{options}->{once_only} = 1;

print "Running ready jobs\n";
$tf->runMainLoop();

$tf->{options}->{once_only} = 1;

print "Waiting for job to finish\n";
ok(&TaskForest::Test::waitForFiles(file_list => ["$log_dir/EXTERNAL_1.J1.0"]), "After first cycle EXTERNAL_1::J1 has run");


$sf->{current} = 0;
$sf->getCurrent();

my $ok = 0;
if ($sf->{jobs}->{J1}->{status} eq 'Ready' || $sf->{jobs}->{J1}->{status} eq 'Success') {
    $ok = 1;
}

is($ok, 1, "Now, J1's external dependency has been met");

$tf->runMainLoop();

print "Waiting for job to finish\n";

ok(&TaskForest::Test::waitForFiles(file_list => ["$log_dir/EXTERNAL_3.J1.0"]), "After second cycle EXTERNAL_3::J1 has run");

&TaskForest::Test::cleanup_files($log_dir);


exit 0;
