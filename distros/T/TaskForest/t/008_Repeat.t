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

foreach my $day qw (Mon Tue Wed Thu Fri Sat Sun) {
    is($sf->{days}->{$day}, 1, "  can run on $day");
}
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); $year += 1900; $mon ++;
is($sf->okToRunToday($wday), 1, '  Is ok to run today');

is(scalar(@{$sf->{time_dependencies}}), 2, '  has 2 time dependencies');
is(scalar(keys %{$sf->{jobs}}), 17, '  has 17 jobs');
is(scalar(keys %{$sf->{dependencies}}), 17, '  has 17 dependency lists');

my $num_dep = 0;
foreach my $dep (keys %{$sf->{dependencies}}) {
    $num_dep += scalar(@{$sf->{dependencies}->{$dep}});
}

is ($num_dep, 18, '  has 18 dependencies');

my $d = $sf->{dependencies};
my $td = $sf->{time_dependencies}->[0];

is($d->{J9}->[0], $td, "First dependency for J9 is a td");
is($d->{J10}->[0]->{name}, 'J9', 'J10 depends on J9');
isa_ok($d->{J10}->[1], 'TaskForest::TimeDependency',     '  and on its own time dependency');
is(scalar(@{$d->{J10}}), 2, '  and only on those');

foreach my $n (1..14) {
    isa_ok($d->{"J10--Repeat_$n--"}->[0], 'TaskForest::TimeDependency',     'Rpt $n has a time dependency');
    is(scalar(@{$d->{"J10--Repeat_$n--"}}), 1, ' and is the only dep it has');
}

&TaskForest::Test::cleanup_files($log_dir);

sub cleanup {
    my $dir = shift;
	local *DIR;
    
	opendir DIR, $dir or die "opendir $dir: $!";
	my $found = 0;
	while ($_ = readdir DIR) {
        next if /^\.{1,2}$/;
        my $path = "$dir/$_";
		unlink $path if -f $path;
		cleanup($path) if -d $path;
	}
	closedir DIR;
	rmdir $dir or print "error - $!";
}

