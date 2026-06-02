#!/bin/false
# ABSTRACT: Boot File URL option (code 59) -- URL for network boot
# PODNAME: Net::DHCPv6::Option::BootfileUrl
use strictures 2;

package Net::DHCPv6::Option::BootfileUrl;
$Net::DHCPv6::Option::BootfileUrl::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Carp qw( croak );
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'BootfileUrl requires url' unless defined $args{url};
    $args{code} = $OPTION_BOOTFILE_URL;
    $args{data} = $args{url};
    my $self = $class->SUPER::new( %args );
    $self->{url} = $args{url};
    return bless $self, $class;
}

sub url { return shift->{url} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated BootfileUrl option' )
        if CORE::length( $payload ) == 0;
    return $class->new( url => $payload );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_BOOTFILE_URL} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::BootfileUrl - Boot File URL option (code 59) -- URL for network boot

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Net::DHCPv6::Option::BootfileUrl;
  my $opt = Net::DHCPv6::Option::BootfileUrl->new(
      url => 'tftp://192.0.2.1/bootfile',
  );

=head1 DESCRIPTION

Carries a URL pointing to a boot file for network boot (PXE, UEFI,
etc.).  See RFC 5970.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<url>.

=head2 url

Returns the boot file URL string.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
