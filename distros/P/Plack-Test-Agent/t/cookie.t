#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Plack::Test::Agent;
use HTTP::Cookies;

my $app = sub {
    return $_[0]->{REQUEST_URI} eq '/'
        ? [
        200,
        [
            'Content-Type' => 'text/html',
            'Set-Cookie'   => "ID=123; path=/"
        ],
        ["Hi"]
        ]
        : [
        200,
        [
            'Content-Type' => 'text/html',
        ],
        ["Hi"]
        ];
};

my $agent = Plack::Test::Agent->new( app => $app );
my $res   = $agent->get('/');

my $cookie_jar = HTTP::Cookies->new;
$cookie_jar->extract_cookies($res);

my @cookies;
$cookie_jar->scan( sub { @cookies = @_ } );

ok @cookies;
is $cookies[1], 'ID';

my $ares = $agent->get('/a');
is $ares->request->header('cookie'), 'ID=123';

done_testing;
