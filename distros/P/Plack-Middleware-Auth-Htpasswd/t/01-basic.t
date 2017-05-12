#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Path::Class;
use Plack::Builder;

{
    my $app = builder {
        enable 'Auth::Htpasswd',
            file => file(__FILE__)->dir->subdir('data', '01')->file('htpasswd');
        sub {
            [
                200,
                [ 'Content-Type' => 'text/plain' ],
                [ "Hello $_[0]->{REMOTE_USER}" ],
            ]
        };
    };

    test_psgi app => $app, client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET "/");
            is($res->code, 401, "plain request gets 401");
        }

        {
            my $res = $cb->(
                GET "/", "Authorization" => "Basic dGVzdDplZGNiYQ==",
            );
            is($res->code, 401, "request with wrong password gets 401");
        }

        {
            my $res = $cb->(
                GET "/", "Authorization" => "Basic dHNldDphYmNkZQ==",
            );
            is($res->code, 401, "request with unknown username gets 401");
        }

        {
            my $res = $cb->(
                GET "/", "Authorization" => "Basic dGVzdDphYmNkZQ==",
            );
            is($res->code, 200, "valid authentication succeeds");
            is($res->content, "Hello test", "and gets the right content");
        }
    };
}

{
    my $app = builder {
        enable 'Auth::Htpasswd',
            file  => file(__FILE__)->dir->subdir('data', '01', 'htpasswd'),
            realm => 'my realm';
        sub {
            [
                200,
                [ 'Content-Type' => 'text/plain' ],
                [ "Hello $_[0]->{REMOTE_USER}" ],
            ]
        };
    };

    test_psgi app => $app, client => sub {
        my $cb = shift;

        {
            my $res = $cb->(GET "/");
            is($res->header('WWW-Authenticate'), 'Basic realm="my realm"',
               "can set realm");
        }
    };
}

done_testing;
