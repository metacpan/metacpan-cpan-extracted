package Net::OBEX::Packet::Request::Abort;

use strict;
use warnings;
our $VERSION = '1.001001'; # VERSION
use Carp;

use base 'Net::OBEX::Packet::Request::Base';

sub make {
    my $self = shift;
    my $headers = join '', @{ $self->headers };

    my $packet = "\xFF" . pack( 'n', 3 + length $headers) . $headers;

    return $self->raw($packet);
}

1;

__END__

=encoding utf8

=for stopwords AnnoCPAN RT

=head1 NAME

Net::OBEX::Packet::Request::Abort - create OBEX protocol C<Abort> request packets.

=head1 SYNOPSIS

    use Net::OBEX::Packet::Request::Abort;

    my $aborts = Net::OBEX::Packet::Request::Abort->new(
        headers => [ $bunch, $of, $raw, $headers ],
    );

    my $abort_packet = $aborts->make;

    $aborts->headers([]); # reset headers.

    my $abort_packet2 = $aborts->make;

=head1 DESCRIPTION

B<WARNING!!! This module is in an early alpha stage. It is recommended
that you use it only for testing.>

The module provides means to create OBEX protocol C<Abort>
(C<0xFF>) packets.
It is used internally by L<Net::OBEX::Packet::Request> module and you
probably want to use that instead.

=head1 CONSTRUCTOR

=head2 new

    $pack = Net::OBEX::Packet::Request::Abort->new;

    $pack2 = Net::OBEX::Packet::Request::Abort->new(
        headers => [ $some, $raw, $headers ]
    );

Returns a Net::OBEX::Packet::Request::Abort object, takes one optional
C<headers> argument value of which is an arrayref of raw OBEX
packet headers. See L<Net::OBEX::Packet::Headers> if you want to create
those.

=head1 METHODS

=head2 make

    my $raw_packet = $pack->make;

Takes no arguments, returns a raw OBEX packet ready to go down the wire.

=head2 raw

    my $raw_packet = $pack->raw;

Takes no arguments, must be called after C<make()> call, returns the
raw OBEX packet which was made with last C<make()> (i.e. the last
return value of C<make()>).

=head2 headers

    my $headers_ref = $pack->headers;

    $pack->headers( [ $bunch, $of, $raw, $headers ] );

Returns an arrayref of currently set OBEX packet
headers. Takes one optional argument which is an arrayref, elements of
which are raw OBEX
packet headers. See L<Net::OBEX::Packet::Headers> if you want to create
those. If you want a packet with no headers use an empty arrayref
as an argument.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/Net-OBEX>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/Net-OBEX/issues>

If you can't access GitHub, you can email your request
to C<bug-Net-OBEX at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut