#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Try::Tiny;

use HTTP::Request ();
use IO::Socket::INET ();
use IO::Select ();

use IO::Framed ();

use FindBin;
use lib "$FindBin::Bin/../lib";

use lib "$FindBin::Bin/lib";
use NWDemo ();

use Net::WebSocket::Endpoint::Server ();
use Net::WebSocket::Parser ();
use Net::WebSocket::Streamer::Server ();

my $host_port = $ARGV[0] || die "Need host:port or port!\n";

if (index($host_port, ':') == -1) {
    substr( $host_port, 0, 0 ) = '127.0.0.1:';
}

my ($host, $port) = split m<:>, $host_port;

my $server = IO::Socket::INET->new(
    LocalHost => $host,
    LocalPort => $port,
    ReuseAddr => 1,
    Listen => 2,
);

#This is a “lazy” example. A more robust, production-level
#solution would not need to fork() unless there were privilege
#drops or some such that necessitate separate processes per session.

#For an example of a non-forking server in Perl, look at Net::WAMP’s
#router example.

while ( my $sock = $server->accept() ) {
    fork and next;

    $sock->autoflush(1);

    NWDemo::handshake_as_server($sock);

    NWDemo::set_signal_handlers_for_server($sock);

    my $framed_obj = IO::Framed->new($sock);

    my $parser = Net::WebSocket::Parser->new($framed_obj);

    $sock->blocking(0);

    my $s = IO::Select->new($sock);

    my $sent_ping;

    my $ept = Net::WebSocket::Endpoint::Server->new(
        parser => $parser,
        out => $framed_obj,
    );
    $ept->do_not_die_on_close();

    my $streamer = Net::WebSocket::Streamer::Server->new('text');

    my $cur_number = 0;

    while (!$ept->is_closed()) {
        my ( $rdrs_ar, undef, $errs_ar ) = IO::Select->select( $s, undef, $s, 0 );

        my $is_final = ($cur_number == 2);

        my $method = $is_final ? 'create_final' : 'create_chunk';

        $framed_obj->write(
            $streamer->$method($cur_number)->to_bytes(),
        );

        $cur_number++;
        $cur_number %= 3;

        if ($is_final) {
            $streamer = Net::WebSocket::Streamer::Server->new('text');
        }

        if ($errs_ar && @$errs_ar) {
            $s->remove($sock);
            last;
        }

        if ( $rdrs_ar && @$rdrs_ar ) {
            $ept->get_next_message();   #we don’t care what it is
        }

        sleep 1;
    }

    exit;
}
