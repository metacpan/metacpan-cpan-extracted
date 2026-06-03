#!/bin/false
# ABSTRACT: UNICAST option (code 12) -- server IPv6 address
# PODNAME: Net::DHCPv6::Option::Unicast
use strictures 2;

package Net::DHCPv6::Option::Unicast;
$Net::DHCPv6::Option::Unicast::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Carp                    qw( croak );
use Net::DHCPv6::Constants  qw(
    $IPV6_ADDR_LEN $OPTION_UNICAST
);
use Net::DHCPv6::X::Truncated ();
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    my $addr = $class->_pick_addr( \%args, 'address' );
    croak 'Unicast requires address'
        unless $addr && CORE::length( $addr ) == $IPV6_ADDR_LEN;
    $args{code} = $OPTION_UNICAST;
    $args{data} = $addr;
    my $self = $class->SUPER::new( %args );
    $self->{address} = $addr;
    return bless $self, $class;
}

sub address_raw { return shift->{address} }

sub address {
    my $self = shift;
    return $self->_format_ipv6( $self->{address} );
}

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated Unicast option' )
        if CORE::length( $payload ) < $IPV6_ADDR_LEN;
    return $class->new( address_raw => substr( $payload, 0, $IPV6_ADDR_LEN ) );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_UNICAST} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::Unicast - UNICAST option (code 12) -- server IPv6 address

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Socket qw(inet_pton AF_INET6);

  # Text form (auto-resolved to wire bytes)
  my $opt = Net::DHCPv6::Option::Unicast->new(address => '2001:db8::1');
  print $opt->address;        # '2001:db8::1'
  print $opt->address_raw;    # 16-byte wire-format bytes

  # Raw bytes from text
  my $opt2 = Net::DHCPv6::Option::Unicast->new(
      address_raw => inet_pton(AF_INET6, '2001:db8::1'),
  );

=head1 DESCRIPTION

Carries the IPv6 address of a server to which the client should send
messages unicast.  See RFC 8415 E<167>21.12.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires either C<address> (text) or C<address_raw> (bytes).

=head2 address

Returns the IPv6 address as a text string.

=head2 address_raw

Returns the 16-byte wire-format address.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
