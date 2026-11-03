package Monitoring::Sneck::Checks::ping;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::ping - checks packet loss and round trip time

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    ping_gw|perl:ping -H 192.0.2.1
    ping_www|perl:ping -H www.example.org -P tcp --port 443 -w 50,20% -c 200,60%

=head1 DESCRIPTION

Pings a host through L<Net::Ping>. ICMP needs root, which sneck often
is not when run by snmpd, so --protocol tcp or udp may be needed. For
tcp, a refused connection still counts as a reply, as the host answered.

Each ping gets the timeout split between the packets.

=head1 OPTIONS

- -H, --hostname :: The host. Required.

- -p, --packets :: How many to send.
Default :: 5

- -P, --protocol :: icmp, tcp, or udp.
Default :: icmp

- --port :: The port for tcp or udp.
Default :: Net::Ping's, 7 for echo

- -w, --warning :: "ms,loss%", the round trip average and packet loss
at which it is WARNING.
Default :: 100,20%

- -c, --critical :: The same, for CRITICAL.
Default :: 500,60%

=cut

sub option_spec { return ( 'hostname|H=s', 'packets|p=i', 'protocol|P=s', 'port=i', 'warning|w=s', 'critical|c=s' ) }

sub defaults { return { packets => 5, protocol => 'icmp', warning => '100,20%', critical => '500,60%' } }

sub required { return ('hostname') }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--hostname "' . $options->{hostname} . '" is not a IP or hostname' )
		if defined( $options->{hostname} ) && !$self->is_host( $options->{hostname} );
	push( @problems, '--packets must be at least 1' )         if $options->{packets} < 1;
	push( @problems, '--protocol must be icmp, tcp, or udp' ) if $options->{protocol} !~ /\A(?:icmp|tcp|udp)\z/;
	foreach my $name ( 'warning', 'critical' ) {
		push( @problems, '--' . $name . ' must be "ms,loss%", such as 100,20%' )
			if !defined( _limits( $options->{$name} ) );
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	require Net::Ping;
	my $packets  = $self->opt('packets');
	my $per_ping = $self->timeout / $packets;
	$per_ping = 0.1 if $per_ping < 0.1;
	my $ping = Net::Ping->new( $self->opt('protocol'), $per_ping );
	$ping->hires(1);
	$ping->port_number( $self->opt('port') ) if defined( $self->opt('port') );

	my @times;
	my $address;
	foreach my $count ( 1 .. $packets ) {
		my ( $replied, $seconds, $ip ) = $ping->ping( $self->opt('hostname') );
		if ( !defined($replied) ) {
			$ping->close;
			return $self->finish( $self->CRITICAL, 'could not resolve ' . $self->opt('hostname') );
		}
		$address = $ip                  if defined($ip);
		push( @times, $seconds * 1000 ) if $replied;
	}
	$ping->close;

	my $loss = sprintf( '%.0f', ( $packets - scalar(@times) ) / $packets * 100 );
	my ( $warning_ms, $warning_loss )   = @{ _limits( $self->opt('warning') ) };
	my ( $critical_ms, $critical_loss ) = @{ _limits( $self->opt('critical') ) };
	my $host = $self->opt('hostname')
		. ( defined($address) && $address ne $self->opt('hostname') ? ' (' . $address . ')' : '' );
	$self->perfdata(
		label    => 'pl',
		value    => $loss,
		uom      => '%',
		warning  => $warning_loss,
		critical => $critical_loss,
		min      => 0,
		max      => 100
	);
	if ( !defined( $times[0] ) ) {
		return $self->finish( $self->CRITICAL, $host . ', 100% packet loss' );
	}

	my $total = 0;
	$total += $_ foreach @times;
	my $average = sprintf( '%.3f', $total / scalar(@times) );
	$self->perfdata(
		label    => 'rta',
		value    => $average,
		uom      => 'ms',
		warning  => $warning_ms,
		critical => $critical_ms,
		min      => 0
	);

	my $code = $self->OK;
	if ( $loss >= $critical_loss || $average >= $critical_ms ) {
		$code = $self->CRITICAL;
	} elsif ( $loss >= $warning_loss || $average >= $warning_ms ) {
		$code = $self->WARNING;
	}

	return $self->finish( $code, $host . ', ' . $loss . '% packet loss, rta ' . $average . ' ms' );
} ## end sub check

# Parses a --warning or --critical limit.
#
# Args...
#
#     - limit :: The text, "ms,loss%", the % being optional.
#
# Returns a array ref of the milliseconds and percent, or undef if it is
# not valid.
#
# Example...
#
#     _limits('100,20%');
#     # [ 100, 20 ]
sub _limits {
	my ($limit) = @_;

	return undef if !defined($limit) || $limit !~ /\A([0-9]+(?:\.[0-9]+)?),([0-9]+(?:\.[0-9]+)?)%?\z/;

	return [ $1, $2 ];
}

1;
