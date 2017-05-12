package Net::WebSocket::Handshake::Server;

=encoding utf-8

=head1 NAME

Net::WebSocket::Handshake::Server

=head1 SYNOPSIS

    my $hsk = Net::WebSocket::Handshake::Server->new(

        #required, base 64
        key => '..',

        #optional
        subprotocols => [ 'echo', 'haha' ],
    );

    #Note the need to conclude the header text manually.
    #This is by design, so you can add additional headers.
    my $resp_hdr = $hsk->create_header_text() . "\x0d\x0a";

    my $b64 = $hsk->get_accept();

=head1 DESCRIPTION

This class implements WebSocket handshake logic for a server.

Because Net::WebSocket tries to be agnostic about how you parse your HTTP
headers, this class doesn’t do a whole lot for you: it’ll give you the
C<Sec-WebSocket-Accept> header value given a base64
C<Sec-WebSocket-Key> (i.e., from the client), and it’ll give you
a “basic” response header text.

B<NOTE:> C<create_header_text()> does NOT provide the extra trailing
CRLF to conclude the HTTP headers. This allows you to add additional
headers beyond what this class gives you.

=cut

use strict;
use warnings;

use parent qw( Net::WebSocket::Handshake::Base );

use Call::Context ();
use Digest::SHA ();

use Net::WebSocket::X ();

sub new {
    my ($class, %opts) = @_;

    if (!$opts{'key'}) {
        die Net::WebSocket::X->create('BadArg', key => $opts{'key'});
    }

    return bless \%opts, $class;
}

*get_accept = __PACKAGE__->can('_get_accept');

sub _create_header_lines {
    my ($self) = @_;

    Call::Context::must_be_list();

    return (
        'HTTP/1.1 101 Switching Protocols',

        #For now let’s assume no one wants any other Upgrade:
        #or Connection: values than the ones WebSocket requires.
        'Upgrade: websocket',
        'Connection: Upgrade',

        'Sec-WebSocket-Accept: ' . $self->get_accept(),

        $self->_encode_subprotocols(),

        #'Sec-WebSocket-Extensions: ',
    );
}

1;
