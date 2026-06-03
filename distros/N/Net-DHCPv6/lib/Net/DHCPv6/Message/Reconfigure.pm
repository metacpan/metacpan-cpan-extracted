#!/bin/false
# ABSTRACT: Reconfigure message (type 10)
# PODNAME: Net::DHCPv6::Message::Reconfigure
use strictures 2;

package Net::DHCPv6::Message::Reconfigure;
$Net::DHCPv6::Message::Reconfigure::VERSION = '0.003';
use Net::DHCPv6::Packet    ();
use Net::DHCPv6::Constants qw(
    $RECONFIGURE
);
use parent 'Net::DHCPv6::Packet';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    $args{msg_type} = $RECONFIGURE;
    return $class->SUPER::new( %args );
}

$Net::DHCPv6::Packet::MESSAGE_CLASS{$RECONFIGURE} = __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Message::Reconfigure - Reconfigure message (type 10)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Net::DHCPv6;

    my ($msg, $err) = Net::DHCPv6->decode_with_error($bytes);

=head1 DESCRIPTION

DHCPv6 Reconfigure message (type 10). Servers send Reconfigure to
trigger a client to initiate Solicit or Information-Request. See
L<Net::DHCPv6::Packet> for available methods.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=for Pod::Coverage new

=head1 SEE ALSO

L<Net::DHCPv6::Packet>, RFC 8415 E<167>18.12

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
