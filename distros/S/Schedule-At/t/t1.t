use Test;
use strict;

eval {
	require Schedule::At;
};
if ($@ =~ /SORRY! There is no config for this OS/) {
	plan tests => 1;
	skip(1); # OS not supported
	exit(0);
} elsif ($@) {
	die "$@";
}

if ($< == 0 || $> == 0 || $ENV{'AT_CAN_EXEC'}) {
	$main::FULL_TEST = 1;
	plan tests => 9;
} else {
	plan tests => 1;
}

# Module compiles!
ok(1);

# Exit if platform not supported or at command is not available
exit 0 unless $main::FULL_TEST;

my $verbose = $ENV{'AT_VERBOSE'};

my $rv;

my $nextYear = (localtime)[5] + 1901;

listJobs('Init state') if $verbose;
my %beforeJobs = Schedule::At::getJobs();

$rv = Schedule::At::add (
	TIME => $nextYear . '01181530', 
	COMMAND => 'ls /thisIsACommand/', 
	TAG => '_TEST_aTAG'
);
my %afterJobs = Schedule::At::getJobs();

listJobs('Added new job') if $verbose;
ok(!$rv && ((scalar(keys %beforeJobs)+1) == scalar(keys %afterJobs)));

my %atJobs = Schedule::At::getJobs();
ok(%atJobs);

my ($jobid, $content) = Schedule::At::readJobs(TAG => '_TEST_aTAG');
ok($content, '/thisIsACommand/');

$rv = Schedule::At::remove (TAG => '_TEST_aTAG');
my %afterRemoveJobs = Schedule::At::getJobs();
listJobs('Schedule::At jobs deleted') if $verbose;
ok(scalar(keys %beforeJobs) == scalar(keys %afterRemoveJobs));

# getJobs with TAG param
$rv = Schedule::At::add (
	TIME => $nextYear . '01181531', 
	COMMAND => 'ls /cmd1/',
	TAG => '_TEST_tag1'
);
$rv = Schedule::At::add (
	TIME => $nextYear . '01181532', 
	COMMAND => [ 'ls /testCMD2/', 'ls /testCMD3/' ],
	TAG => '_TEST_tag2'
);

my %tag1Jobs = Schedule::At::getJobs(TAG => '_TEST_tag1');
my %tag2Jobs = Schedule::At::getJobs(TAG => '_TEST_tag2');
listJobs('Schedule::At tag1 and tag2 added') if $verbose;
ok(join('', map { $_->{TAG} } values %tag1Jobs), '/^(_TEST_tag1)+$/');

my ($jobid2, $content2) = Schedule::At::readJobs(TAG => '_TEST_tag2');
ok($content2, '/testCMD2/');
ok($content2, '/testCMD3/');

$rv = Schedule::At::remove (TAG => '_TEST_tag1');
$rv = Schedule::At::remove (TAG => '_TEST_tag2');
listJobs('Schedule::At tag1 and tag2 removed') if $verbose;

sub listJobs {
	print STDERR "@_\n" if @_;
	my %atJobs = Schedule::At::getJobs();
	foreach my $job (values %atJobs) {
		print STDERR "\tID:$job->{JOBID}, Time:$job->{TIME}, Tag:",
			($job->{TAG} || ''), "\n";
	}
}

# Adding in the past fails in some at versions, check that!
my $lastYear = (localtime)[5] + 1900 - 1;
$rv = Schedule::At::add (
        TIME => $lastYear . '01181530',
        COMMAND => 'ls /thisIsACommand/',
        TAG => '_TEST_pastTAG'
);
my %pastJobs = Schedule::At::readJobs(TAG => '_TEST_pastTAG');;
listJobs();
my $pastJobs = scalar(keys(%pastJobs));
ok(($rv != 0 && $pastJobs == 0) || ($rv == 0 && $pastJobs != 0));
