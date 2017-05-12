package Protocol::SOCKS;
# ABSTRACT: abstract SOCKS protocol support
use strict;
use warnings;

our $VERSION = '0.003';

=head1 NAME

Protocol::SOCKS - abstract support for the SOCKS5 network protocol

=head1 VERSION

Version 0.003

=head1 DESCRIPTION

=cut

use Future;
use Socket qw(inet_pton inet_ntop inet_ntoa AF_INET AF_INET6);

use Protocol::SOCKS::Constants qw(:all);

our %REPLY_CODE = (
	0x00 => 'succeeded',
	0x01 => 'general SOCKS server failure',
	0x02 => 'connection not allowed by ruleset',
	0x03 => 'Network unreachable',
	0x04 => 'Host unreachable',
	0x05 => 'Connection refused',
	0x06 => 'TTL expired',
	0x07 => 'Command not supported',
	0x08 => 'Address type not supported',
);

=head1 METHODS

=cut

=head2 new

Instantiates this protocol object.

=cut

sub new { my $class = shift; bless { @_ }, $class }

=head2 version

Our protocol version. Usually 5.

=cut

sub version { shift->{version} ||= 5 }

=head2 write

Called when we want to write data. Requires a writer to be configured.

=cut

sub write { $_[0]->{writer}->($_[1]) }

=head2 new_future

Instantiates a new L<Future> using the provided factory, or calls through to L<Future>->new.

=cut

sub new_future { (shift->{future_factory} ||= sub { Future->new })->() }

=head2 pack_fqdn

Packs a fully-qualified domain into a data structure.

=cut

sub pack_fqdn {
	my $self = shift;
	$self->pack_address(ATYPE_FQDN, @_)
}

=head2 pack_ipv4

Packs an IPv4 address into a data structure.

=cut

sub pack_ipv4 {
	my $self = shift;
	$self->pack_address(ATYPE_IPV4, @_)
}

=head2 pack_ipv6

Packs an IPv6 address into a data structure.

=cut

sub pack_ipv6 {
	my $self = shift;
	$self->pack_address(ATYPE_IPV6, @_)
}

=head2 pack_address

Packs an address of the given type into a data structure.

=cut

sub pack_address {
	my ($self, $type, $addr) = @_;
	if($type == ATYPE_IPV4) {
		return pack('C1', $type) . inet_pton(AF_INET, $addr);
	} elsif($type == ATYPE_IPV6) {
		return pack('C1', $type) . inet_pton(AF_INET6, $addr);
	} elsif($type == ATYPE_FQDN) {
		return pack('C1C/a*', $type, $addr);
	} else {
		die sprintf 'unknown address type 0x%02x', $type;
	}
}

=head2 extract_address

Extracts address information from a scalar ref.

=cut

sub extract_address {
	my ($self, $buf) = @_;
	return undef unless length($$buf) > 1;

	my ($type) = unpack 'C1', substr $$buf, 0, 1;
	if($type == ATYPE_IPV4) {
		return undef unless length($$buf) >= (1 + 4);
		(undef, my $ip) = unpack 'C1A4', substr $$buf, 0, 1 + 4, '';
		return '' unless $ip;
		return inet_ntoa($ip);
	} elsif($type == ATYPE_IPV6) {
		return undef unless length($$buf) >= (1 + 16);
		(undef, my $ip) = unpack 'C1A16', substr $$buf, 0, 1 + 16, '';
		return inet_ntop(AF_INET6, $ip);
	} elsif($type == ATYPE_FQDN) {
		my ($len) = unpack 'C1', substr $$buf, 1, 1;
		return undef unless length($$buf) >= (1 + 1 + $len);
		(undef, my $host) = unpack 'C1C/a*', substr $$buf, 0, 1 + 1 + $len, '';
		return $host;
	} else {
		die sprintf 'unknown address type 0x%02x', $type;
	}
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<Net::SOCKS>

=item * L<POE::Component::Client::SOCKS>

=item * L<POE::Component::Proxy::SOCKS>

=item * L<LWP::Protocol::socks>

=item * L<IO::Stream::Proxy::SOCKSv5>

=item * L<IO::Socket::Socks>

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2014. Licensed under the same terms as Perl itself.
