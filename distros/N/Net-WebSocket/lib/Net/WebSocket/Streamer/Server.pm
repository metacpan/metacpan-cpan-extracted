package Net::WebSocket::Streamer::Server;

=encoding utf-8

=head1 NAME

Net::WebSocket::Streamer::Server

=head1 SYNOPSIS

    open my $rfh, '<', '/some/big/file';

    my $stream = Net::WebSocket::Streamer::Server->new('binary');

    while ( read $rfh, my $buf, 32768 ) {
        my $chunk = $stream->create_chunk($buf);
        print {$socket} $chunk->to_bytes();
    }

    print {$socket} $stream->create_final(q<>);

=head1 DESCRIPTION

The SYNOPSIS pretty well shows it: you can use this module
(or its twin, C<Net::WebSocket::Streamer::Client>) to send a WebSocket
message without buffering the full contents.

=head1 EXTENSION SUPPORT

You can subclass this module to support initial frame types other than
text or binary. (Subsequent frames are always continuations.)

You can also set the reserved bytes manually on the individual frames
to support extensions that involve those bits.

=cut

use strict;
use warnings;

use parent qw(
    Net::WebSocket::Streamer
    Net::WebSocket::Masker::Server
);

1;
