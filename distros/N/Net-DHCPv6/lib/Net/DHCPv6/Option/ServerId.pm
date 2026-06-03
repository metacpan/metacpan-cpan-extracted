#!/bin/false
# ABSTRACT: Server Identifier option (code 2)
# PODNAME: Net::DHCPv6::Option::ServerId
use strictures 2;

package Net::DHCPv6::Option::ServerId;
$Net::DHCPv6::Option::ServerId::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Net::DHCPv6::DUID       ();
use Carp                    qw( croak );
use Net::DHCPv6::Constants  qw(
    $OPTION_SERVERID
);
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'ServerId requires a duid' unless $args{duid};
    $args{code} = $OPTION_SERVERID;
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

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_SERVERID} = __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::ServerId - Server Identifier option (code 2)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $sid = Net::DHCPv6::Option::ServerId->new(duid => $duid);
  print $sid->duid->duid_type;

=head1 DESCRIPTION

Implements the Server Identifier option (OPTION_SERVERID, code 2)
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

L<Net::DHCPv6::Option>, L<Net::DHCPv6::Option::ClientId>, L<Net::DHCPv6::DUID>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
