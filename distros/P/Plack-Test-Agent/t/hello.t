#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Plack::Test::Agent;

my $app = sub
{
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
};

my $agent = Plack::Test::Agent->new( app => $app );
my $res   = $agent->get( 'http://localhost/hello' );
is $res->content, 'Hello World';
is $res->content_type, 'text/plain';
is $res->code, 200;
is $res->header( 'Server' ), undef, '... should default to MockHTTP server';

done_testing;
