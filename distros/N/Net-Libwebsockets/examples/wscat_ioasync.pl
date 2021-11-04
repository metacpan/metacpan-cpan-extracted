#!/usr/bin/env perl

use strict;
use warnings;

use experimental 'signatures';

use IO::Async::Loop;
use IO::Async::Stream;

use Net::Libwebsockets::WebSocket::Client ();

use IO::SigGuard;

$| = 1;

my $url = $ARGV[0] or die "Need URL!\n";

{
    my $loop = IO::Async::Loop->new();

    $_->blocking(0) for (\*STDIN, \*STDOUT);

    Net::Libwebsockets::WebSocket::Client::connect(
        url => $url,
        event => [ 'IOAsync', $loop ],
        headers => [ 'X-Foo' => 'bar' ],
        on_ready => sub ($ws) {
            print STDERR "============ connected!!\n";

            # 1. Anything we receive from WS should go to STDOUT:

            my $out_stream = IO::Async::Stream->new(
                write_handle => \*STDOUT,
            );

            $loop->add($out_stream);

            $ws->on_text(
                sub ($msg) {
                    utf8::encode($msg);
                    $out_stream->write($msg);
                },
            );

            $ws->on_binary(
                sub ($msg) {
                    $out_stream->write($msg);
                },
            );

            # 2. Anything we receive from STDIN should go to WS:

            my @pauses;

            $loop->watch_io(
                handle => \*STDIN,
                on_read_ready => sub {
                    my $in = IO::SigGuard::sysread( \*STDIN, my $buf, 65536 );

                    if ($in) {
                        $ws->send_binary($buf);

                        #push @pauses, $ws->pause();
                        #my $t; $t = AnyEvent->timer(
                        #    after => 3,
                        #    cb => sub { shift @pauses; undef $t },
                        #);
                    }
                    else {
                        @pauses = ();

                        $loop->unwatch_io(
                            handle => \*STDIN,
                            on_read_ready => 1,
                        );

                        my $close_code;

                        if (!defined $in) {
                            warn "read(STDIN): $!";
                            $close_code = 1011;
                        }
                        else {
                            $close_code = 1000;
                        }

                        $ws->close($close_code);
                    }
                },
            );
        },
    )->finally( sub {
        $loop->stop();

        $loop->unwatch_io(
            handle => \*STDIN,
            on_read_ready => 1,
        );
    } );

    $loop->run();
}

print "And now our song is done.\n";
