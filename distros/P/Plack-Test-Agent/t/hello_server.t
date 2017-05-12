#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Plack::Test::Agent;
use HTTP::Server::Simple::PSGI;

my $app = sub
{
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
};

my %server = (
    'HTTP::Server::PSGI'   => 'HTTP::Server::PSGI',
    'HTTP::Server::Simple' => undef,
);

foreach my $server_class ( keys %server ) {
    my $agent = Plack::Test::Agent->new(
        app    => $app,
        server => $server_class,
    );

    my $res = $agent->get( 'http://localhost/hello' );

    is $res->content,      'Hello World';
    is $res->content_type, 'text/plain';
    is $res->code,         200;
    is $res->header( 'Server' ), $server{$server_class},
        '... should use server when given server';
}


done_testing;
