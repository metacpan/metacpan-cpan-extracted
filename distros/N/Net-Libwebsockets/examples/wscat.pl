#!/usr/bin/env perl

use strict;
use warnings;

use experimental 'signatures';

#use AnyEvent::Loop;
use AnyEvent;
use AnyEvent::Handle;

use Promise::XS;

$Promise::XS::DETECT_MEMORY_LEAKS = 1;

use Net::Libwebsockets::WebSocket::Client ();
use Net::Libwebsockets::Logger ();

use IO::SigGuard;

my $url = $ARGV[0] or die "Need URL!\n";

{
    my $cv = AE::cv();

    $_->blocking(0) for (\*STDIN, \*STDOUT);

    my $in_w;

    Net::Libwebsockets::WebSocket::Client::connect(
        url => $url,
        event => 'AnyEvent',
        headers => [ 'X-Foo' => 'bar' ],
        logger => Net::Libwebsockets::Logger->new(
            #level => 0b11111111111,
            level => Net::Libwebsockets::LLL_ERR | Net::Libwebsockets::LLL_WARN,
            callback => sub {
                print STDERR ">> $_[0] $_[1]\n";
            },
        ),
        on_ready => sub ($ws) {

            # 1. Anything we receive from WS should go to STDOUT:

            my $out = AnyEvent::Handle->new(
                fh => \*STDOUT,
                # omitting on_error for brevity
            );

            $ws->on_text(
                sub ($msg) {
                    utf8::encode($msg);
                    $out->push_write($msg);
                },
            );

            $ws->on_binary(
                sub ($msg) {
                    $out->push_write($msg);
                },
            );

            # 2. Anything we receive from STDIN should go to WS:

            my @pauses;

            $in_w = AnyEvent->io(
                fh => \*STDIN,
                poll => 'r',
                cb => sub {
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

                        undef $in_w;

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
    )->then(
        $cv,
        sub { $cv->croak(@_) },
    )->finally( sub { undef $in_w } );

    $cv->recv();
}

print "And now our song is done.\n";
