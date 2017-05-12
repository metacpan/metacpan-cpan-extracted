#!/usr/bin/env perl

use strict;
use warnings;
use 5.012;
use Carp;
use autodie;
use utf8;

use HTTP::Request;
use Plack::Request;
use Plack::Test;
use Test::More;

use Plack::Middleware::Inflater;

my $app = sub {
    my $request = Plack::Request->new(shift);
    my $response = $request->new_response(
        200,
        ['X-Request-Content-Length', $request->header('Content-Length'),
         'X-Request-Content', $request->content],
        'OK');
    return $response->finalize;
};

my $instance = Plack::Test->create(Plack::Middleware::Inflater->wrap($app));

subtest 'gzip upload' => sub {
    my $request = HTTP::Request->new(
        POST => '/',
        [ 'Content-Length', 65,
          'Content-Encoding', 'gzip' ]);
    $request->content(do {
        open my $fh, '<', 't/data/content.gz';
        local $/;
        <$fh> });

    my $response = $instance->request($request);

    is($response->header('X-Request-Content-Length'),
       39,
       q{... and the Content-Length is adjusted});
    is($response->header('X-Request-Content'),
       'this is some content in a gzipped file',
       q{... and the body is decoded from gzip});
};

subtest 'regular upload' => sub {
    my $request = HTTP::Request->new(
        POST => '/',
        [ 'Content-Length', 42 ]);
    $request->content(do {
        open my $fh, '<', 't/data/content.txt';
        local $/;
        <$fh> });

    my $response = $instance->request($request);

    is($response->header('X-Request-Content-Length'),
       42,
       q{... and the Content-Length is not touched});
    is($response->header('X-Request-Content'),
       'this is some content in a plain text file',
       q{... and neither is the body});
};

subtest 'crap upload' => sub {
    my $request = HTTP::Request->new(
        POST => '/',
        [ 'Content-Length', 42,
          'Content-Encoding', 'gzip' ]);
    $request->content(do {
        open my $fh, '<', 't/data/content.txt';
        local $/;
        <$fh> });

    my $response = $instance->request($request);

    is($response->header('X-Request-Content-Length'),
       42,
       q{... and the Content-Length is still good});
    is($response->header('X-Request-Content'),
       'this is some content in a plain text file',
       q{... and the body is still good});
};

done_testing;

