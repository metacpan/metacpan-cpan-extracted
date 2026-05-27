#!/usr/bin/false
# ABSTRACT: PD Exclude option (code 67) — prefix to exclude from IA_PD
# PODNAME: Net::DHCPv6::Option::PdExclude
package Net::DHCPv6::Option::PdExclude;
$Net::DHCPv6::Option::PdExclude::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'PdExclude requires prefix_length' unless defined $args{prefix_length};
    croak 'PdExclude requires address'       unless $args{address};
    $args{code} = $OPTION_PD_EXCLUDE;
    $args{data} = pack( 'C', $args{prefix_length} ) . $args{address};
    my $self = $class->SUPER::new( %args );
    $self->{prefix_length} = $args{prefix_length};
    $self->{address}       = $args{address};
    bless $self, $class;
}

sub prefix_length { shift->{prefix_length} }
sub address       { shift->{address} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated PdExclude option' )
        if CORE::length( $data ) < 2;
    my $plen     = unpack( 'C', substr( $data, 0, 1 ) );
    my $addr_len = ( $plen + 7 ) >> 3;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated PdExclude address' )
        if 1 + $addr_len > CORE::length( $data );
    my $addr = substr( $data, 1, $addr_len );
    return $class->new( prefix_length => $plen, address => $addr );
}

sub as_bytes {
    my $self = shift;
    my $data = pack( 'C', $self->{prefix_length} ) . $self->{address};
    return pack( 'nn', $self->{code}, CORE::length( $data ) ) . $data;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_PD_EXCLUDE} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::PdExclude - PD Exclude option (code 67) — prefix to exclude from IA_PD

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::PdExclude;
  my $opt = Net::DHCPv6::Option::PdExclude->new(
      prefix_length => 48,
      address       => "\x20\x01\x0d\xb8\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
  );

=head1 DESCRIPTION

Carries a prefix that the requesting router must exclude from the
delegated prefix set.  See RFC 6603.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<prefix_length> and C<address> (the prefix
address bytes, with length derived from prefix_length).

=head2 prefix_length

Returns the prefix length in bits.

=head2 address

Returns the prefix address bytes.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
