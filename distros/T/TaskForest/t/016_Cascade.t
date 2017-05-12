# -*- perl -*-

# 
use Test::More tests => 8;
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

my $cwd = getcwd();

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;
&TaskForest::Test::cleanup_files("$cwd/t/families");

copy("$src_dir/CASCADE", $dest_dir);


$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR});
&TaskForest::Test::cleanup_files($log_dir);

my $sf = TaskForest::Family->new(name=>'CASCADE');
isa_ok($sf,  'TaskForest::Family',  'Created CASCADE family');
is($sf->{name},  'CASCADE',   '  name');
is($sf->{start},  '00:00',   '  start');
is($sf->{tz},  'America/Chicago',   '  tz');

#$sf->findDependentJobs();
my $deps = $sf->findDependentJobs('J2');
my $str = join(" ", sort(@$deps));
is($str, "J4 J5 J7 J8 J9");

$deps = $sf->findDependentJobs('J1');
$str = join(" ", sort(@$deps));
is($str, "J2 J3 J4 J5 J7 J8 J9");


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
    




