#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use Monitoring::Sneck::Checks;
use Monitoring::Sneck::Checks::mailq;

# the fake postqueue and exim print t/data/mailq/$MAILQ_TEST_SET/output, arrival times in it relative to now
my $mta = $FindBin::Bin . '/data/mailq/mta';
local $Monitoring::Sneck::Checks::mailq::POSTQUEUE = $mta;
local $Monitoring::Sneck::Checks::mailq::EXIM      = $mta;
my $run = sub {
	my ( $set, @args ) = @_;
	local $ENV{MAILQ_TEST_SET} = $set;
	return Monitoring::Sneck::Checks->run( check => 'mailq', args => \@args );
};

# Postfix
is(
	$run->('postfix_empty')->{stdout},
	"MAILQ OK - 0 messages in the postfix queue | messages=0;50;200;0 oldest=0s;14400;;0\n",
	'Postfix, empty'
);
my $return = $run->('postfix_queue');
is( $return->{code}, 0, 'Postfix, a few queued' );
like(
	$return->{stdout},
	qr/\AMAILQ OK - 3 messages in the postfix queue, oldest 2h, 1 active, 1 deferred, 1 hold \| messages=3;50;200;0 oldest=730[0-9]s;14400;;0
4B7F9A1234 2h alice\@example.org to bob\@example.net, connect to mx.example.net\[192.0.2.25\]:25: Connection refused
5C8A0B2345 10m <> to carol\@example.com and 2 more
6D9B1C3456 30s frank\@example.org to grace\@example.net
\z/,
	'Postfix, queues counted and the oldest listed'
);
is( $return->{stderr}, '', 'Postfix, no warnings' );
$return = $run->( 'postfix_queue', '-w', '2', '-l', '1' );
is( $return->{code},                              1, 'Postfix, over --warning' );
is( scalar( split( /\n/, $return->{stdout} ) ),   2, 'Postfix, --list' );
is( $run->( 'postfix_queue', '-c', '2' )->{code}, 2, 'Postfix, over --critical' );
like(
	$run->('postfix_old')->{stdout},
	qr/\AMAILQ WARNING - 1 message in the postfix queue, oldest 2d, 1 deferred \|.*\n7EAC2D4567 2d alice\@example.org to heidi\@example.net, host mx.example.net\[192.0.2.26\] said: 451 4.7.1 Greylisted/,
	'Postfix, over --age-warning'
);
is( $run->( 'postfix_old', '-C', '86400' )->{code}, 2, 'Postfix, over --age-critical' );
is(
	$run->('postfix_down')->{combined},
	"MAILQ UNKNOWN - postqueue -j exited 69, postqueue: fatal: Queue report unavailable - mail system is down\n",
	'Postfix down'
);
is(
	$run->('postfix_garbage')->{combined},
	qq{MAILQ UNKNOWN - postqueue -j printed something not JSON, "Mail queue is empty"\n},
	'Postfix, not JSON'
);

# Exim
is(
	$run->( 'exim_queue', '-m', 'exim' )->{stdout},
	"MAILQ WARNING - 3 messages in the exim queue, oldest 2d, 1 frozen | messages=3;50;200;0 oldest=172800s;14400;;0\n"
		. "1tABCd-00000000xYz-0aBc 2d frank\@example.org to erin\@example.com\n"
		. "1i7k9a-0003Zs-Qe 4h <> to carol\@example.com\n"
		. "1i7lqn-0004Aq-2x 25m alice\@example.org to bob\@example.net\n",
	'Exim, frozen, delivered recipients left out'
);
is(
	$run->( 'exim_denied', '-m', 'exim' )->{combined},
	"MAILQ UNKNOWN - exim -bp exited 1, exim: permission denied; not admin\n",
	'Exim, not admin'
);

# finding the MTA
{
	local $Monitoring::Sneck::Checks::mailq::POSTQUEUE;
	local @Monitoring::Sneck::Checks::mailq::POSTQUEUE_PATHS = ();
	like( $run->('exim_queue')->{stdout}, qr/ in the exim queue/, 'Exim used without Postfix' );
	local $Monitoring::Sneck::Checks::mailq::EXIM;
	local @Monitoring::Sneck::Checks::mailq::EXIM_PATHS = ();
	is( $run->('exim_queue')->{stdout}, "MAILQ UNKNOWN - neither Postfix nor Exim found\n", 'neither' );
	is(
		$run->( 'exim_queue', '-m', 'postfix' )->{stdout},
		"MAILQ UNKNOWN - postqueue is not there\n",
		'forced, not there'
	);
}
like( $run->( 'x', '-m', 'sendmail' )->{combined}, qr/--mta must be postfix or exim/, 'bad --mta' );

done_testing();
