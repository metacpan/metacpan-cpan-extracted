#!/usr/bin/env perl

# Copyright (C) 2009, Pascal Gaudette.

use strict;
use warnings;

use Test::More;
use MojoX::UserAgent;

plan tests => 54;

{
    package CookieTest;

    use strict;
    use warnings;

    use base 'Mojo::HelloWorld';

    sub handler {
        my ($self, $tx) = @_;

        if ($tx->req->url->path =~ m{^/echo}) {

            my $cookies = $tx->req->cookies;

            my $body = "xyz\n";
            for my $cookie (@{$cookies}) {
                $body .= $cookie->to_string . "\n";

            }
            if (my $ua = $tx->req->headers->user_agent) {
                $body .= "User-Agent: $ua\n";
            }
            $tx->res->code(200);
            $tx->res->headers->content_type('text/plain');

            $tx->res->body($body);

        }
        elsif ($tx->req->url->path =~ m{^/set}) {

            my $cookie = Mojo::Cookie::Response->new;
            $cookie->name('testcookie');
            $cookie->value('1969');
            $cookie->path('/');

            my $url = $tx->req->url->to_abs;
            $url->path('/echo');
            $tx->res->code(302);
            $tx->res->headers->set_cookie($cookie);
            $tx->res->headers->location($url);
        }
        elsif ($tx->req->url->path =~ m{^/unset}) {

            my $cookie = Mojo::Cookie::Response->new;
            $cookie->name('testcookie');
            $cookie->value('nomatter');
            $cookie->path('/');
            $cookie->max_age(0);

            $tx->res->code(302);
            $tx->res->headers->location('/echo');
            $tx->res->headers->set_cookie($cookie);
        }
        elsif ($tx->req->url->path =~ m{^/loop/(\d+)}) {

            my $x = $1;
            $x++;
            $tx->res->code(302);
            $tx->res->headers->location("/loop/$x");
        }
        elsif ($tx->req->url->path =~ m{^/multi}) {

            my $cookie1 = Mojo::Cookie::Response->new;
            $cookie1->name('multi1');
            $cookie1->value('111');
            $cookie1->path('/');
            $cookie1->domain('notreal.com');
            $cookie1->max_age(6000);

            my $cookie2 = Mojo::Cookie::Response->new;
            $cookie2->name('multi2');
            $cookie2->value('222');
            $cookie2->path('/');
            $cookie2->domain('notreal.com');
            $cookie2->max_age(6000);

            $tx->res->code(302);
            $tx->res->headers->set_cookie($cookie1, $cookie2);
            $tx->res->headers->location('/echo');
        }
        elsif ($tx->req->url->path =~ m{^/baddomain}) {

            my $cookie1 = Mojo::Cookie::Response->new;
            $cookie1->name('testevil');
            $cookie1->value('shouldntwork');
            $cookie1->path('/');
            $cookie1->domain('eal.com');
            $cookie1->max_age(6000);

            my $cookie2 = Mojo::Cookie::Response->new;
            $cookie2->name('testevil2');
            $cookie2->value('shouldntwork');
            $cookie2->path('/');
            $cookie2->domain('.com');
            $cookie2->max_age(6000);

            $tx->res->code(302);
            $tx->res->headers->set_cookie($cookie1, $cookie2);
            $tx->res->headers->location('/echo');
        }
        elsif ($tx->req->url->path =~ m{^/twolevelsup}) {

            my $domain = $tx->req->url->to_abs->host;
            $domain =~ s/^(\w+\.\w+\.)//;
            my $cookie = Mojo::Cookie::Response->new;
            $cookie->name('testevil');
            $cookie->value('shouldntwork');
            $cookie->path('/');
            $cookie->domain("$domain");
            $cookie->max_age(6000);

            $tx->res->code(302);
            $tx->res->headers->set_cookie($cookie);
            $tx->res->headers->location('/echo');
        }
        else {

            my $url = $tx->req->url->to_abs;
            $url->path('/echo');
            $tx->res->code(302);
            $tx->res->headers->location($url);
        }
    }
}


