#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::fail2ban;

# the fake fail2ban-client prints t/data/fail2ban/$FAIL2BAN_TEST_SET/status or status.$jail
local $Monitoring::Sneck::Checks::fail2ban::FAIL2BAN_CLIENT = $FindBin::Bin . '/data/fail2ban/fail2ban-client';
my $run = sub {
	my ( $set, @args ) = @_;
	local $ENV{FAIL2BAN_TEST_SET} = $set;
	return Monitoring::Sneck::Checks->run( check => 'fail2ban', args => \@args );
};

my $perf
	= 'sshd_banned=2;;;0 sshd_failed=3;;;0 sshd_total_banned=15c;;;0 sshd_total_failed=120c;;;0'
	. ' postfix-sasl_banned=0;;;0 postfix-sasl_failed=0;;;0 postfix-sasl_total_banned=1c;;;0'
	. ' postfix-sasl_total_failed=4c;;;0';
is(
	$run->('ok')->{stdout},
	"FAIL2BAN OK - 2 jails, 2 banned now: sshd 2, postfix-sasl 0 | $perf banned=2;;;0\n",
	'jails up, file and journal backends'
);
is(
	$run->( 'ok', '-j', 'sshd', '-j', 'dovecot' )->{stdout},
	"FAIL2BAN CRITICAL - 2 jails, dovecot not running, 2 banned now: sshd 2, postfix-sasl 0 | $perf banned=2;;;0\n",
	'--jail, one not running'
);
is( $run->( 'ok', '-j', 'sshd', '-j', 'postfix-sasl' )->{code}, 0, '--jail, all running' );
is( $run->( 'ok', '-w', '1' )->{code}, 1, 'banned over --warning' );
like( $run->( 'ok', '-c', '1' )->{stdout}, qr/\AFAIL2BAN CRITICAL - .* banned=2;;1;0\n\z/, 'banned over --critical' );
is( $run->('none')->{stdout}, "FAIL2BAN WARNING - no jails running\n", 'no jails' );
is(
	$run->( 'none', '-j', 'sshd' )->{stdout},
	"FAIL2BAN CRITICAL - sshd not running, no jails running\n",
	'no jails, --jail'
);
is(
	$run->('down')->{stdout},
	"FAIL2BAN CRITICAL - fail2ban-client status exited 255,"
		. " Failed to access socket path: /var/run/fail2ban/fail2ban.sock. Is fail2ban running?\n",
	'fail2ban down'
);
is(
	$run->('denied')->{stdout},
	"FAIL2BAN UNKNOWN - fail2ban-client status exited 255,"
		. " Permission denied to socket: /var/run/fail2ban/fail2ban.sock, (you must be root)\n",
	'not root'
);
is(
	$run->('broken')->{stdout},
	"FAIL2BAN UNKNOWN - fail2ban-client status sshd did not say how many are banned\n",
	'jail status without counts'
);
{
	local $Monitoring::Sneck::Checks::fail2ban::FAIL2BAN_CLIENT = $FindBin::Bin . '/data/fail2ban/nope';
	like( $run->('ok')->{stdout}, qr/\AFAIL2BAN UNKNOWN - \S+nope is not there\n\z/, 'fail2ban-client not there' );
}

done_testing();
