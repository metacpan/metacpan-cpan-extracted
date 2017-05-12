#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::HTTP::Server;
use Reflexive::Client::HTTP;
use HTTP::Request;

my $server = Test::HTTP::Server->new();

sub Test::HTTP::Server::Request::test { "test" }

my $ua = Reflexive::Client::HTTP->new;
isa_ok($ua,'Reflexive::Client::HTTP');

$ua->request( HTTP::Request->new( GET => $server->uri.'test' ) );

my $event = $ua->next();
isa_ok($event,'Reflexive::Client::HTTP::ResponseEvent','First event');

is($event->response->content,'test','First response has proper content');

$ua->request( HTTP::Request->new( GET => $server->uri.'echo' ) );

my $next_event = $ua->next();
isa_ok($next_event,'Reflexive::Client::HTTP::ResponseEvent','Second event');

my $request = HTTP::Request->parse($next_event->response->content);

is($request->uri->as_string,'/echo','Second request has proper uri');
is($request->method,'GET','Second request has proper method');
is($request->content,'','Second request has proper content');

done_testing;