my $app = CookieTest->new;
isa_ok($app, "Mojo::HelloWorld");

my $ua = MojoX::UserAgent->new;
$ua->app($app);

$ua->default_headers(
    {   'X-Foo' => 'quux',
        'X-Bar' => '1001001'
    }
);

$ua->get(
    'http://www.notreal.com/echo/',
    sub {
        my ($ua_r, $tx) = @_;

        is($tx->res->code,      200,     "Test0 (default headers) - Status 200");
        is($tx->req->headers->header('X-Foo'), 'quux', "Test0 - X-Foo");
        is($tx->req->headers->header('X-Bar'), '1001001', "Test0 - X-Bar");
    }
);


$ua->get(
    'http://www.notreal.com/set/',
    sub {
        my ($ua_r, $tx) = @_;

        is($tx->res->code,      200,     "Test1 (set cookie) - Status 200");
        is($tx->hops,           1,       "Test1 - 1 hop");
        is($tx->req->url->path, '/echo', "Test1 - request path");
        is($tx->req->url, 'http://www.notreal.com/echo',
            "Test1 - request url");
        is($tx->res->headers->content_type,
            'text/plain', "Test1 - content-type");
        like($tx->res->body, qr/testcookie=1969/, "Test1 - cookie");
        like($tx->res->body,
            qr{User-Agent:.*MojoX::UserAgent/$MojoX::UserAgent::VERSION},
            "Test1 - user-agent found");
    }
);

$ua->run_all;


$ua->app($app);

$ua->get(
    'http://www.notreal.com/unset/',
    sub {
        my ($ua_r, $tx) = @_;

        is($tx->res->code,      200,     "Test2 (unset cookie) - Status 200");
        is($tx->hops,           1,       "Test2 - 1 hop");
        is($tx->req->url->path, '/echo', "Test2 - request path");
        is($tx->req->url, 'http://www.notreal.com/echo',
            "Test2 - request url");
        is($tx->res->headers->content_type,
            'text/plain', "Test2 - content-type");
        unlike($tx->res->body, qr/testcookie=1969/, "Test2 - cookie gone");
    }
);

$ua->run_all;


$ua->get(
    'http://www.notreal.com/loop/0',
    sub {
        my ($ua_r, $tx) = @_;

        is($tx->res->code, 302, "Test3 (request loop) - Status 302");
        is($tx->hops, 10, "Test3 - 10 hops");
        is($tx->req->url->path, '/loop/10', "Test3 - request path");
        is( $tx->req->url,
            'http://www.notreal.com/loop/10',
            "Test3 - request url"
        );
    }
);

$ua->run_all;


$ua->get(
    'http://www.notreal.com/multi/',
    sub {
        my ($ua_r, $tx) = @_;

        is($tx->res->code, 200, "Test4 (multiple set-cookie) - Status 200");
        is($tx->hops, 1, "Test4 - 1 hop");
        is($tx->req->url->path, '/echo', "Test4 - request path");
        like($tx->res->body, qr/multi1=111/, "Test4 - 1st cookie found");
        like($tx->res->body, qr/multi2=222/, "Test4 - 2nd cookie found");
    }
);

$ua->run_all;


$ua->get(
    'http://www.notreal.com/baddomain/',
    sub {
        my ($ua_r, $tx) = @_;

        is($tx->res->code, 200, "Test5 (bad cookie domains) - Status 200");
        is($tx->hops, 1, "Test5 - 1 hop");
        is($tx->req->url->path, '/echo', "Test5 - request path");
        unlike($tx->res->body, qr/testevil/, "Test5 - bad cookie absent");
    }
);

$ua->run_all;


$ua->get(
    'http://www.eal.com/echo/',
    sub {
        my ($ua_r, $tx) = @_;

        is($tx->res->code, 200, "Test5 - Status 200");
        unlike($tx->res->body, qr/testevil/, "Test5 - bad cookie absent");
    }
);

