#!/usr/bin/false
# ABSTRACT: IA Address option (code 5) — address + lifetimes + sub-options
# PODNAME: Net::DHCPv6::Option::IAAddr
package Net::DHCPv6::Option::IAAddr;
$Net::DHCPv6::Option::IAAddr::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'IAAddr requires address' unless $args{address};
    $args{code}               = $OPTION_IAADDR;
    $args{preferred_lifetime} = $args{preferred_lifetime} // 0;
    $args{valid_lifetime}     = $args{valid_lifetime}     // 0;
    $args{options}            = $args{options}            // Net::DHCPv6::OptionList->new;
    my $data =
        $args{address} . pack( 'N N', $args{preferred_lifetime}, $args{valid_lifetime} ) . $args{options}->as_bytes;
    $args{data} = $data;
    my $self = $class->SUPER::new( %args );
    $self->{address}            = $args{address};
    $self->{preferred_lifetime} = $args{preferred_lifetime};
    $self->{valid_lifetime}     = $args{valid_lifetime};
    $self->{options}            = $args{options};
    bless $self, $class;
}

sub address            { shift->{address} }
sub preferred_lifetime { shift->{preferred_lifetime} }
sub valid_lifetime     { shift->{valid_lifetime} }
sub options            { shift->{options} }

sub add_option {
    my ( $self, $option ) = @_;
    $self->{options}->add_option( $option );
}

sub get_option {
    my ( $self, $code ) = @_;
    return $self->{options}->get_option( $code );
}

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated IAAddr option' )
        if CORE::length( $data ) < 24;
    my $addr = substr( $data, 0, 16 );
    my ( $pl, $vl ) = unpack( 'N N', substr( $data, 16, 8 ) );
    my $opt_data = substr( $data, 24 );
    my $opts     = Net::DHCPv6::OptionList->from_bytes( $opt_data );
    return $class->new(
        address            => $addr,
        preferred_lifetime => $pl,
        valid_lifetime     => $vl,
        options            => $opts,
    );
}

sub as_bytes {
    my $self = shift;
    my $data =
          $self->{address}
        . pack( 'N N', $self->{preferred_lifetime}, $self->{valid_lifetime} )
        . $self->{options}->as_bytes;
    return pack( 'nn', $self->{code}, CORE::length( $data ) ) . $data;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_IAADDR} = __PACKAGE__;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::IAAddr - IA Address option (code 5) — address + lifetimes + sub-options

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $iaaddr = Net::DHCPv6::Option::IAAddr->new(
      address            => "\x20\x01\x0d\xb8\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01",
      preferred_lifetime => 7200,
      valid_lifetime     => 86400,
  );

=head1 DESCRIPTION

Implements the IAADDR option (OPTION_IAADDR, code 5) per RFC 8415 §21.6.
Contains a 16-byte IPv6 address, preferred lifetime, valid lifetime,
and sub-options.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>(address => $bytes16, preferred_lifetime => $num, valid_lifetime => $num, options => $optionlist)

Constructor. C<address> is required (16 raw bytes). C<preferred_lifetime>
and C<valid_lifetime> default to 0. C<options> defaults to an empty
L<Net::DHCPv6::OptionList>.

=item B<address>

Returns the 16-byte IPv6 address.

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
