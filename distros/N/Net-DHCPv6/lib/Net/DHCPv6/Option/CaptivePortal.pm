#!/usr/bin/false
# ABSTRACT: DHCP Captive-Portal option (code 103) — captive portal API URI
# PODNAME: Net::DHCPv6::Option::CaptivePortal
package Net::DHCPv6::Option::CaptivePortal;
$Net::DHCPv6::Option::CaptivePortal::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'CaptivePortal requires uri' unless defined $args{uri};
    $args{code} = $OPTION_CAPTIVE_PORTAL;
    $args{data} = $args{uri};
    my $self = $class->SUPER::new( %args );
    $self->{uri} = $args{uri};
    bless $self, $class;
}

sub uri { shift->{uri} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated CaptivePortal option' )
        if CORE::length( $data ) == 0;
    return $class->new( uri => $data );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_CAPTIVE_PORTAL} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::CaptivePortal - DHCP Captive-Portal option (code 103) — captive portal API URI

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::CaptivePortal;
  my $opt = Net::DHCPv6::Option::CaptivePortal->new(
      uri => 'https://example.com/portal',
  );

=head1 DESCRIPTION

Carries a URI for a captive portal API endpoint, allowing clients to
detect and interact with captive portals.  See RFC 8910.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<uri>.

=head2 uri

Returns the captive portal API URI.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
