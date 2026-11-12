#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::base;
use Monitoring::Sneck::Checks::auditd;
use Monitoring::Sneck::Checks::selinux;
use Monitoring::Sneck::Checks::apparmor;

local $Monitoring::Sneck::Checks::base::OS = 'linux';
my $data = $FindBin::Bin . '/data';
my $run  = sub {
	my ( $check, @args ) = @_;
	return Monitoring::Sneck::Checks->run( check => $check, args => \@args );
};

# auditd, the fake auditctl printing t/data/auditd/$AUDITD_TEST_SET/status or rules
local $Monitoring::Sneck::Checks::auditd::AUDITCTL = $data . '/auditd/auditctl';
my $auditd = sub {
	my ( $set, @args ) = @_;
	local $ENV{AUDITD_TEST_SET} = $set;
	return $run->( 'auditd', @args );
};
# as sha256sum gives for t/data/auditd/ok/rules and stopped/rules
my $ok_hash      = '4f55936e9ca55def13c7f1e313b8e6af17ff0a4ae1ef28573f6fbe5afbbb8910';
my $stopped_hash = '61501e69a61dbbc1a41605ea15c34807e6b1d3992bee195dde36a7ebdd95dd87';
is(
	$auditd->('ok')->{stdout},
	"AUDITD OK - auditing enabled, 4 rules | rules=4;;;0 lost=0c;;;0\nrules sha256 $ok_hash\n",
	'auditd ok, with the rules hash'
);
is(
	$auditd->( 'ok', '-I' )->{stdout},
	"AUDITD WARNING - auditing enabled, rules not immutable, 4 rules | rules=4;;;0 lost=0c;;;0\nrules sha256 $ok_hash\n",
	'auditd, --immutable'
);
is(
	$auditd->( 'ok', '-r', $data . '/auditd/rules.wanted' )->{stdout},
	"AUDITD CRITICAL - auditing enabled, 4 rules, 1 missing, 1 unexpected | rules=4;;;0 lost=0c;;;0\n"
		. "missing: -w /etc/group -p wa -k identity\n"
		. "unexpected: -w /etc/sudoers -p wa -k scope\n"
		. "rules sha256 $ok_hash\n",
	'auditd, --rules-file'
);
is( $auditd->( 'ok', '-H', $ok_hash )->{code},     0, 'auditd, --hash matching' );
is( $auditd->( 'ok', '-H', uc($ok_hash) )->{code}, 0, 'auditd, --hash matching, upper case' );
is(
	$auditd->( 'ok', '-H', $stopped_hash )->{stdout},
	"AUDITD CRITICAL - auditing enabled, 4 rules, rules hash differs | rules=4;;;0 lost=0c;;;0\nrules sha256 $ok_hash\n",
	'auditd, --hash differing'
);
like( $auditd->( 'ok', '-H', 'abc' )->{combined}, qr/--hash must be a SHA-256, 64 hex digits/, 'auditd, bad --hash' );
like( $auditd->( 'ok', '-m', '5' )->{combined},   qr/Unknown option: m/, 'auditd, --min-rules is gone' );
is(
	$auditd->( 'locked', '-I', '--lost-warning', '10' )->{stdout},
	"AUDITD WARNING - auditing enabled and immutable, 4 rules, 17 lost | rules=4;;;0 lost=17c;10;;0\nrules sha256 $ok_hash\n",
	'auditd, immutable, lost over --lost-warning'
);
is(
	$auditd->('stopped')->{stdout},
	"AUDITD CRITICAL - auditd not running, auditing disabled, 0 rules | rules=0;;;0 lost=0c;;;0\nrules sha256 $stopped_hash\n",
	'auditd stopped, "No rules" hashed as printed'
);
is(
	$auditd->('denied')->{stdout},
	"AUDITD UNKNOWN - auditctl -s exited 4, You must be root to run this program.\n",
	'auditd, not root'
);
like(
	$auditd->( 'ok', '-r', $data . '/auditd/nope' )->{stdout},
	qr/\AAUDITD UNKNOWN - can not read \S+nope, /,
	'auditd, --rules-file not there'
);