$ua->run_all;


$ua->get(
    'http://www.foo.notreal.com/twolevelsup/',
    sub {
        my ($ua_r, $tx) = @_;

        is($tx->res->code, 200,
            "Test6 (cookie domain two levels up) - Status 200");
        is($tx->hops, 1, "Test6 - 1 hop");
        is( $tx->req->url,
            'http://www.foo.notreal.com/echo',
            "Test6 - request url"
        );
        unlike($tx->res->body, qr/testevil/, "Test6 - bad cookie absent");
    }
);

$ua->run_all;


$ua->agent("007");

$ua->get(
    'http://www.notreal.com/echo/',
    sub {
        my ($ua_r, $tx) = @_;

        is($tx->res->code,      200,     "Test7 (custom UA string) - Status 200");
        like($tx->res->body, qr/User-Agent:.*007/,
            "Test7 - user-agent string");
    }
);

$ua->run_all;


$ua->maxconnections(2);
$ua->get(
    'http://www.notreal.com/echo/0',
    sub {
        my ($ua_r, $tx) = @_;
    }
);
$ua->get(
    'http://www.notreal.com/echo/1',
    sub {
        my ($ua_r, $tx) = @_;
    }
);
$ua->get(
    'http://www.notreal.com/echo/3',
    sub {
        my ($ua_r, $tx) = @_;
    }
);

is(scalar @{$ua->_ondeck->{"www.notreal.com:80"}},
    3, "Test 8 (maxconnections) - 3 txs on deck");
is(scalar @{$ua->_active->{"www.notreal.com:80"}}, 0, "Test 8 - 0 active txs");

$ua->crank_all;

is(scalar @{$ua->_ondeck->{"www.notreal.com:80"}}, 1, "Test 8 - 1 tx on deck");
is(scalar @{$ua->_active->{"www.notreal.com:80"}}, 2, "Test 8 - 2 txs active");

$ua->run_all;


# Make more complicated requests


$ua->allow_post_redirect(0);

my $tx = MojoX::UserAgent::Transaction->new(
    {   url     => 'http://www.notreal.com/set/',
        method  => 'POST',
        ua      => $ua,
        id      => "a1a1a1",
        headers => {
            'Expect'       => '100-continue',
            'Content-Type' => 'text/plain'
        },
        body     => 'Hello Mojo! 39827',
        callback => sub {
            my ($ua, $tx) = @_;
            is($tx->res->code, 302,
                "Test9 (No redirect on POST) - Status");
            is($tx->id, 'a1a1a1', "Test 9 - ID");
            is($tx->req->headers->content_type,
                'text/plain', "Test 9 - Content-type");
            is($tx->req->headers->expect, '100-continue', "Test 9 - Expect");
            is($tx->req->headers->content_length,
                17, "Test 9 - Content-length");
            is($tx->req->body, 'Hello Mojo! 39827', "Test 9 - Body");
          }
    }
);

$ua->spool($tx);

$ua->run_all;

$ua->allow_post_redirect(1);

$tx = MojoX::UserAgent::Transaction->new(
    {   url     => 'http://www.notreal.com/set/',
        method  => 'POST',
        ua      => $ua,
        id      => "a2a2a2",
        headers => {
            'Expect'       => '100-continue',
            'Content-Type' => 'text/plain'
        },
        body     => 'Hello Mojo! 39827',
        callback => sub {
            my ($ua, $tx) = @_;
            is($tx->res->code, 200, "Test10 (Redirect on POST) - Status");
            is($tx->id, 'a2a2a2', "Test 10 - ID");
            is($tx->req->method, 'GET', "Test10 - Method");
            is( $tx->req->url,
                'http://www.notreal.com/echo',
                "Test10 - url"
            );
            is($tx->req->headers->content_type,
                undef, "Test 10 - content-type");
            is($tx->original_req->headers->content_type,
                'text/plain', "Test 10 - original content-type");
          }
    }
);

$ua->spool($tx);

$ua->run_all;

