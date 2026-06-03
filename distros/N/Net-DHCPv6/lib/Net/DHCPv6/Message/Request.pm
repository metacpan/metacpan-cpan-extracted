#!/bin/false
# ABSTRACT: Request message (type 3)
# PODNAME: Net::DHCPv6::Message::Request
use strictures 2;

package Net::DHCPv6::Message::Request;
$Net::DHCPv6::Message::Request::VERSION = '0.003';
use Net::DHCPv6::Packet    ();
use Net::DHCPv6::Constants qw(
    $REQUEST
);
use parent 'Net::DHCPv6::Packet';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    $args{msg_type} = $REQUEST;
    return $class->SUPER::new( %args );
}

$Net::DHCPv6::Packet::MESSAGE_CLASS{$REQUEST} = __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Message::Request - Request message (type 3)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Net::DHCPv6;

    my ($msg, $err) = Net::DHCPv6->decode_with_error($bytes);

=head1 DESCRIPTION

DHCPv6 Request message (type 3). Clients send Request after
selecting a server. See L<Net::DHCPv6::Packet> for available
methods.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=for Pod::Coverage new

=head1 SEE ALSO

L<Net::DHCPv6::Packet>, L<Net::DHCPv6::Message::Reply>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
