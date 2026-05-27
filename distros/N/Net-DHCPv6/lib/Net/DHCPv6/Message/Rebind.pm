#!/usr/bin/false
# ABSTRACT: Rebind message (type 6)
# PODNAME: Net::DHCPv6::Message::Rebind
package Net::DHCPv6::Message::Rebind;
$Net::DHCPv6::Message::Rebind::VERSION = '0.001';
use strictures 2;
use Net::DHCPv6::Constants;
use parent 'Net::DHCPv6::Packet';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    $args{msg_type} = $REBIND;
    $class->SUPER::new( %args );
}

$Net::DHCPv6::Packet::MESSAGE_CLASS{$REBIND} = __PACKAGE__;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Message::Rebind - Rebind message (type 6)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Net::DHCPv6;

    my ($msg, $err) = Net::DHCPv6->decode_with_error($bytes);

=head1 DESCRIPTION

DHCPv6 Rebind message (type 6). Clients send Rebind when a Renew
to the original server receives no response. See L<Net::DHCPv6::Packet>
for available methods.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=for Pod::Coverage new

=head1 SEE ALSO

L<Net::DHCPv6::Packet>, RFC 8415 §18.6

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
