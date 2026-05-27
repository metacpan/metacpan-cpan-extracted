#!/usr/bin/false
# ABSTRACT: Information Refresh Time option (code 32) — 32-bit refresh duration
# PODNAME: Net::DHCPv6::Option::InfoRefreshTime
package Net::DHCPv6::Option::InfoRefreshTime;
$Net::DHCPv6::Option::InfoRefreshTime::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'InfoRefreshTime requires value' unless defined $args{value};
    $args{code} = $OPTION_INFORMATION_REFRESH_TIME;
    $args{data} = pack( 'N', $args{value} );
    my $self = $class->SUPER::new( %args );
    $self->{value} = $args{value};
    bless $self, $class;
}

sub value { shift->{value} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::BadOption->throw( message => 'InfoRefreshTime must be exactly 4 bytes' )
        if CORE::length( $data ) != 4;
    my $value = unpack( 'N', $data );
    return $class->new( value => $value );
}

sub as_bytes {
    my $self = shift;
    my $data = pack( 'N', $self->{value} );
    return pack( 'nn', $self->{code}, CORE::length( $data ) ) . $data;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_INFORMATION_REFRESH_TIME} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::InfoRefreshTime - Information Refresh Time option (code 32) — 32-bit refresh duration

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::InfoRefreshTime;
  my $opt = Net::DHCPv6::Option::InfoRefreshTime->new(value => 86400);

=head1 DESCRIPTION

Carries the minimum time (in seconds) that a client should wait before
refreshing information received from the server.  Required for
Information-Request messages.  See RFC 8415 §21.24.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<value>, a 32-bit unsigned integer.

=head2 value

Returns the refresh time in seconds.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
