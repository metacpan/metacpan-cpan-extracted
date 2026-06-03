#!/bin/false
# ABSTRACT: PD Exclude option (code 67) -- prefix to exclude from IA_PD
# PODNAME: Net::DHCPv6::Option::PdExclude
use strictures 2;

package Net::DHCPv6::Option::PdExclude;
$Net::DHCPv6::Option::PdExclude::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Carp                    qw( croak );
use Net::DHCPv6::Constants  qw(
    $OPTION_PD_EXCLUDE
);
use Net::DHCPv6::X::Truncated ();
use Net::DHCPv6::X::BadOption ();
use parent 'Net::DHCPv6::Option';
use namespace::clean;

my $BYTE_ALIGN_MASK = 7;    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
my $BYTE_SHIFT      = 3;    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

sub new {
    my ( $class, %args ) = @_;
    croak 'PdExclude requires prefix_length' unless defined $args{prefix_length};
    my $addr = $class->_pick_addr( \%args, 'address' );
    croak 'PdExclude requires address' unless defined $addr;
    my $addr_len = ( $args{prefix_length} + $BYTE_ALIGN_MASK ) >> $BYTE_SHIFT;
    $addr       = substr( $addr, 0, $addr_len );
    $args{code} = $OPTION_PD_EXCLUDE;
    $args{data} = pack( 'C', $args{prefix_length} ) . $addr;
    my $self = $class->SUPER::new( %args );
    $self->{prefix_length} = $args{prefix_length};
    $self->{address}       = $addr;
    return bless $self, $class;
}

sub prefix_length { return shift->{prefix_length} }
sub address_raw   { return shift->{address} }
sub address       { return shift->{address} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated PdExclude option' )
        if CORE::length( $payload ) < 1;
    my $plen     = unpack( 'C', substr( $payload, 0, 1 ) );
    my $addr_len = ( $plen + $BYTE_ALIGN_MASK ) >> $BYTE_SHIFT;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated PdExclude address' )
        if 1 + $addr_len > CORE::length( $payload );
    my $addr = substr( $payload, 1, $addr_len );
    return $class->new( prefix_length => $plen, address_raw => $addr );
}

sub as_bytes {
    my $self    = shift;
    my $payload = pack( 'C', $self->{prefix_length} ) . $self->{address};
    return pack( 'nn', $self->{code}, CORE::length( $payload ) ) . $payload;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_PD_EXCLUDE} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::PdExclude - PD Exclude option (code 67) -- prefix to exclude from IA_PD

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  # Text form (auto-resolved, truncated to prefix length)
  my $opt = Net::DHCPv6::Option::PdExclude->new(
      prefix_length => 48,
      address       => '2001:db8::',
  );

  # Raw bytes (already truncated to prefix length)
  use Socket qw(inet_pton AF_INET6);
  my $opt2 = Net::DHCPv6::Option::PdExclude->new(
      prefix_length => 48,
      address_raw   => inet_pton( AF_INET6, '2001:db8::' ),
  );

=head1 DESCRIPTION

Carries a prefix that the requesting router must exclude from the
delegated prefix set.  See RFC 6603.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<prefix_length> and either C<address> (IPv6 text)
or C<address_raw> (prefix bytes).  Text addresses are truncated to
ceil(prefix_length/8) bytes.

=head2 address

Returns the prefix address bytes (variable-length, not full 16 bytes).

=head2 address_raw

Returns the prefix address bytes (same as C<address>).

=head2 prefix_length

Returns the prefix length in bits.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
