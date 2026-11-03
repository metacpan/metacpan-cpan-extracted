#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;
use IO::Socket::IP;
use Time::HiRes ();
use Monitoring::Sneck::Checks;

plan( skip_all => 'needs fork' ) if $^O eq 'MSWin32';

# a NTP server whose clock is off by $offset, or that answers oddly, by the first byte asked
my $server = IO::Socket::IP->new( LocalHost => '127.0.0.1', LocalPort => 0, Proto => 'udp' ) or die($@);
my $port   = $server->sockport;
my $pid    = fork();
die($!) if !defined($pid);
if ( !$pid ) {
	while (1) {
		my $from   = recv( $server, my $request, 1024, 0 ) or next;
		my $offset = unpack( 'n', substr( $request, 2, 2 ) ) - 1000;
		my $how    = unpack( 'C', substr( $request, 4, 1 ) );
		my $now    = Time::HiRes::time + $offset;
		my $stamp  = pack( 'N N', int($now) + 2208988800, int( ( $now - int($now) ) * 4294967296 ) );
		my ( $flags, $stratum, $refid ) = ( 0x24, 2, "\0\0\0\0" );
		( $flags,   $stratum ) = ( 0xe4, 16 )     if $how == 1;
		( $stratum, $refid )   = ( 0,    'RATE' ) if $how == 2;
		$flags = 0x23 if $how == 3;
		my $originate = $how == 4 ? "\0" x 8 : substr( $request, 40, 8 );
		my $reply
			= pack( 'C C C c', $flags, $stratum, 6, -20 )
			. ( "\0" x 8 )
			. $refid
			. $stamp
			. $originate
			. $stamp
			. $stamp;
		send( $server, $reply, 0, $from ) if $how != 5;
	} ## end while (1)
} ## end if ( !$pid )
END { kill( 'TERM', $pid ) if $pid }

# the client puts the offset and how to answer in bytes the server ignores, through a wrapped send
my ( $offset, $how ) = ( 0, 0 );
{
	no warnings 'redefine', 'once';
	*Monitoring::Sneck::Checks::ntp::send = sub {
		my ( $socket, $request, $flags ) = @_;
		substr( $request, 2, 2 ) = pack( 'n', $offset + 1000 );
		substr( $request, 4, 1 ) = pack( 'C', $how );
		return CORE::send( $socket, $request, $flags );
	};
}
my $ntp = sub {
	my ( $wanted_offset, $wanted_how, @args ) = @_;
	( $offset, $how ) = ( $wanted_offset, $wanted_how );
	return Monitoring::Sneck::Checks->run(
		check   => 'ntp',
		args    => [ '-H', '127.0.0.1', '-p', $port, @args ],
		timeout => 3
	);
};

my $return = $ntp->( 0, 0 );
is( $return->{code}, 0, 'in sync' );
like(
	$return->{stdout},
	qr/\ANTP OK - offset -?0\.0\d+ seconds from 127.0.0.1:$port, stratum 2 \| offset=-?[0-9.]+s;60;120 delay=-?[0-9.]+s;;;0 stratum=2;;;0;16\n\z/,
	'output'
);
is( $ntp->( 90,   0 )->{code}, 1, '90 seconds ahead is WARNING' );
is( $ntp->( -200, 0 )->{code}, 2, '200 seconds behind is CRITICAL' );
is( $ntp->( 2, 0, '-w', 1, '-c', 5 )->{code}, 1, 'ranges' );
like( $ntp->( 0, 1 )->{stdout}, qr/is not synced, stratum 16/,                                       'not synced' );
like( $ntp->( 0, 2 )->{stdout}, qr/\ANTP CRITICAL - 127.0.0.1:$port sent a kiss of death, RATE\n\z/, 'kiss of death' );
is( $ntp->( 0, 3 )->{code}, 3, 'not a server reply is UNKNOWN' );
is( $ntp->( 0, 4 )->{code}, 3, 'reply not for what was sent is UNKNOWN' );
like( $ntp->( 0, 5, '-t', 1 )->{stdout}, qr/\ANTP CRITICAL - no reply from/, 'no reply' );
is( $ntp->( 0, 0, '-w', 'x' )->{code}, 3, 'bad range' );

done_testing();
