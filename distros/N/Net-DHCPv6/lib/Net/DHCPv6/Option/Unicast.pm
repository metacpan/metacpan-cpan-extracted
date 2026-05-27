#!/usr/bin/false
# ABSTRACT: UNICAST option (code 12) — server IPv6 address
# PODNAME: Net::DHCPv6::Option::Unicast
package Net::DHCPv6::Option::Unicast;
$Net::DHCPv6::Option::Unicast::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'Unicast requires address'
        unless $args{address}
        && CORE::length( $args{address} ) == 16;
    $args{code} = $OPTION_UNICAST;
    $args{data} = $args{address};
    my $self = $class->SUPER::new( %args );
    $self->{address} = $args{address};
    bless $self, $class;
}

sub address { shift->{address} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated Unicast option' )
        if CORE::length( $data ) < 16;
    return $class->new( address => substr( $data, 0, 16 ) );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_UNICAST} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::Unicast - UNICAST option (code 12) — server IPv6 address

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::Unicast;
  my $opt = Net::DHCPv6::Option::Unicast->new(address => $ipv6_bytes);

=head1 DESCRIPTION

Carries the IPv6 address of a server to which the client should send
messages unicast.  See RFC 8415 §21.12.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<address>, a 16-byte IPv6 address.

=head2 address

Returns the 16-byte IPv6 address.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
