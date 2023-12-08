package Net::DNS::Multicast;

use strict;
use warnings;

our $VERSION;
$VERSION = '1.00';

use Net::DNS qw(:DEFAULT);
use base     qw(Exporter Net::DNS);

our @EXPORT = @Net::DNS::EXPORT;

use IO::Select;
use IO::Socket;
use Socket qw(	pack_ipv6_mreq inet_pton
		IPPROTO_IPV6 IPV6_JOIN_GROUP IPV6_MULTICAST_LOOP);

=head1 NAME

Net::DNS::Multicast - Multicast extension to Net::DNS

=head1 SYNOPSIS

    use Net::DNS::Multicast;
    my $resolver = Net::DNS::Resolver->new();
    my $response = $resolver->send( 'host.local.', 'AAAA' );

    my $handle = $resolver->bgsend( '_ipp._tcp.local.', 'PTR' );
    while ( my $response = $resolver->bgread($handle) ) {
	$response->print;
    }

=head1 DESCRIPTION

Net::DNS::Multicast is installed as an extension to an existing Net::DNS
installation providing packages to support simple IP multicast queries
as described in RFC6762(5.1).

The multicast feature is activated by substituting Net::DNS::Multicast
for Net::DNS in the use declaration.

The use of IP Multicast is confined to the link-local domain names
listed in RFC6762. Queries for other names in the global DNS are
directed to the configured nameservers.

=cut


## no critic
use constant SOCKOPT => eval {		## precompile multicast socket options
	use constant ADDRESS => 'FF02::FB';
	use constant IP6MREQ => pack_ipv6_mreq( inet_pton( AF_INET6, ADDRESS ), 0 );

	use constant T => pack( 'i', 1 );
	use constant F => pack( 'i', 0 );
	my @sockopt;						# check option names are acceptable
	push @sockopt, eval '[SOL_SOCKET,   SO_REUSEADDR,	 T]';
	push @sockopt, eval '[SOL_SOCKET,   SO_REUSEPORT,	 T]';
	push @sockopt, eval '[IPPROTO_IPV6, IPV6_MULTICAST_LOOP, F]';
	push @sockopt, eval '[IPPROTO_IPV6, IPV6_JOIN_GROUP,	 IP6MREQ]';

	my $resolver = Net::DNS::Resolver->new();
	my $tolerate = sub {					# check options are safe to use
		return defined eval { $resolver->_create_udp_socket( ADDRESS, Sockopts => [shift] ) }
	};
	return grep { &$tolerate($_) } @sockopt;		# without any guarantee that they work!
};


## Insert methods into (otherwise empty) Net::DNS::Resolver package

my @multicast_group   = qw(FF02::FB 224.0.0.251);
my $multicast_port    = 5353;
my $multicast_timeout = 5;

my $NAME_REGEX = q/\.(local|[89AB]\.E\.F\.ip6\.arpa|254\.169\.in-addr\.arpa)$/;


sub Net::DNS::Resolver::send {
	my ( $self, @argument ) = @_;
	my $packet = $self->_make_query_packet(@argument);
	my ($q) = $packet->question;

	return Net::DNS::Resolver::Base::send( $self, $packet ) unless $q->qname =~ /$NAME_REGEX/oi;

	my $handle = $self->bgsend($packet);
	return $self->bgread($handle);
}


sub Net::DNS::Resolver::bgsend {
	my ( $self, @argument ) = @_;
	my $packet = $self->_make_query_packet(@argument);
	my ($query) = $packet->question;

	return IO::Select->new( Net::DNS::Resolver::Base::bgsend( $self, $packet ) )
			unless $query->qname =~ /$NAME_REGEX/oi;

	my $select = IO::Select->new();
	my $expire = time() + $multicast_timeout;
	$self->_reset_errorstring;
	local $packet->{status} = 0;
	my $qm = $packet->data;
	local $query->{qclass};
	$query->unicast_response(1);
	my $qu = $packet->data;

	local @{$self}{qw(nameservers nameserver4 nameserver6 port)};
	my $port = $self->port($multicast_port);
	foreach my $ip ( $self->nameservers(@multicast_group) ) {
		my $socket = $self->_create_udp_socket($ip);
		next unless $socket;				# uncoverable branch true

		$self->_diag( 'bgsend', "[$ip]:$port" );
		my $destaddr = $self->_create_dst_sockaddr( $ip, $port );
		${*$socket}{net_dns_bg} = [$expire, $packet];

		if ( $socket->sockdomain() == AF_INET6 ) {
			$socket->setsockopt( IPPROTO_IPV6, IPV6_MULTICAST_LOOP, 0 );

			my $multicast = $self->_create_udp_socket(
				$ip,
				LocalPort => $port,
				Sockopts  => [SOCKOPT],
				);
			if ($multicast) {			# uncoverable branch false
				${*$multicast}{net_dns_bg} = [$expire];
				$select->add($multicast);
				$multicast->send( $qm, 0, $destaddr );
			}
		}

		$select->add($socket);
		$socket->send( $qu, 0, $destaddr );		# unicast
	}
	return $select;
}


sub Net::DNS::Resolver::bgbusy {
	my ( $self, $select ) = @_;
	my ($handle) = ( $select->can_read(0), $select->handles );
	return Net::DNS::Resolver::Base::bgbusy( $self, $handle );
}


sub Net::DNS::Resolver::bgread {
	my ( $self, $select ) = @_;
	my $response;
	foreach my $handle ( $select->can_read(0), $select->handles ) {
		last if $response = Net::DNS::Resolver::Base::bgread( $self, $handle );
	}
	return $response;
}


## Add access methods for m-DNS flags

sub Net::DNS::Question::unicast_response {
	my ( $self, $value ) = @_;				# uncoverable pod
	my $class = $self->{qclass} || 1;			# IN implicit
	$self->{qclass} = $class |= 0x8000 if $value;		# set only
	return $class >> 15;
}

sub Net::DNS::RR::cache_flush {
	my ( $self, $value ) = @_;				# uncoverable pod
	my $class = $self->{class} || 1;			# IN implicit
	$self->{class} = $class |= 0x8000 if $value;		# set only
	return $class >> 15;
}


1;
__END__


=head1 COPYRIGHT

Copyright (c)2023 Dick Franks


All Rights Reserved


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the original copyright notices appear in all copies and that both
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


=head1 SEE ALSO

L<perl>, L<Net::DNS>, L<RFC6762|https://tools.ietf.org/html/rfc6762>,

=cut

