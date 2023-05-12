package Net::DNS::Multicast;

use strict;
use warnings;

our $VERSION;
$VERSION = '0.03';

use Net::DNS qw(:DEFAULT);
use base     qw(Exporter Net::DNS);

our @EXPORT = @Net::DNS::EXPORT;

=head1 NAME

Net::DNS::Multicast - Multicast extension to Net::DNS

=head1 SYNOPSIS

    use Net::DNS::Multicast;
    my $resolver = Net::DNS::Resolver->new();
    my $response = $resolver( 'host.local.', 'AAAA' );

=head1 DESCRIPTION

Net::DNS::Multicast is installed as an extension to an existing Net::DNS
installation providing packages to support simple IP multicast queries
as described in RFC6762(5.1).

The multicast feature is made available by replacing Net::DNS by
Net::DNS::Multicast in the use declaration.

The use of IP Multicast is confined to the link-local domains listed in
RFC6762. Queries for other names in the global DNS are directed to the
configured nameservers.

=cut


{

	package Net::DNS::Resolver;	## Add methods to (otherwise empty) package

	my $NAME_REGEX = q/\.(local|254\.169\.in-addr\.arpa|[89AB]\.E\.F\.ip6\.arpa)$/;

	sub send {
		my ( $self, @argument ) = @_;
		my $packet = $self->_make_query_packet(@argument);
		my ($q) = $packet->question;

		if ( $q->qname =~ /$NAME_REGEX/oi ) {
			local $packet->{status} = 0;
			local @{$self}{qw(nameservers nameserver4 nameserver6 port retrans)};
			$self->_reset_errorstring;
			$self->nameservers( @{$self->{multicast_group}} );
			$self->port( $self->{multicast_port} );
			$self->retrans(3);
			return $self->_send_udp( $packet, $packet->data );
		}

		return $self->SUPER::send($packet);
	}

	sub bgsend {
		my ( $self, @argument ) = @_;
		my $packet = $self->_make_query_packet(@argument);
		my ($q) = $packet->question;

		if ( $q->qname =~ /$NAME_REGEX/oi ) {
			local $packet->{status} = 0;
			local @{$self}{qw(nameservers nameserver4 nameserver6 port)};
			$self->_reset_errorstring;
			$self->nameservers( @{$self->{multicast_group}} );
			$self->port( $self->{multicast_port} );
			return $self->_bgsend_udp( $packet, $packet->data );
		}

		return $self->SUPER::bgsend($packet);
	}

	sub string {
		my $self = shift;
		return join( '', $self->SUPER::string, <<END );
;; multicast_group	@{$self->{multicast_group}}
;; multicast_ port	$self->{multicast_port}
END
	}

	my $defaults = __PACKAGE__->_defaults;
	$defaults->{multicast_group} = [qw(FF02::FB 224.0.0.251)];
	$defaults->{multicast_port}  = 5353;
}


sub Net::DNS::Question::unicast_response {
	my ( $self, @value ) = @_;				# uncoverable pod
	for (@value) { $self->{qclass} |= ( $_ << 15 ) }
	return $self->{qclass} >> 15;
}

sub Net::DNS::RR::cache_flush {
	my ( $self, @value ) = @_;				# uncoverable pod
	for (@value) { $self->{class} |= ( $_ << 15 ) }
	return $self->{class} >> 15;
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

