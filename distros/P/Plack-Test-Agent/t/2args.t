#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Plack::Test::Agent;

my $app   = sub { return [ 200, [], [ 'Hello' ] ] };

my $agent = Plack::Test::Agent->new(
    server => 'HTTP::Server::PSGI',
    app    => $app,
);

my $res = $agent->get( '/' );
is $res->content, 'Hello';

done_testing;
