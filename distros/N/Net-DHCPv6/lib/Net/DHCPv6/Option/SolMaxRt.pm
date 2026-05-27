#!/usr/bin/false
# ABSTRACT: SOL_MAX_RT option (code 10) — maximum solicit retransmission duration (32-bit)
# PODNAME: Net::DHCPv6::Option::SolMaxRt
package Net::DHCPv6::Option::SolMaxRt;
$Net::DHCPv6::Option::SolMaxRt::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'SolMaxRt requires value' unless defined $args{value};
    $args{code} = $OPTION_SOL_MAX_RT;
    $args{data} = pack( 'N', $args{value} );
    my $self = $class->SUPER::new( %args );
    $self->{value} = $args{value};
    bless $self, $class;
}

sub value { shift->{value} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::BadOption->throw( message => 'SolMaxRt must be exactly 4 bytes' )
        if CORE::length( $data ) != 4;
    my $value = unpack( 'N', $data );
    return $class->new( value => $value );
}

sub as_bytes {
    my $self = shift;
    my $data = pack( 'N', $self->{value} );
    return pack( 'nn', $self->{code}, CORE::length( $data ) ) . $data;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_SOL_MAX_RT} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::SolMaxRt - SOL_MAX_RT option (code 10) — maximum solicit retransmission duration (32-bit)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::SolMaxRt;
  my $opt = Net::DHCPv6::Option::SolMaxRt->new(value => 3600);

=head1 DESCRIPTION

Carries the maximum retransmission duration (in seconds) for Solicit
messages.  See RFC 8415 §21.10.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<value>, a 32-bit unsigned integer.

=head2 value

Returns the maximum retransmission duration in seconds.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
