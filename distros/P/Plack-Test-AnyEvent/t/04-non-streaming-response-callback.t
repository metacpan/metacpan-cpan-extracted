#!/usr/bin/env perl

use strict;
use Test::More tests => 5;

use Plack::Test;
$Plack::Test::Impl = 'AnyEvent';

use AnyEvent;
use HTTP::Request::Common;

my $app = sub {
    my ( $env ) = @_;

    if($env->{QUERY_STRING} =~ /non-blocking/) {
        return sub {
            my ( $respond ) = @_;

            my $writer = $respond->([200, ['Content-Type' => 'text/plain']]);

            my $timer;
            $timer = AnyEvent->timer(
                after => 1,
                cb    => sub {
                    undef $timer;
                    $writer->write("ok");
                    $writer->close;
                },
            );
        };
    } else {
        return [200, ['Content-Type' => 'text/plain'], ['ok']];
    }
};

test_psgi $app, sub {
    my ( $cb ) = @_;

    my $num_callbacks_invoked = 0;

    my $res = $cb->(GET '/?non-blocking');
    is $res->code, 200;
    $res->on_content_received(sub {
        $num_callbacks_invoked++;
        is $res->content, 'ok';
    });
    $res->recv;

    my $res = $cb->(GET '/');
    is $res->code, 200;
    $res->on_content_received(sub{
        $num_callbacks_invoked++;
        is $res->content, 'ok';
    });
    $res->recv;
    is $num_callbacks_invoked, 2, 'make sure that both callbacks have been invoked';
};
