#!/bin/false
# ABSTRACT: IA Address option (code 5) -- address + lifetimes + sub-options
# PODNAME: Net::DHCPv6::Option::IAAddr
use strictures 2;

package Net::DHCPv6::Option::IAAddr;
$Net::DHCPv6::Option::IAAddr::VERSION = '0.003';
use Carp                   qw( croak );
use Net::DHCPv6::Constants qw(
    $IPV6_ADDR_LEN $OPTION_IAADDR
);
use Net::DHCPv6::OptionList   ();
use Net::DHCPv6::X::Truncated ();
use parent 'Net::DHCPv6::Option';
use namespace::clean;

my $IA_ADDR_HDR       = 24;    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
my $LIFETIME_WIRE_LEN = 8;     ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

sub new {
    my ( $class, %args ) = @_;
    my $addr = $class->_pick_addr( \%args, 'address' );
    croak 'IAAddr requires address' unless $addr && CORE::length( $addr ) == $IPV6_ADDR_LEN;
    $args{code}               = $OPTION_IAADDR;
    $args{preferred_lifetime} = $args{preferred_lifetime} // 0;
    $args{valid_lifetime}     = $args{valid_lifetime}     // 0;
    $args{options}            = $args{options}            // Net::DHCPv6::OptionList->new;
    my $payload =
        $addr . pack( 'N N', $args{preferred_lifetime}, $args{valid_lifetime} ) . $args{options}->as_bytes;
    $args{data} = $payload;
    my $self = $class->SUPER::new( %args );
    $self->{address}            = $addr;
    $self->{preferred_lifetime} = $args{preferred_lifetime};
    $self->{valid_lifetime}     = $args{valid_lifetime};
    $self->{options}            = $args{options};
    return bless $self, $class;
}

sub address_raw { return shift->{address} }

sub address {
    my $self = shift;
    return $self->_format_ipv6( $self->{address} );
}
sub preferred_lifetime { return shift->{preferred_lifetime} }
sub valid_lifetime     { return shift->{valid_lifetime} }
sub options            { return shift->{options} }

sub add_option {
    my ( $self, $option ) = @_;
    return $self->{options}->add_option( $option );
}

sub get_option {
    my ( $self, $code ) = @_;
    return $self->{options}->get_option( $code );
}

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated IAAddr option' )
        if CORE::length( $payload ) < $IA_ADDR_HDR;
    my $addr = substr( $payload, 0, $IPV6_ADDR_LEN );
    my ( $pl, $vl ) = unpack( 'N N', substr( $payload, $IPV6_ADDR_LEN, $LIFETIME_WIRE_LEN ) );
    my $opt_data = substr( $payload, $IA_ADDR_HDR );
    my $opts     = Net::DHCPv6::OptionList->from_bytes( $opt_data );
    return $class->new(
        address_raw        => $addr,
        preferred_lifetime => $pl,
        valid_lifetime     => $vl,
        options            => $opts,
    );
}

sub as_bytes {
    my $self = shift;
    my $payload =
          $self->{address}
        . pack( 'N N', $self->{preferred_lifetime}, $self->{valid_lifetime} )
        . $self->{options}->as_bytes;
    return pack( 'nn', $self->{code}, CORE::length( $payload ) ) . $payload;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_IAADDR} = __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::IAAddr - IA Address option (code 5) -- address + lifetimes + sub-options

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  # Text form (auto-resolved to wire bytes)
  my $iaaddr = Net::DHCPv6::Option::IAAddr->new(
      address            => '2001:db8::1',
      preferred_lifetime => 7_200,
      valid_lifetime     => 86_400,
  );
  print $iaaddr->address;             # '2001:db8::1'
  print $iaaddr->address_raw;         # 16-byte wire-format bytes

  # Raw bytes
  use Socket qw(inet_pton AF_INET6);
  my $iaaddr2 = Net::DHCPv6::Option::IAAddr->new(
      address_raw        => inet_pton( AF_INET6, '2001:db8::1' ),
      preferred_lifetime => 7_200,
      valid_lifetime     => 86_400,
  );

=head1 DESCRIPTION

Implements the IAADDR option (OPTION_IAADDR, code 5) per RFC 8415 E<167>21.6.
Contains a 16-byte IPv6 address, preferred lifetime, valid lifetime,
and sub-options.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>(address => $text | address_raw => $bytes16, preferred_lifetime => $num, valid_lifetime => $num, options => $optionlist)

Constructor. Requires either C<address> (IPv6 text) or C<address_raw> (16 raw
bytes). C<preferred_lifetime> and C<valid_lifetime> default to 0. C<options>
defaults to an empty L<Net::DHCPv6::OptionList>.

=item B<address>

Returns the IPv6 address as a text string.

=item B<address_raw>

Returns the 16-byte wire-format address.

=item B<preferred_lifetime>

Returns preferred lifetime in seconds.

=item B<valid_lifetime>

Returns valid lifetime in seconds.

=item B<options>

Returns the internal L<Net::DHCPv6::OptionList> of sub-options.

=item B<add_option>($option)

Add a sub-option.

=item B<get_option>($code)

Retrieve the first sub-option with the given code.

=back

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::Option::IANA>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
