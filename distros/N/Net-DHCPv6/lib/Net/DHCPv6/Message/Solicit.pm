#!/usr/bin/false
# ABSTRACT: Solicit message (type 1)
# PODNAME: Net::DHCPv6::Message::Solicit
package Net::DHCPv6::Message::Solicit;
$Net::DHCPv6::Message::Solicit::VERSION = '0.001';
use strictures 2;
use Net::DHCPv6::Constants;
use parent 'Net::DHCPv6::Packet';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    $args{msg_type} = $SOLICIT;
    $class->SUPER::new( %args );
}

$Net::DHCPv6::Packet::MESSAGE_CLASS{$SOLICIT} = __PACKAGE__;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Message::Solicit - Solicit message (type 1)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Net::DHCPv6;

    my ($msg, $err) = Net::DHCPv6->decode_with_error($bytes);

=head1 DESCRIPTION

DHCPv6 Solicit message (type 1). Clients send Solicit to locate
servers. See L<Net::DHCPv6::Packet> for available methods.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=for Pod::Coverage new

=head1 SEE ALSO

L<Net::DHCPv6::Packet>, L<Net::DHCPv6::Message::Advertise>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
