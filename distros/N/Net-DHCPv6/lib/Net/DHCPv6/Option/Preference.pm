#!/bin/false
# ABSTRACT: Preference option (code 7) -- 8-bit server preference value
# PODNAME: Net::DHCPv6::Option::Preference
use strictures 2;

package Net::DHCPv6::Option::Preference;
$Net::DHCPv6::Option::Preference::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Carp qw( croak );
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
    return bless $self, $class;
}

sub value { return shift->{value} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::BadOption->throw( message => 'Preference option must be exactly 1 byte' )
        if CORE::length( $payload ) != 1;
    my $value = unpack( 'C', $payload );
    return $class->new( value => $value );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_PREFERENCE} = __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::Preference - Preference option (code 7) -- 8-bit server preference value

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $pref = Net::DHCPv6::Option::Preference->new(value => 255);  # 0-255, higher = more preferred

=head1 DESCRIPTION

Implements the Preference option (OPTION_PREFERENCE, code 7) per
RFC 8415 E<167>21.8. An 8-bit unsigned integer (0-255) where a higher
value indicates the server is more preferred by the client.

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
