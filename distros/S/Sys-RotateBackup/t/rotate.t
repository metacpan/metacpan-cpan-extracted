#!perl -w

use strict;
use warnings;

use File::Temp;
use File::Blarf;
use Sys::RotateBackup;
use Test::MockObject::Universal;
use Test::MockTime;
use Test::More tests => 59;

# Get all timestamps when dow == dom == month == 1, i.e. weekly, monthly and yearly rotations all fire at once
# not sctrictly necessary, but nice to know anyway
# perl -MPOSIX -le'for $year (1970 .. 2000) { $ts = POSIX::mktime(0,0,0,1,0,$year-1900); (undef, undef, undef, $dom, $mon, undef, $dow, undef, undef) = localtime($ts); if($dom+1 == $dow) { print localtime($ts)." - ".$ts; } }'
Test::MockTime::set_fixed_time(252457200);

my $Logger = Test::MockObject::Universal->new();
my $tempdir = File::Temp::tempdir( CLEANUP => 1, );

my $Rotor = Sys::RotateBackup::->new(
    'logger'    => $Logger,
    'vault'     => $tempdir,
);

ok($Rotor->rotate(time()),'Rotated');
foreach my $type (qw(daily weekly monthly yearly)) {
    ok(-d $tempdir.'/'.$type,'Got '.$type.' directory');
}

mkdir($tempdir.'/daily/inprogress');
my $testfile = $tempdir.'/daily/inprogress/test.txt';
my $teststring = 'TESTFILE1';
ok(File::Blarf::blarf($testfile,$teststring),'Wrote test subject');
ok($Rotor->rotate(time()),'Rotated again');
is(File::Blarf::slurp($tempdir.'/daily/0/test.txt'),$teststring,'Testfile was correctly rotated');

mkdir($tempdir.'/daily/inprogress');
ok($Rotor->rotate(time()),'Rotated again and again');
is(File::Blarf::slurp($tempdir.'/daily/1/test.txt'),$teststring,'Testfile was correctly rotated (again)');

foreach my $type (qw(daily weekly monthly yearly)) {
    ok(-d $tempdir.'/'.$type,'Still got '.$type.' directory');
    # make sure all necessary dirs exist
    foreach my $i (0 .. $Rotor->$type()) {
        ok(-d $tempdir.'/'.$type.'/'.$i,'Rotation '.$i.' of type '.$type.' exists');
    }
}

# TODO HIGH make sure the rotated contents are sincere, i.e. not folders
# are move to unwanted sub-leves and all files are where there should be (check content!)

#
# Test cleanup
#

#my $daily_max = 32;
#my $weekly_max = 4;
#my $monthly_max = 12;
#my $yearly_max = 2;
#
#foreach my $yearly (reverse (0 .. $yearly_max)) {
#    foreach my $monthly (reverse (0 .. $monthly_max)) {
#        foreach my $weekly (reverse (0 .. $weekly_max)) {
#            foreach my $daily (reverse (0 .. $daily_max)) {
#                $Rotor = Sys::RotateBackup::->new(
#                    'logger'    => $Logger,
#                    'vault'     => $tempdir,
#                    'daily'     => $daily,
#                    'weekly'    => $weekly,
#                    'monthly'   => $monthly,
#                    'yearly'    => $yearly,
#                );
#
#                ok($Rotor->cleanup());
#
#                ok(!-d $tempdir.'/daily/'.($daily+1),'Superflous daily rotation does no longer exist');
#                ok(!-d $tempdir.'/weekly/'.($weekly+1),'Removed weekly type does no longer exist');
#                ok(!-d $tempdir.'/monthly/'.($monthly+1),'Superflous monthly rotation does no longer exist');
#                ok(!-d $tempdir.'/yearly/'.($yearly+1),'Removed yearly type does no longer exist');
#            }
#        }
#    }
#}

$Rotor = Sys::RotateBackup::->new(
    'logger'    => $Logger,
    'vault'     => $tempdir,
    'daily'     => 4,
    'weekly'    => 0,
    'monthly'   => 2,
    'yearly'    => 0,
);

ok($Rotor->cleanup());

ok(!-d $tempdir.'/daily/5','Superflous daily rotation does no longer exist');
ok(!-d $tempdir.'/weekly','Removed weekly type does no longer exist');
ok(!-d $tempdir.'/monthly/3','Superflous monthly rotation does no longer exist');
ok(!-d $tempdir.'/yearly','Removed yearly type does no longer exist');

# TODO HIGH make sure no wanted dirs/files are deleted!

Test::MockTime::restore_time();