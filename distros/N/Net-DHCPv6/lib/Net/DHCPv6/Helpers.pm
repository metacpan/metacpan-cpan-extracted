#!/bin/false
# ABSTRACT: Internal helper methods for IPv6 address resolution
# PODNAME: Net::DHCPv6::Helpers
use strictures 2;

package Net::DHCPv6::Helpers;
$Net::DHCPv6::Helpers::VERSION = '0.002';
use Carp      qw( croak );
use Ref::Util qw( is_plain_arrayref );
use Socket    qw( AF_INET6 inet_ntop inet_pton );
use namespace::clean;

sub _resolve_ipv6 {
    my ( $class, $arg ) = @_;
    return unless defined $arg;
    if ( CORE::length( $arg ) == 16 ) {

        # If it looks like IPv6 text (hex digits + colons), parse it
        if ( $arg =~ m/^[0-9a-fA-F:]+$/ && $arg =~ m/:/ ) {
            my $bytes = inet_pton( AF_INET6, $arg );
            return $bytes if defined $bytes;
        }
        return $arg;
    }
    croak( "Invalid IPv6 address: $arg" ) unless $arg =~ m/:/;
    my $bytes = inet_pton( AF_INET6, $arg );
    croak( "Invalid IPv6 address: $arg" ) unless defined $bytes;
    return $bytes;
}

sub _format_ipv6 {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my ( $self, $bytes ) = @_;
    return unless defined $bytes;
    return inet_ntop( AF_INET6, $bytes );
}

sub _pick_addr {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my ( $class, $args, $field ) = @_;
    my $key = "${field}_raw";
    return $args->{$key} if exists $args->{$key};
    return unless defined $args->{$field};
    return $class->_resolve_ipv6( $args->{$field} );
}

sub _pick_addrs {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my ( $class, $args, $field ) = @_;
    my $key = "${field}_raw";
    return $args->{$key} if exists $args->{$key};
    return unless defined $args->{$field};
    my $list =
        is_plain_arrayref( $args->{$field} )
        ? $args->{$field}
        : [ $args->{$field} ];
    return [ map { $class->_resolve_ipv6( $_ ) } @{$list} ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Helpers - Internal helper methods for IPv6 address resolution

=head1 VERSION

version 0.002

=head1 DESCRIPTION

Internal helper methods shared by L<Net::DHCPv6::Option> and
L<Net::DHCPv6::Packet::Relay> for IPv6 address parsing and formatting.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<_resolve_ipv6>($arg)

If C<$arg> is exactly 16 octets, treat as wire format and return
unmodified. Otherwise, if it contains C<:>, parse as text and convert to
16-byte wire format via C<inet_pton>. Otherwise croak.

=item B<_format_ipv6>($bytes)

Convert 16-byte wire-format address to text via C<inet_ntop>.

=item B<_pick_addr>( \%args, $field )

Helper for constructor argument processing. If C<$field_raw> exists in
C<\%args>, return it directly. Else if C<$field> exists, pass it through
L</_resolve_ipv6>. Otherwise return C<undef>.

=item B<_pick_addrs>( \%args, $field )

Like L</_pick_addr> but for multiple addresses. Accepts an arrayref or a
single scalar value; a scalar is wrapped in an arrayref automatically.

=back

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::Packet::Relay>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
