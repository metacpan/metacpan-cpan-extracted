#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 64;

use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

our @log;

my $test = sub {
    my ($app, @args) = @_;
    return sub {
        my ($req) = @_;
        my $app = builder {
            enable 'Plack::Middleware::TrafficLog',
                logger => sub { push @log, "@_" }, @args;
            $app;
        };
        test_psgi $app, sub { $_[0]->($req) };
    };
};


{
    my $req = POST 'http://example.com/', Content => "TEST\nTEST\n";
    $req->header('Host' => 'example.com', 'Content-Type' => 'text/plain');

    my $app_static = sub {
        [ 200, [ 'Content-Type' => 'text/plain' ], [ "OK\nOK\n" ] ]
    };

    {
        local @log;
        my $res = $test->($app_static, with_body => 1)->($req);
        is $res->code, 200, 'response code';
        is $res->content, "OK\nOK\n", 'response content';
        is @log, 2, 'no args [lines]';
        like $log[0], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|TEST TEST $}, 'no args [0]';
        like $log[1], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|OK OK $}, 'no args [1]';
    }

    {
        local @log;
        my $res = $test->($app_static, with_date => 1, with_request => 1, with_response => 1, with_body => 1, eol => '|', body_eol => ' ')->($req);
        is $res->code, 200, 'response code';
        is $res->content, "OK\nOK\n", 'response content';
        is @log, 2, 'all args [lines]';
        like $log[0], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|TEST TEST $}, 'all args [0]';
        like $log[1], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|OK OK $}, 'all args [1]';
    }

    {
        local @log;
        my $res = $test->($app_static, with_date => 0, with_body => 1)->($req);
        is $res->code, 200, 'response code';
        is $res->content, "OK\nOK\n", 'response content';
        is @log, 2, 'without date [lines]';
        like $log[0], qr{^\[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|TEST TEST $}, 'without date [0]';
        like $log[1], qr{^\[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|OK OK $}, 'without date [1]';
    }

    {
        local @log;
        my $res = $test->($app_static, with_date => 0, with_request => 1, with_response => 0, with_body => 1)->($req);
        is $res->code, 200, 'response code';
        is $res->content, "OK\nOK\n", 'response content';
        is @log, 1, 'only request [lines]';
        like $log[0], qr{^\[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|TEST TEST $}, 'only request [0]';
    }

    {
        local @log;
        my $res = $test->($app_static, with_date => 0, with_request => 0, with_response => 1, with_body => 1)->($req);
        is $res->code, 200, 'response code';
        is $res->content, "OK\nOK\n", 'response content';
        is @log, 1, 'only response [lines]';
        like $log[0], qr{^\[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|OK OK $}, 'only response [0]';
    }

    {
        local @log;
        my $res = $test->($app_static, with_date => 0)->($req);
        is $res->code, 200, 'response code';
        is $res->content, "OK\nOK\n", 'response content';
        is @log, 2, 'without body [lines]';
        like $log[0], qr{^\[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|$}, 'without body [0]';
        like $log[1], qr{^\[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|$}, 'without body [1]';
    }

    {
        local @log;
        my $res = $test->($app_static, with_date => 0, with_body => 1, eol => '!')->($req);
        is $res->code, 200, 'response code';
        is $res->content, "OK\nOK\n", 'response content';
        is @log, 2, 'with eol [lines]';
        like $log[0], qr{^\[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] !POST / HTTP/1.1!Host: example.com!Content-Length: 10!Content-Type: text/plain!!TEST!TEST!$}, 'with eol [0]';
        like $log[1], qr{^\[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] !HTTP/1.0 200 OK!Content-Type: text/plain!!OK!OK!$}, 'with eol [1]';
    }

    {
        local @log;
        my $res = $test->($app_static, with_date => 0, with_body => 1, eol => '!', body_eol => ',')->($req);
        is $res->code, 200, 'response code';
        is $res->content, "OK\nOK\n", 'response content';
        is @log, 2, 'with body_eol [lines]';
        like $log[0], qr{^\[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] !POST / HTTP/1.1!Host: example.com!Content-Length: 10!Content-Type: text/plain!!TEST,TEST,$}, 'with body_eol [0]';
        like $log[1], qr{^\[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] !HTTP/1.0 200 OK!Content-Type: text/plain!!OK,OK,$}, 'with body_eol [1]';
    }

    {
        my $req_empty = GET 'http://example.com/';

        my $app_static_empty = sub {
            [ 200, [ 'Content-Type' => 'text/plain' ], [] ]
        };

        {
            local @log;
            my $res = $test->($app_static_empty, with_body => 1)->($req_empty);
            is $res->code, 200, 'response code';
            is $res->content, '', 'response content';
            is @log, 2, 'empty [lines]';
            like $log[0], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] \|GET / HTTP/1.1\|Host: example.com\|Content-Length: 0\|\|$}, 'empty [0]';
            like $log[1], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|$}, 'empty [1]';
        }
    }

    {
        my $app_delayed = sub {
            my ($app) = @_;
            return sub {
                my ($env) = @_;
                return sub {
                    my ($responder) = @_;
                    $responder->( $app->() );
                };
            };
        };

        local @log;
        my $res = $test->($app_delayed->($app_static), with_body => 1)->($req);
        is $res->code, 200, 'response code';
        is $res->content, "OK\nOK\n", 'response content';
        is @log, 2, 'delayed [lines]';
        like $log[0], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|TEST TEST $}, 'delayed [0]';
        like $log[1], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|OK OK $}, 'delayed [1]';
    }

    {
        my $app_streaming = sub {
            return sub {
                my ($responder) = @_;
                my $writer = $responder->(
                    [ 200, [ 'Content-Type' => 'text/plain' ] ]
                );
                $writer->write("OK\n");
                $writer->write("OK\n");
                $writer->close;
                return;
            };
        };

        local @log;
        my $res = $test->($app_streaming, with_body => 1)->($req);
        is $res->code, 200, 'response code';
        is $res->content, "OK\nOK\n", 'response content';
        is @log, 2, 'streaming [lines]';
        like $log[0], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|TEST TEST $}, 'streaming [0]';
        like $log[1], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|OK $}, 'streaming [1]';
    }

    {
        my $app_streaming = sub {
            return sub {
                my ($responder) = @_;
                my $writer = $responder->(
                    [ 200, [ 'Content-Type' => 'text/plain' ] ]
                );
                $writer->write("OK\n");
                $writer->write("OK\n");
                $writer->close;
                return;
            };
        };

        local @log;
        my $res = $test->($app_streaming, with_body => 1, with_all_chunks => 1)->($req);
        is $res->code, 200, 'response code';
        is $res->content, "OK\nOK\n", 'response content';
        is @log, 3, 'streaming [lines]';
        like $log[0], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10\|Content-Type: text/plain\|\|TEST TEST $}, 'streaming [0]';
        like $log[1], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|OK $}, 'streaming [1]';
        like $log[2], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] \|HTTP/1.0 200 OK\|Content-Type: text/plain\|\|OK $}, 'streaming [2]';
    }

    {
        my $app_static_499 = sub {
            [ 499, [ 'Content-Type' => 'text/plain' ], ["Unknown error\n"] ]
        };

        {
            local @log;
            my $res = $test->($app_static_499, with_body => 1)->($req);
            is $res->code, 499, 'response code';
            is $res->content, "Unknown error\n", 'response content';
            is @log, 2, 'error 499 [lines]';
            like $log[0], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ -> example.com:80\] \[Request \] \|POST / HTTP/1.1\|Host: example.com\|Content-Length: 10|Content-Type: text/plain\|\|TEST TEST\|\|$}, 'error 499 [0]';
            like $log[1], qr{^\[\d{2}/\S+/\d{4}:\d{2}:\d{2}:\d{2} \S+\] \[\d+\] \[127.0.0.1:\d+ <- example.com:80\] \[Response\] \|HTTP/1.0 499 \|Content-Type: text/plain\|\|Unknown error $}, 'error 499 [1]';
        }
    }

}

done_testing;
