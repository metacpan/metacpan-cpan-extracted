package Monitoring::Sneck::Checks::ntp;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';
use IO::Select  ();
use Time::HiRes ();

=head1 NAME

Monitoring::Sneck::Checks::ntp - checks the local clock against a NTP server

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Seconds from 1900, where NTP time starts, to 1970.
our $NTP_EPOCH = 2208988800;

=head1 SYNOPSIS

    clock|perl:ntp -H pool.ntp.org
    clock_tight|perl:ntp -H 192.0.2.123 -w 0.5 -c 1

=head1 DESCRIPTION

Asks a NTP server for the time over UDP and works out how far the local
clock is off from it, the same as check_ntp_time. The offset, either
way, is checked against the ranges.

No reply, a server that says it is not synced, being stratum 16 or
having its leap indicator set to 3, or a kiss of death, such as RATE,
are CRITICAL. A reply that is not for what was sent is UNKNOWN.

=head1 OPTIONS

- -H, --hostname :: The NTP server. Required.

- -p, --port :: The port.
Default :: 123

- -w, --warning :: Range of seconds for the offset.
Default :: 60

- -c, --critical :: Range of seconds for the offset.
Default :: 120

=cut

sub option_spec { return ( 'hostname|H=s', 'port|p=i', 'warning|w=s', 'critical|c=s' ) }

sub defaults { return { port => 123, warning => '60', critical => '120' } }

sub required { return ('hostname') }

sub ranges { return ( 'warning', 'critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	return ( '--hostname "' . $options->{hostname} . '" is not a IP or hostname' )
		if defined( $options->{hostname} ) && !$self->is_host( $options->{hostname} );

	return ();
}

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	require IO::Socket::IP;
	my $where  = $self->opt('hostname') . ':' . $self->opt('port');
	my $socket = IO::Socket::IP->new(
		PeerHost => $self->opt('hostname'),
		PeerPort => $self->opt('port'),
		Proto    => 'udp',
	);
	if ( !defined($socket) ) {
		return $self->finish( $self->CRITICAL, $where . ', ' . ( $@ || $! ) );
	}

	# leap indicator 0, version 4, mode 3 for a client, and when it was sent as the transmit time
	my $sent    = Time::HiRes::time;
	my $stamp   = _to_ntp($sent);
	my $request = pack( 'C', 0x23 ) . ( "\0" x 39 ) . $stamp;
	send( $socket, $request, 0 );
	my $reply;
	if ( IO::Select->new($socket)->can_read( $self->timeout ) ) {
		recv( $socket, $reply, 1024, 0 );
	}
	my $received = Time::HiRes::time;
	close($socket);
	if ( !defined($reply) || length($reply) < 48 ) {
		return $self->finish( $self->CRITICAL, 'no reply from ' . $where );
	}

	my ( $flags, $stratum ) = unpack( 'C C', $reply );
	my $leap = $flags >> 6;
	my $mode = $flags & 0x07;
	if ( $mode != 4 || substr( $reply, 24, 8 ) ne $stamp ) {
		return $self->finish( $self->UNKNOWN, $where . ' sent a reply that is not for what was sent' );
	}
	if ( $stratum == 0 ) {
		my $code = substr( $reply, 12, 4 ) =~ s/[^\x20-\x7e]//gr;
		return $self->finish( $self->CRITICAL, $where . ' sent a kiss of death, ' . $code );
	}
	if ( $stratum >= 16 || $leap == 3 ) {
		return $self->finish( $self->CRITICAL, $where . ' is not synced, stratum ' . $stratum );
	}

	# offset is ((T2 - T1) + (T3 - T4)) / 2 and delay (T4 - T1) - (T3 - T2)
	my $server_received = _from_ntp( substr( $reply, 32, 8 ) );
	my $server_sent     = _from_ntp( substr( $reply, 40, 8 ) );
	my $offset          = sprintf( '%.6f', ( ( $server_received - $sent ) + ( $server_sent - $received ) ) / 2 );
	my $delay           = sprintf( '%.6f', ( $received - $sent ) - ( $server_sent - $server_received ) );

	$self->perfdata(
		label    => 'offset',
		value    => $offset,
		uom      => 's',
		warning  => $self->opt('warning'),
		critical => $self->opt('critical')
	);
	$self->perfdata( label => 'delay',   value => $delay,   uom => 's', min => 0 );
	$self->perfdata( label => 'stratum', value => $stratum, min => 0,   max => 16 );
	my $code = $self->threshold_status( abs($offset), $self->opt('warning'), $self->opt('critical') );

	return $self->finish( $code, 'offset ' . $offset . ' seconds from ' . $where . ', stratum ' . $stratum );
} ## end sub check

# Turns a time since epoch into a NTP time stamp.
#
# Args...
#
#     - time :: Seconds since epoch, with a fraction.
#
# Returns the 8 bytes of the time stamp, seconds since 1900 and a 32 bit
# fraction, both big endian.
#
# Example...
#
#     _to_ntp(1793530999.5);
#     # pack( 'N N', 4002519799, 2147483648 )
sub _to_ntp {
	my ($time) = @_;

	my $seconds = int($time);

	return pack( 'N N', $seconds + $NTP_EPOCH, int( ( $time - $seconds ) * 4294967296 ) );
}

# Turns a NTP time stamp into a time since epoch.
#
# Args...
#
#     - stamp :: The 8 bytes of the time stamp.
#
# Returns seconds since epoch, with a fraction.
#
# Example...
#
#     _from_ntp( pack( 'N N', 4002519799, 2147483648 ) );
#     # 1793530999.5
sub _from_ntp {
	my ($stamp) = @_;

	my ( $seconds, $fraction ) = unpack( 'N N', $stamp );

	return $seconds - $NTP_EPOCH + $fraction / 4294967296;
}

1;
