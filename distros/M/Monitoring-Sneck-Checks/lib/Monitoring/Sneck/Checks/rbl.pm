package Monitoring::Sneck::Checks::rbl;

use 5.014;
use strict;
use warnings;
use parent 'Monitoring::Sneck::Checks::base';

=head1 NAME

Monitoring::Sneck::Checks::rbl - checks if a host is on DNS block lists

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    rbl_mail|perl:rbl -H 192.0.2.25 -s zen.spamhaus.org -s bl.spamcop.net
    rbl_mx|perl:rbl -H mail.example.org -s zen.spamhaus.org -w 0 -c 1

=head1 DESCRIPTION

Looks each address of a host up on each block list given, through
L<Net::DNS>, with L<Net::IP> for the reversed address. A hostname is
looked up for its A and AAAA records first.

A listing is a A record for it. The number of listings is checked
against the ranges, so by default any is CRITICAL. A lookup that gets
no usable reply, such as none at all or SERVFAIL, is UNKNOWN, unless
the listings are worse.

=head1 OPTIONS

- -H, --hostname :: The IP or host. Required.

- -s, --rbl :: A block list zone, such as zen.spamhaus.org. May be given
more than once. Required.

- --server :: A DNS server to ask. May be given more than once. The
system's if not given.

- -w, --warning :: Range for the number of listings.

- -c, --critical :: Range for the number of listings.
Default :: 0

=cut

sub option_spec { return ( 'hostname|H=s', 'rbl|s=s@', 'server=s@', 'warning|w=s', 'critical|c=s' ) }

sub defaults { return { critical => '0' } }

sub required { return ( 'hostname', 'rbl' ) }

sub ranges { return ( 'warning', 'critical' ) }

sub validate {
	my ( $self, $options ) = @_;

	my @problems;
	push( @problems, '--hostname "' . $options->{hostname} . '" is not a IP or hostname' )
		if defined( $options->{hostname} ) && !$self->is_host( $options->{hostname} );
	foreach my $zone ( @{ $options->{rbl} // [] } ) {
		push( @problems, '--rbl "' . $zone . '" is not a zone' ) if !$self->is_host($zone);
	}

	return @problems;
} ## end sub validate

=head1 METHODS

=head2 check

Does the check.

=cut

sub check {
	my ($self) = @_;

	require Net::IP;
	require Data::Validate::IP;
	my $resolver = $self->resolver( servers => $self->opt('server') );
	my $host     = $self->opt('hostname');
	my @addresses;
	if ( Data::Validate::IP::is_ip($host) ) {
		@addresses = ($host);
	} else {
		foreach my $type ( 'A', 'AAAA' ) {
			my $reply = $resolver->send( $host, $type );
			next if !defined($reply);
			push( @addresses,
				map { $type eq 'AAAA' ? $_->address_short : $_->address }
				grep { $_->type eq $type } $reply->answer );
		}
		if ( !defined( $addresses[0] ) ) {
			return $self->finish( $self->UNKNOWN, 'could not look up ' . $host );
		}
	} ## end else [ if ( Data::Validate::IP::is_ip($host) ) ]

	my @listed;
	my @failed;
	my $lookups = 0;
	foreach my $address (@addresses) {
		my $reversed = Net::IP->new($address)->reverse_ip;
		$reversed =~ s/\.(?:in-addr|ip6)\.arpa\.?\z//;
		foreach my $zone ( @{ $self->opt('rbl') } ) {
			$lookups++;
			my $reply = $resolver->send( $reversed . '.' . $zone, 'A' );
			if ( !defined($reply) || $reply->header->rcode !~ /\A(?:NOERROR|NXDOMAIN)\z/ ) {
				push( @failed, $address . ' on ' . $zone );
				next;
			}
			my @answers = map { $_->address } grep { $_->type eq 'A' } $reply->answer;
			push( @listed, $address . ' on ' . $zone . ' (' . join( ', ', @answers ) . ')' ) if defined( $answers[0] );
		} ## end foreach my $zone ( @{ $self->opt('rbl') } )
	} ## end foreach my $address (@addresses)

	my $count = scalar(@listed);
	$self->perfdata(
		label    => 'listed',
		value    => $count,
		warning  => $self->opt('warning'),
		critical => $self->opt('critical'),
		min      => 0
	);
	my @codes = ( $self->threshold_status( $count, $self->opt('warning'), $self->opt('critical') ) );
	push( @codes, $self->UNKNOWN ) if defined( $failed[0] );

	my $message = join( ', ', @addresses ) . ' listed ' . $count . ' times in ' . $lookups . ' lookups';
	$message = $message . ', ' . join( ', ', @listed )               if defined( $listed[0] );
	$message = $message . ', no answer for ' . join( ', ', @failed ) if defined( $failed[0] );

	return $self->finish( $self->worst(@codes), $message );
} ## end sub check

1;
