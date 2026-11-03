#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Net::Ping;
use Monitoring::Sneck::Checks;

# replies as @replies says, 1 for a reply, 0 for none, undef for not resolving
my @replies;
my %made;
{
	no warnings 'redefine';
	my $new = \&Net::Ping::new;
	*Net::Ping::new = sub {
		my ( $class, $protocol, $timeout ) = @_;
		%made = ( protocol => $protocol, timeout => $timeout );
		return $new->( $class, 'tcp', $timeout );
	};
	*Net::Ping::ping = sub {
		my $reply = shift(@replies);
		return ( $reply, 0.010, '192.0.2.1' ) if $reply;
		return ( $reply, 0,     undef );
	};
}
my $ping = sub {
	my ( $answers, @args ) = @_;
	@replies = @{$answers};
	return Monitoring::Sneck::Checks->run( check => 'ping', args => \@args );
};

my $return = $ping->( [ 1, 1, 1, 1, 1 ], '-H', 'gw.example.org', '-P', 'udp' );
is( $return->{code}, 0, 'all replied' );
is(
	$return->{stdout},
	"PING OK - gw.example.org (192.0.2.1), 0% packet loss, rta 10.000 ms | pl=0%;20;60;0;100 rta=10.000ms;100;500;0\n",
	'output'
);
is_deeply( \%made, { protocol => 'udp', timeout => 29 / 5 }, 'protocol and the timeout split' );
is( $ping->( [ 1, 1, 1, 1, 0 ], '-H', '192.0.2.1' )->{code}, 1, '20% loss is WARNING' );
is( $ping->( [ 1, 0, 0, 0, 0 ], '-H', '192.0.2.1' )->{code}, 2, '80% loss is CRITICAL' );
is( $ping->( [ 1, 1 ], '-H', '192.0.2.1', '-p', 2, '-w', '5,50%' )->{code}, 1, 'slow is WARNING' );
like(
	$ping->( [ 0, 0, 0, 0, 0 ], '-H', '192.0.2.1' )->{stdout},
	qr/\APING CRITICAL - 192.0.2.1, 100% packet loss \|/,
	'no replies'
);
like( $ping->( [undef], '-H', 'nope.example.org' )->{stdout}, qr/could not resolve nope.example.org/, 'not resolving' );
is( $ping->( [], '-H', '192.0.2.1', '-P', 'smoke' )->{code}, 3, 'bad protocol' );
is( $ping->( [], '-H', '192.0.2.1', '-w', '100' )->{code},   3, 'bad limit' );

done_testing();
