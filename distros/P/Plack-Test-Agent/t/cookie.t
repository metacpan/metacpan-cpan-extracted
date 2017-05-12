#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Plack::Test::Agent;
use HTTP::Cookies;

my $app = sub
{
    return
    [
        200,
        [
            'Content-Type' => 'text/html',
            'Set-Cookie'   => "ID=123; path=/"
        ],
        [ "Hi" ]
    ];
};

my $agent = Plack::Test::Agent->new( app => $app );
my $res   = $agent->get( '/' );

my $cookie_jar = HTTP::Cookies->new;
$cookie_jar->extract_cookies($res);

my @cookies;
$cookie_jar->scan( sub { @cookies = @_ });

ok @cookies;
is $cookies[1], 'ID';

done_testing;
