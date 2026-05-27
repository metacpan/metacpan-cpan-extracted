#!/usr/bin/false
# ABSTRACT: Client Link-Layer Address option (code 79) — link-layer type + address
# PODNAME: Net::DHCPv6::Option::ClientLinkLayerAddr
package Net::DHCPv6::Option::ClientLinkLayerAddr;
$Net::DHCPv6::Option::ClientLinkLayerAddr::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'ClientLinkLayerAddr requires link_layer_type' unless defined $args{link_layer_type};
    croak 'ClientLinkLayerAddr requires link_layer_addr' unless defined $args{link_layer_addr};
    $args{code} = $OPTION_CLIENT_LINKLAYER_ADDR;
    $args{data} = pack( 'n', $args{link_layer_type} ) . $args{link_layer_addr};
    my $self = $class->SUPER::new( %args );
    $self->{link_layer_type} = $args{link_layer_type};
    $self->{link_layer_addr} = $args{link_layer_addr};
    bless $self, $class;
}

sub link_layer_type { shift->{link_layer_type} }
sub link_layer_addr { shift->{link_layer_addr} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated ClientLinkLayerAddr option' )
        if CORE::length( $data ) < 3;
    my $type = unpack( 'n', substr( $data, 0, 2 ) );
    my $addr = substr( $data, 2 );
    return $class->new( link_layer_type => $type, link_layer_addr => $addr );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_CLIENT_LINKLAYER_ADDR} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::ClientLinkLayerAddr - Client Link-Layer Address option (code 79) — link-layer type + address

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::ClientLinkLayerAddr;
  my $opt = Net::DHCPv6::Option::ClientLinkLayerAddr->new(
      link_layer_type => 1,
      link_layer_addr => "\x00\x11\x22\x33\x44\x55",
  );

=head1 DESCRIPTION

Carries the link-layer address of the client, inserted by a relay
agent.  Consists of a 16-bit link-layer type (IANA ARP hardware type)
followed by the link-layer address.  See RFC 6939.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<link_layer_type> and C<link_layer_addr>.

=head2 link_layer_type

Returns the 16-bit link-layer type (e.g. 1 for Ethernet).

=head2 link_layer_addr

Returns the link-layer address bytes.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
