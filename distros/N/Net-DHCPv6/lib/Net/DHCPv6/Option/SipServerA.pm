#!/usr/bin/false
# ABSTRACT: SIP Server A option (code 22) — list of IPv6 addresses
# PODNAME: Net::DHCPv6::Option::SipServerA
package Net::DHCPv6::Option::SipServerA;
$Net::DHCPv6::Option::SipServerA::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use Ref::Util qw(is_plain_arrayref);
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    my $addrs = $args{servers} // $args{addresses} // [];
    $addrs      = [$addrs] unless is_plain_arrayref( $addrs );
    $args{code} = $OPTION_SIP_SERVER_A;
    $args{data} = join( '', @$addrs );
    my $self = $class->SUPER::new( %args );
    $self->{servers} = $addrs;
    bless $self, $class;
}

sub servers { shift->{servers} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated SipServerA option' )
        if CORE::length( $data ) % 16 != 0;
    my @addrs;
    for ( my $i = 0 ; $i < CORE::length( $data ) ; $i += 16 ) {
        push @addrs, substr( $data, $i, 16 );
    }
    return $class->new( servers => \@addrs );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_SIP_SERVER_A} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::SipServerA - SIP Server A option (code 22) — list of IPv6 addresses

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::SipServerA;
  my $opt = Net::DHCPv6::Option::SipServerA->new(
      servers => [ $ipv6_bytes ],
  );

=head1 DESCRIPTION

Carries a list of IPv6 addresses of SIP servers available to
the client.  See RFC 3319.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Optional C<servers> (arrayref of 16-byte IPv6 addresses).

=head2 servers

Returns an arrayref of 16-byte IPv6 addresses.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
