#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Time::HiRes ();
use TestTmp;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::vrrp;

my $data = $FindBin::Bin . '/data/vrrp';
my $dir  = TestTmp::dir();
my $run  = sub {
	return Monitoring::Sneck::Checks->run( check => 'vrrp', args => \@_ );
};

# keepalived, the fake one writing t/data/vrrp/keepalived/$set.data out when sent USR1
local $Monitoring::Sneck::Checks::base::OS        = 'linux';
local $Monitoring::Sneck::Checks::vrrp::PID_FILE  = $dir . '/keepalived.pid';
local $Monitoring::Sneck::Checks::vrrp::DATA_FILE = $dir . '/keepalived.data';
local $Monitoring::Sneck::Checks::vrrp::DUMP_WAIT = 5;
is( $run->()->{stdout}, "VRRP CRITICAL - keepalived is not running\n", 'no PID file' );

my $set_file      = $dir . '/set';
my $keepalived_as = sub {
	open( my $set_fh, '>', $set_file ) or die($!);
	print $set_fh $_[0] . "\n";
	close($set_fh);
};
my $keepalived_pid = fork() // die( 'can not fork, ' . $! );
if ( !$keepalived_pid ) {
	exec(
		$^X,
		$data . '/keepalived/keepalived',
		$Monitoring::Sneck::Checks::vrrp::PID_FILE,
		$set_file, $Monitoring::Sneck::Checks::vrrp::DATA_FILE
	);
	die( 'can not run the fake keepalived, ' . $! );
}
END { kill( 'TERM', $keepalived_pid ) if $keepalived_pid; }
my $give_up = time + 10;
Time::HiRes::sleep(0.05) while !-s $Monitoring::Sneck::Checks::vrrp::PID_FILE && time < $give_up;

my $web = 'VI_WEB, MASTER, eth0, VRID 51, priority 150';
my $db  = 'VI_DB, BACKUP, eth1, VRID 52, priority 100, master router 192.0.2.12';
$keepalived_as->('ok');
my $return = $run->();
is( $return->{code}, 0, 'either state is fine when none is asked for' );
is(
	$return->{stdout},
	"VRRP OK - VI_WEB MASTER, VI_DB BACKUP | master=1;;;0 backup=1;;;0\n" . $web . "\n" . $db . "\n",
	'instances, the sync group after them left alone'
);
is( $run->( '-m', 'VI_WEB', '-b', 'VI_DB' )->{code}, 0, '--master and --backup met' );
is(
	$run->( '-s', 'master' )->{stdout},
	"VRRP CRITICAL - VI_WEB MASTER, VI_DB BACKUP, not MASTER | master=1;;;0 backup=1;;;0\n"
		. $web . "\n"
		. $db . "\n",
	'--state not met'
);
is( $run->( '-s', 'master', '-b', 'VI_DB' )->{code}, 0, '--backup over --state' );
is(
	$run->( '-b', 'VI_WEB', '-m', 'VI_GONE' )->{stdout},
	"VRRP CRITICAL - VI_GONE is not there, VI_WEB MASTER, not BACKUP, VI_DB BACKUP | master=1;;;0 backup=1;;;0\n"
		. $web . "\n"
		. $db . "\n",
	'--backup not met, --master not there'
);

$keepalived_as->('fault');
like( $run->( '-m', 'VI_WEB' )->{stdout},
	qr/\AVRRP CRITICAL - VI_WEB FAULT, VI_DB BACKUP \| master=0;;;0 backup=1;;;0\nVI_WEB, FAULT, eth0,/, 'FAULT' );
is( $run->()->{code}, 2, 'FAULT is CRITICAL with no state asked for' );

$keepalived_as->('none');
is( $run->()->{stdout}, "VRRP OK - no VRRP instances\n", 'no instances' );
is(
	$run->( '-m', 'VI_WEB' )->{stdout},
	"VRRP CRITICAL - VI_WEB is not there | master=0;;;0 backup=0;;;0\n",
	'no instances, one wanted'
);

# the data file from the last run is still there, and must not be taken for a answer
$keepalived_as->('silent');
{
	local $Monitoring::Sneck::Checks::vrrp::DUMP_WAIT = 1.5;
	$return = $run->();
	is( $return->{code}, 3, 'never writing its state out is UNKNOWN' );
	like(
		$return->{stderr},
		qr/\AVRRP UNKNOWN - keepalived, PID $keepalived_pid, did not write \S+keepalived\.data\n\z/,
		'the old data file is not used'
	);
}

kill( 'TERM', $keepalived_pid );
waitpid( $keepalived_pid, 0 );
my $gone_pid = $keepalived_pid;
$keepalived_pid = undef;
is( $run->()->{stdout}, "VRRP CRITICAL - keepalived is not running\n", 'PID file left by one that is gone' );

is( $run->( '-T', 'vrrpd' )->{code}, 3, 'bad --type' );
is( $run->( '-s', 'fault' )->{code}, 3, 'bad --state' );
is( $run->( '-m', 'VI_WEB', '-b', 'VI_WEB' )->{code}, 3, 'one name as both' );
like( $run->( '-T', 'carp' )->{stderr}, qr/CARP is only checked on FreeBSD, not linux/, 'CARP off FreeBSD' );

