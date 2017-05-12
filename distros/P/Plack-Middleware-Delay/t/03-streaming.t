#!/usr/bin/env perl

use strict;
use warnings;

use AnyEvent::HTTP;
use Plack::Builder;
use Plack::Loader;
use Test::More tests => 5;
use Test::TCP;
use Time::HiRes qw(time);

my $app = sub {
    return sub {
        my ( $respond ) = @_;

        my $writer = $respond->([
            200,
            ['Content-Type' => 'text/plain'],
        ]);

        my $count = 0;
        my $timer;
        $timer = AnyEvent->timer(
            interval => 1,
            cb       => sub {
                $writer->write($count . "\n");
                if($count++ >= 5) {
                    $writer->close;
                    undef $timer;
                }
            },
        );
    };
};

my $wrapped = builder {
    enable 'Delay', delay => 5, sleep_fn => sub {
        my ( $delay, $invoke ) = @_;

        my $timer;
        $timer = AnyEvent->timer(
            after => $delay,
            cb    => sub {
                undef $timer;
                $invoke->();
            },
        );
    };

    $app;
};

test_tcp(
    client => sub {
        my ( $port ) = @_;

        my $cond = AnyEvent->condvar;

        http_get "http://localhost:$port", sub {
            my ( $data, $headers ) = @_;

            is $data, join('', map { "$_\n" } (0..5)), "Data should match";

            $cond->send;
        };

        my $start = time;
        $cond->recv;
        my $end = time;

        my $diff = $end - $start;

        ok $diff >= 10, "Waiting for a streaming response should take over ten seconds";

        $cond = AnyEvent->condvar;

        http_get "http://localhost:$port", want_body_handle => 1, sub {
            my ( $h, $headers ) = @_;

            $end = time; ## seems kind of backwards here...

            my $buffer = '';

            $h->on_read(sub {
                my $buf  = $h->rbuf;
                $h->rbuf = '';
                $buffer .= $buf;
            });

            $h->on_eof(sub {
                is $buffer, join('', map { "$_\n" } (0..5)), "Data should match";
                undef $h;
                $cond->send;
            });
        };

        $start = time;
        $cond->recv;

        $diff = $end - $start;

        ok $diff >= 5, "Waiting for just the headers of a delayed response should take over five seconds...";
        ok $diff < 10, "...but less than ten";
    },
    server => sub {
        my ( $port ) = @_;

        Plack::Loader->load('Twiggy', port => $port)->run($wrapped);
    },
);
