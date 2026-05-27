#!/usr/bin/false
# ABSTRACT: Preference option (code 7) — 8-bit server preference value
# PODNAME: Net::DHCPv6::Option::Preference
package Net::DHCPv6::Option::Preference;
$Net::DHCPv6::Option::Preference::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'Preference requires value' unless defined $args{value};
    $args{code} = $OPTION_PREFERENCE;
    $args{data} = pack( 'C', $args{value} );
    my $self = $class->SUPER::new( %args );
    $self->{value} = $args{value};
    bless $self, $class;
}

sub value { shift->{value} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::BadOption->throw( message => 'Preference option must be exactly 1 byte' )
        if CORE::length( $data ) != 1;
    my $value = unpack( 'C', $data );
    return $class->new( value => $value );
}

sub as_bytes {
    my $self = shift;
    my $data = pack( 'C', $self->{value} );
    return pack( 'nn', $self->{code}, CORE::length( $data ) ) . $data;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_PREFERENCE} = __PACKAGE__;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::Preference - Preference option (code 7) — 8-bit server preference value

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $pref = Net::DHCPv6::Option::Preference->new(value => 255);

=head1 DESCRIPTION

Implements the Preference option (OPTION_PREFERENCE, code 7) per
RFC 8415 §21.8. An 8-bit unsigned integer indicating server preference.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>(value => $num)

Constructor. Requires an 8-bit value (0-255).

=item B<value>

Returns the preference value.

=back

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
