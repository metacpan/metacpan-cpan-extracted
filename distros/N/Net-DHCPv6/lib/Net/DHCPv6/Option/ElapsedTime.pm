#!/bin/false
# ABSTRACT: Elapsed Time option (code 8) -- 16-bit centiseconds
# PODNAME: Net::DHCPv6::Option::ElapsedTime
use strictures 2;

package Net::DHCPv6::Option::ElapsedTime;
$Net::DHCPv6::Option::ElapsedTime::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Carp qw( croak );
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'ElapsedTime requires centiseconds' unless defined $args{centiseconds};
    $args{code} = $OPTION_ELAPSED_TIME;
    $args{data} = pack( 'n', $args{centiseconds} );
    my $self = $class->SUPER::new( %args );
    $self->{centiseconds} = $args{centiseconds};
    return bless $self, $class;
}

sub centiseconds { return shift->{centiseconds} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::BadOption->throw( message => 'ElapsedTime option must be exactly 2 bytes' )
        if CORE::length( $payload ) != 2;
    my $cs = unpack( 'n', $payload );
    return $class->new( centiseconds => $cs );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_ELAPSED_TIME} = __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::ElapsedTime - Elapsed Time option (code 8) -- 16-bit centiseconds

=head1 VERSION

version 0.002

=head1 SYNOPSIS

   my $et = Net::DHCPv6::Option::ElapsedTime->new(centiseconds => 1_000);

=head1 DESCRIPTION

Implements the Elapsed Time option (OPTION_ELAPSED_TIME, code 8) per
RFC 8415 E<167>21.9. A 16-bit unsigned integer representing hundredths of
a second elapsed since the client began the transaction.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>(centiseconds => $num)

Constructor. Requires a 16-bit value in centiseconds (0-65_535).

=item B<centiseconds>

Returns the elapsed time in centiseconds.

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
