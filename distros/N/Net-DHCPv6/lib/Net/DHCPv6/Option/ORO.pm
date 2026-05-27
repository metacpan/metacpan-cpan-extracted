#!/usr/bin/false
# ABSTRACT: Option Request option (code 6)
# PODNAME: Net::DHCPv6::Option::ORO
package Net::DHCPv6::Option::ORO;
$Net::DHCPv6::Option::ORO::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'ORO requires requested_options (arrayref)' unless $args{requested_options};
    $args{code} = $OPTION_ORO;
    $args{data} = pack( 'n*', @{ $args{requested_options} } );
    my $self = $class->SUPER::new( %args );
    $self->{requested_options} = $args{requested_options};
    bless $self, $class;
}

sub requested_options { shift->{requested_options} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::BadOption->throw( message => 'ORO data must have even length' )
        if CORE::length( $data ) % 2 != 0;
    my @codes = unpack( 'n*', $data );
    return $class->new( requested_options => \@codes );
}

sub as_bytes {
    my $self = shift;
    my $data = pack( 'n*', @{ $self->{requested_options} } );
    return pack( 'nn', $self->{code}, CORE::length( $data ) ) . $data;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_ORO} = __PACKAGE__;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::ORO - Option Request option (code 6)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $oro = Net::DHCPv6::Option::ORO->new(requested_options => [23, 24]);

=head1 DESCRIPTION

Implements the ORO option (OPTION_ORO, code 6) per RFC 8415 §21.7.
Lists option codes the client requests the server to include in
the reply.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>(requested_options => \@codes)

Constructor. Requires an arrayref of numeric option codes.

=item B<requested_options>

Returns the arrayref of requested option codes.

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