# CARP, the fake ifconfig printing t/data/vrrp/freebsd/$VRRP_TEST_SET/output
local $Monitoring::Sneck::Checks::base::OS       = 'freebsd';
local $Monitoring::Sneck::Checks::vrrp::IFCONFIG = $data . '/ifconfig';
my $carp = sub {
	my ( $set, @args ) = @_;
	local $ENV{VRRP_TEST_SET} = $set;
	return $run->(@args);
};

my $details = "em0:1, MASTER, advbase 1, advskew 0\nem1:1, BACKUP, advbase 1, advskew 100\n"
	. "em1:2, BACKUP, advbase 1, advskew 100\n";
is(
	$carp->( 'ok', '-m', 'em0:1', '-b', 'em1:1', '-b', '2' )->{stdout},
	"VRRP OK - em0:1 MASTER, em1:1 BACKUP, em1:2 BACKUP | master=1;;;0 backup=2;;;0\n" . $details,
	'CARP by default on FreeBSD, vhids by interface and alone'
);
is(
	$carp->( 'ok', '-m', '1', '-m', '9' )->{stdout},
	"VRRP CRITICAL - 9 is not there, em0:1 MASTER, em1:1 BACKUP, not MASTER, em1:2 BACKUP"
		. " | master=1;;;0 backup=2;;;0\n"
		. $details,
	'a vhid alone is every interface with it'
);
like( $carp->('init')->{stdout},
	qr/\AVRRP CRITICAL - em0:1 MASTER, em1:1 INIT, em1:2 INIT \| master=1;;;0 backup=0;;;0\n/, 'INIT' );
is( $carp->('none')->{stdout}, "VRRP OK - no CARP vhids\n", 'no vhids' );

# freevrrpd, its state worked out from the addresses in its config being held
local $Monitoring::Sneck::Checks::vrrp::FREEVRRPD_CONF     = $data . '/freevrrpd/freevrrpd.conf';
local $Monitoring::Sneck::Checks::vrrp::FREEVRRPD_PID_FILE = $dir . '/freevrrpd.pid';
is(
	$carp->( 'freevrrpd_ok', '-T', 'freevrrpd' )->{stdout},
	"VRRP CRITICAL - freevrrpd is not running\n",
	'freevrrpd, no PID file'
);
my $freevrrpd_pid_as = sub {
	open( my $pid_fh, '>', $Monitoring::Sneck::Checks::vrrp::FREEVRRPD_PID_FILE ) or die($!);
	print $pid_fh $_[0] . "\n";
	close($pid_fh);
};
$freevrrpd_pid_as->($$);
$return = $carp->( 'freevrrpd_ok', '-T', 'freevrrpd', '-m', 'em0:1', '-b', '2' );
is(
	$return->{stdout},
	"VRRP OK - em0:1 MASTER, em1:2 BACKUP | master=1;;;0 backup=1;;;0\n"
		. "em0:1, MASTER, priority 255, 192.0.2.100 192.0.2.201\n"
		. "em1:2, BACKUP, priority 100, 198.51.100.100 (not held)\n",
	'freevrrpd, every address held is MASTER, none BACKUP'
);
unlike( $return->{combined}, qr/notshown/, 'the password is never output' );
is(
	$carp->( 'freevrrpd_ok', '-T', 'freevrrpd', '-s', 'backup' )->{stdout},
	"VRRP CRITICAL - em0:1 MASTER, not BACKUP, em1:2 BACKUP | master=1;;;0 backup=1;;;0\n"
		. "em0:1, MASTER, priority 255, 192.0.2.100 192.0.2.201\n"
		. "em1:2, BACKUP, priority 100, 198.51.100.100 (not held)\n",
	'freevrrpd, --state not met'
);
is(
	$carp->( 'freevrrpd_partial', '-T', 'freevrrpd' )->{stdout},
	"VRRP CRITICAL - em0:1 PARTIAL, em1:2 BACKUP | master=0;;;0 backup=1;;;0\n"
		. "em0:1, PARTIAL, priority 255, 192.0.2.100 192.0.2.201 (not held)\n"
		. "em1:2, BACKUP, priority 100, 198.51.100.100 (not held)\n",
	'freevrrpd, some held is PARTIAL, one on a interface that is down is not held'
);
{
	local $Monitoring::Sneck::Checks::vrrp::FREEVRRPD_CONF = $data . '/freevrrpd/no_interface.conf';
	is( $carp->( 'freevrrpd_ok', '-T', 'freevrrpd' )->{stdout}, "VRRP OK - no VRIDs\n", 'freevrrpd, no whole VRID' );
	$Monitoring::Sneck::Checks::vrrp::FREEVRRPD_CONF = $data . '/freevrrpd/nope.conf';
	like(
		$carp->( 'freevrrpd_ok', '-T', 'freevrrpd' )->{stderr},
		qr/\AVRRP UNKNOWN - can not read \S+nope\.conf, /,
		'freevrrpd, no config'
	);
}
$freevrrpd_pid_as->($gone_pid);
is(
	$carp->( 'freevrrpd_ok', '-T', 'freevrrpd' )->{stdout},
	"VRRP CRITICAL - freevrrpd is not running\n",
	'freevrrpd, PID file left by one that is gone'
);
{
	local $Monitoring::Sneck::Checks::base::OS = 'linux';
	like(
		$carp->( 'freevrrpd_ok', '-T', 'freevrrpd' )->{stderr},
		qr/freevrrpd is only checked on FreeBSD, not linux/,
		'freevrrpd off FreeBSD'
	);
}

done_testing();
