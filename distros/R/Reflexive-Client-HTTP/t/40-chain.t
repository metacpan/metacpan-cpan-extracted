#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::HTTP::Server;
use Reflexive::Client::HTTP;
use HTTP::Request;

my $server = Test::HTTP::Server->new();

sub Test::HTTP::Server::Request::one { "1" }
sub Test::HTTP::Server::Request::two { "2" }
sub Test::HTTP::Server::Request::three { "3" }

my $ua = Reflexive::Client::HTTP->new;

$ua->request( HTTP::Request->new( GET => $server->uri.'one' ), sub {
	is($_->content,'1','First request fine');
	return HTTP::Request->new( GET => $server->uri.'two' ), sub {
		is($_->content,'2','Second request fine');
		return HTTP::Request->new( GET => $server->uri.'three' ), sub {
			is($_->content,'3','Third request fine');
			$server = undef;
		};
	};
});

Reflex->run_all();

done_testing;