# selinux
my $selinux = sub {
	my ( $set, @args ) = @_;
	local $Monitoring::Sneck::Checks::selinux::SELINUXFS = $data . '/selinux/' . $set . '/selinuxfs';
	local $Monitoring::Sneck::Checks::selinux::CONFIG    = $data . '/selinux/' . $set . '/config';
	return $run->( 'selinux', @args );
};
is( $selinux->('enforcing')->{stdout}, "SELINUX OK - enforcing, targeted policy\n", 'selinux enforcing' );
is(
	$selinux->('permissive')->{stdout},
	"SELINUX CRITICAL - permissive, targeted policy, wanted enforcing, "
		. $data
		. "/selinux/permissive/config says enforcing from the next boot\n",
	'selinux permissive'
);
is( $selinux->( 'permissive', '-m', 'permissive' )->{code}, 1, 'selinux, config differing is WARNING' );
is( $selinux->('disabled')->{stdout}, "SELINUX CRITICAL - disabled, wanted enforcing\n", 'selinux disabled' );
is( $selinux->( 'disabled', '-m', 'disabled' )->{stdout}, "SELINUX OK - disabled\n",     'selinux disabled, wanted' );
like(
	$selinux->( 'disabled', '-m', 'off' )->{combined},
	qr/--mode must be enforcing, permissive, or disabled/,
	'selinux, bad --mode'
);

# apparmor
local $Monitoring::Sneck::Checks::apparmor::PROFILES = $data . '/apparmor/profiles';
local $Monitoring::Sneck::Checks::apparmor::ENABLED  = $data . '/apparmor/enabled';
my $counts = '12 profiles, 6 complain, 5 enforce, 1 unconfined';
is(
	$run->('apparmor')->{stdout},
	"APPARMOR WARNING - $counts, complaining: /usr/bin/firefox, lsb_release, nvidia_modprobe,"
		. " nvidia_modprobe//kmod, php-fpm and 1 more | profiles=12;;;0 complain=6;;;0\n"
		. join(
			'',
			map { 'complaining: ' . $_ . "\n" } (
				'/usr/bin/firefox', 'lsb_release', 'nvidia_modprobe', 'nvidia_modprobe//kmod',
				'php-fpm',          'torbrowser_tor'
			)
		),
	'apparmor, complaining, unconfined not warned about'
);
is(
	$run->(
		'apparmor', '-x', '^/usr/bin/firefox', '-x', '^nvidia_modprobe', '-x',
		'^(lsb_release|torbrowser)', '-p', 'php-fpm'
	)->{stdout},
	"APPARMOR CRITICAL - $counts, php-fpm in complain mode | profiles=12;;;0 complain=6;;;0\n",
	'apparmor, --exclude, --profile complaining'
);
is(
	$run->( 'apparmor', '-x', '.', '-p', '/usr/sbin/nginx', '-p', 'sshd', '-m', '20' )->{stdout},
	"APPARMOR CRITICAL - $counts, under 20, sshd not loaded | profiles=12;;;0 complain=6;;;0\n",
	'apparmor, --profile not loaded, --min-profiles'
);
is( $run->( 'apparmor', '-x', '.' )->{code}, 0, 'apparmor, all complaining excluded' );
{
	local $Monitoring::Sneck::Checks::apparmor::ENABLED = $data . '/apparmor/disabled';
	is( $run->('apparmor')->{stdout}, "APPARMOR CRITICAL - AppArmor is not enabled\n", 'apparmor disabled' );
}
{
	local $Monitoring::Sneck::Checks::apparmor::PROFILES = $data . '/apparmor/nope';
	like(
		$run->('apparmor')->{stdout},
		qr/\AAPPARMOR UNKNOWN - can not read \S+nope, /,
		'apparmor, profiles not readable'
	);
}

# Linux only
{
	local $Monitoring::Sneck::Checks::base::OS = 'freebsd';
	foreach my $check ( 'auditd', 'selinux', 'apparmor' ) {
		like( $run->($check)->{combined}, qr/not supported on freebsd/, $check . ', not Linux' );
	}
}

done_testing();
