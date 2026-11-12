package Monitoring::Sneck::Checks::wireguard;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::wireguard - checks WireGuard peers have handshaken recently

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# Where wg is. Set by tests. Undef means the first of WG_PATHS that is there.
our $WG;
our @WG_PATHS = ( '/usr/bin/wg', '/usr/sbin/wg', '/usr/local/bin/wg' );

=head1 SYNOPSIS

    wireguard|perl:wireguard
    wireguard_wg0|perl:wireguard -i wg0 -w 180 -c 600
    wireguard_hub|perl:wireguard -k
    wireguard_site|perl:wireguard -p 'xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg='

=head1 DESCRIPTION

Checks how long ago each peer last handshook, through wg show all
dump. A peer with traffic, or persistent keepalive, handshakes about
every two minutes, so a old handshake means the tunnel is down.

A peer without persistent keepalive only handshakes when there is
traffic, so a idle one looks the same as a down one. --keepalive checks
only peers with it, for hubs with peers that come and go.

- CRITICAL :: A handshake older than --critical, or never made. A
interface or peer given that is not there.

- WARNING :: A handshake older than --warning.

- UNKNOWN :: wg not being there, or failing, as it does when not run as
root.

- OK :: Everything else, including no WireGuard interfaces.

Peers are named by interface and first allowed IP, or the start of
their public key if they have none. A line for each peer follows the
status line, with its endpoint, handshake, and transfer. Private and
preshared keys are never output.

=head1 OPTIONS

- -i, --interface :: A interface to check, instead of all of them. May
be given more than once.

- -p, --peer :: The public key of a peer to check, instead of all of
them. May be given more than once.

- -k, --keepalive :: Only check peers with persistent keepalive.

- -w, --warning :: Range for the seconds since the latest handshake.
Default :: 300

- -c, --critical :: Range for the seconds since the latest handshake.
Default :: 900

=cut

sub option_spec { return ( 'interface|i=s@', 'peer|p=s@', 'keepalive|k', 'warning|w=s', 'critical|c=s' ) }

sub defaults { return { warning => '300', critical => '900' } }

sub ranges { return ( 'warning', 'critical' ) }

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	my $wg = $WG // ( grep { -x $_ } @WG_PATHS )[0];
	return $self->finish( $self->UNKNOWN, 'wg is not there' )     if !defined($wg);
	return $self->finish( $self->UNKNOWN, $wg . ' is not there' ) if !-x $wg;

	my ( $exit, $output ) = $self->run_command( $wg, 'show', 'all', 'dump' );
	if ($exit) {
		my $first = ( grep { /\S/ } split( /\n/, $output ) )[0] // 'saying nothing';
		return $self->finish( $self->UNKNOWN, 'wg show exited ' . $exit . ', ' . $first );
	}

	# interface lines have 5 fields, the private key among them, peer lines 9
	my %interfaces;
	my @peers;
	foreach my $line ( split( /\n/, $output ) ) {
		my @fields = split( /\t/, $line );
		if ( @fields == 5 ) {
			$interfaces{ $fields[0] } = 1;
		} elsif ( @fields == 9 ) {
			push(
				@peers,
				{
					interface => $fields[0],
					key       => $fields[1],
					endpoint  => $fields[3],
					allowed   => ( split( /,/, $fields[4] ) )[0],
					handshake => $fields[5],
					received  => $fields[6],
					sent      => $fields[7],
					keepalive => $fields[8],
				}
			);
		} ## end elsif ( @fields == 9 )
	} ## end foreach my $line ( split( /\n/, $output ) )

	my @codes = ( $self->OK );
	my @parts;
	my @interfaces_wanted = @{ $self->opt('interface') // [] };
	foreach my $interface ( grep { !$interfaces{$_} } @interfaces_wanted ) {
		push( @codes, $self->CRITICAL );
		push( @parts, $interface . ' is not there' );
	}
	my %interface_wanted = map { $_ => 1 } @interfaces_wanted;
	@peers = grep { $interface_wanted{ $_->{interface} } } @peers if defined( $interfaces_wanted[0] );

	my @keys_wanted = @{ $self->opt('peer') // [] };
	foreach my $key (@keys_wanted) {
		next if grep { $_->{key} eq $key } @peers;
		push( @codes, $self->CRITICAL );
		push( @parts, 'peer ' . substr( $key, 0, 8 ) . ' is not there' );
	}
	my %key_wanted = map { $_ => 1 } @keys_wanted;
	@peers = grep { $key_wanted{ $_->{key} } } @peers                    if defined( $keys_wanted[0] );
	@peers = grep { $_->{keepalive} ne 'off' && $_->{keepalive} } @peers if $self->opt('keepalive');

	if ( !defined( $peers[0] ) && !defined( $parts[0] ) ) {
		return $self->finish( $self->OK, %interfaces ? 'no peers to check' : 'no WireGuard interfaces' );
	}

	my $now   = time;
	my $stale = 0;
	my @details;
	foreach my $peer (@peers) {
		my $name
			= $peer->{interface} . ' '
			. (
				( defined( $peer->{allowed} ) && $peer->{allowed} ne '(none)' )
				? $peer->{allowed}
				: substr( $peer->{key}, 0, 8 )
			);

		# a handshake of 0 is never, which is as old as can be
		my $age       = $peer->{handshake} ? $now - $peer->{handshake}            : 9**9**9;
		my $handshake = $peer->{handshake} ? 'handshake ' . $age . ' seconds ago' : 'never handshaken';
		my $code      = $self->threshold_status( $age, $self->opt('warning'), $self->opt('critical') );
		push( @codes, $code );
		if ( $code != $self->OK ) {
			$stale++;
			push( @parts, $name . ' ' . $handshake );
		}
		push( @details,
				  $name
				. ', endpoint '
				. $peer->{endpoint} . ', '
				. $handshake
				. ', received '
				. $peer->{received}
				. ' B, sent '
				. $peer->{sent}
				. ' B' );
	} ## end foreach my $peer (@peers)

	my $fine = scalar(@peers) - $stale;
	if ($fine) {
		my $noun = defined( $parts[0] ) ? 'other' : 'peer';
		$noun = $noun . 's' if $fine > 1;
		push( @parts, $fine . ' ' . $noun . ' ok' );
	}
	$self->perfdata( label => 'peers', value => scalar(@peers), min => 0 );
	$self->perfdata( label => 'stale', value => $stale,         min => 0 );

	return $self->finish( $self->worst(@codes), join( ', ', @parts ), @details );
} ## end sub check

1;
