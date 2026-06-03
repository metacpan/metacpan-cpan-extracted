#!/bin/false
# ABSTRACT: MUD URL option (code 112) -- Manufacturer Usage Description URL
# PODNAME: Net::DHCPv6::Option::MudUrl
use strictures 2;

package Net::DHCPv6::Option::MudUrl;
$Net::DHCPv6::Option::MudUrl::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Carp                    qw( croak );
use Net::DHCPv6::Constants  qw(
    $OPTION_MUD_URL
);
use Net::DHCPv6::X::Truncated ();
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'MudUrl requires url' unless defined $args{url};
    $args{code} = $OPTION_MUD_URL;
    $args{data} = $args{url};
    my $self = $class->SUPER::new( %args );
    $self->{url} = $args{url};
    return bless $self, $class;
}

sub url { return shift->{url} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated MudUrl option' )
        if CORE::length( $payload ) == 0;
    return $class->new( url => $payload );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_MUD_URL} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::MudUrl - MUD URL option (code 112) -- Manufacturer Usage Description URL

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Net::DHCPv6::Option::MudUrl;
  my $opt = Net::DHCPv6::Option::MudUrl->new(
      url => 'https://mud.example.com/device.json',
  );

=head1 DESCRIPTION

Carries a URL to a Manufacturer Usage Description (MUD) file
that describes the device's network behaviour.  See RFC 8520.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<url>.

=head2 url

Returns the URL string.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
