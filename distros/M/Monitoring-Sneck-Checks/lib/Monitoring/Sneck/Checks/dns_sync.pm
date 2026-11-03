package Monitoring::Sneck::Checks::dns_sync;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::dns_sync - checks a zone's nameservers have the same serial

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    zone_sync|perl:dns_sync -z example.org
    zone_sync_internal|perl:dns_sync -z internal.example.org -n 192.0.2.53 -n 192.0.2.54 -c

=head1 DESCRIPTION

Finds a zone's nameservers from its NS records, then asks each of
their addresses for the zone's SOA through L<Net::DNS>, without
recursion. A nameserver with no address, or a address that does not
answer, gives a error, or is not authoritative, is CRITICAL. That last
is a lame delegation.

Serials that differ are WARNING, as a secondary that has not caught up
yet, or CRITICAL with --critical.

=head1 OPTIONS

- -z, --zone :: The zone. Required.

- -s, --server :: A server to ask for the NS records and the addresses
of the nameservers. May be given more than once. The system's if not
given.

- -n, --nameserver :: A nameserver to check, a IP or name, in place of
looking up the NS records. May be given more than once.

- -4, --ipv4 :: Only check the IPv4 addresses of nameservers found by
name. A IP given to --nameserver is checked either way.

- -6, --ipv6 :: The same for IPv6.

- -c, --critical :: Serials that differ are CRITICAL.

=cut

sub option_spec { return ( 'zone|z=s', 'server|s=s@', 'nameserver|n=s@', 'ipv4|4', 'ipv6|6', 'critical|c' ) }

sub required { return ('zone') }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--zone "' . $options->{zone} . '" is not a zone' )
		if defined( $options->{zone} ) && !$self->is_host( $options->{zone} =~ s/\.\z//r );
	foreach my $name ( 'server', 'nameserver' ) {
		foreach my $host ( @{ $options->{$name} // [] } ) {
			push( @problems, '--' . $name . ' "' . $host . '" is not a IP or hostname' ) if !$self->is_host($host);
		}
	}
	push( @problems, '--ipv4 and --ipv6 can not both be given' ) if $options->{ipv4} && $options->{ipv6};

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	require Data::Validate::IP;
	my $zone     = $self->opt('zone') =~ s/\.\z//r;
	my $resolver = $self->resolver( servers => $self->opt('server') );
	my @names    = @{ $self->opt('nameserver') // [] };
	if ( !defined( $names[0] ) ) {
		my $reply = $resolver->send( $zone, 'NS' );
		if ( !defined($reply) ) {
			return $self->finish( $self->CRITICAL, 'no reply for ' . $zone . ' NS, ' . $resolver->errorstring );
		}
		@names = sort( map { lc( $_->nsdname ) =~ s/\.\z//r } grep { $_->type eq 'NS' } $reply->answer );
		if ( !defined( $names[0] ) ) {
			return $self->finish( $self->CRITICAL, $zone . ' has no NS records' );
		}
	} ## end if ( !defined( $names[0] ) )

	my @types = $self->opt('ipv4') ? ('A') : $self->opt('ipv6') ? ('AAAA') : ( 'A', 'AAAA' );
	my @codes;
	my @problems;
	my %serials;
	my $answered = 0;
	foreach my $name (@names) {
		my @addresses;
		if ( Data::Validate::IP::is_ip($name) ) {
			@addresses = ($name);
		} else {
			foreach my $type (@types) {
				my $reply = $resolver->send( $name, $type );
				next if !defined($reply);
				push( @addresses,
					map { $type eq 'AAAA' ? $_->address_short : $_->address }
					grep { $_->type eq $type } $reply->answer );
			}
		}
		if ( !defined( $addresses[0] ) ) {
			push( @codes,    $self->CRITICAL );
			push( @problems, $name . ' has no address' );
			next;
		}

		foreach my $address (@addresses) {
			my $where = $name eq $address ? $name : $name . ' (' . $address . ')';
			my $asker = $self->resolver( servers => [$address], no_recurse => 1 );
			my $reply = $asker->send( $zone, 'SOA' );
			my ($soa) = defined($reply) ? grep { $_->type eq 'SOA' } $reply->answer : ();
			my $problem;
			if ( !defined($reply) ) {
				$problem = 'did not answer';
			} elsif ( $reply->header->rcode ne 'NOERROR' ) {
				$problem = 'got ' . $reply->header->rcode;
			} elsif ( !$reply->header->aa ) {
				$problem = 'is not authoritative';
			} elsif ( !defined($soa) ) {
				$problem = 'has no SOA';
			}
			if ( defined($problem) ) {
				push( @codes,    $self->CRITICAL );
				push( @problems, $where . ' ' . $problem );
				next;
			}
			$answered++;
			push( @{ $serials{ $soa->serial } }, $where );
		} ## end foreach my $address (@addresses)
	} ## end foreach my $name (@names)

	my @serials = sort { $b <=> $a } keys(%serials);
	if ( scalar(@serials) > 1 ) {
		push( @codes, $self->opt('critical') ? $self->CRITICAL : $self->WARNING );
		push( @problems,
			'serials differ, ' . join( '; ', map { $_ . ' on ' . join( ', ', @{ $serials{$_} } ) } @serials ) );
	}

	# the highest serial, as the one the others should catch up to
	my $message
		= defined( $serials[0] )
		? $zone . ' serial ' . $serials[0] . ', ' . $answered . ' answered'
		: $zone . ', none answered';
	$message = $message . ', nameservers ' . join( ', ', @names );
	$message = $message . ', ' . join( ', ', @problems ) if defined( $problems[0] );

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

1;
