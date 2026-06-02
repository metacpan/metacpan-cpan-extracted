#!/bin/false
# ABSTRACT: Client Identifier option (code 1)
# PODNAME: Net::DHCPv6::Option::ClientId
use strictures 2;

package Net::DHCPv6::Option::ClientId;
$Net::DHCPv6::Option::ClientId::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Net::DHCPv6::DUID;
use Carp qw( croak );
use Net::DHCPv6::Constants;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'ClientId requires a duid' unless $args{duid};
    $args{code} = $OPTION_CLIENTID;
    $args{data} = $args{duid}->as_bytes;
    my $self = $class->SUPER::new( %args );
    $self->{duid} = $args{duid};
    return bless $self, $class;
}

sub duid { return shift->{duid} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    my $duid = Net::DHCPv6::DUID->from_bytes( $payload );
    return $class->new( duid => $duid );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_CLIENTID} = __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::ClientId - Client Identifier option (code 1)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $cid = Net::DHCPv6::Option::ClientId->new(duid => $duid);
  print $cid->duid->duid_type;

=head1 DESCRIPTION

Implements the Client Identifier option (OPTION_CLIENTID, code 1)
per RFC 8415 E<167>21.2. The option data contains a single DUID.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>(duid => $duid)

Constructor. Requires a L<Net::DHCPv6::DUID> object.

=item B<duid>

Returns the contained L<Net::DHCPv6::DUID> object.

=back

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::Option::ServerId>, L<Net::DHCPv6::DUID>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
