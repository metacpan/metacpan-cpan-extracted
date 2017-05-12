#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::HTTP::Server;
use Reflexive::Client::HTTP;
use HTTP::Request;

my $server = Test::HTTP::Server->new();

my $ua = Reflexive::Client::HTTP->new;
isa_ok($ua,'Reflexive::Client::HTTP');

my $test_count = 0;

for (1..5) {
	$ua->request(
		HTTP::Request->new( GET => $server->uri.'echo' ),
		sub {
			my ( $no ) = @_;
			is($_->code,'200',$no.' response is a success');
			my $request = HTTP::Request->parse($_->content);
			is($request->uri->as_string,'/echo',$no.'. request has proper uri');
			is($request->method,'GET',$no.'. request has proper method');
			is($request->content,'',$no.'. request has proper content');
			$test_count++;
			$server = undef if $test_count == 5;
		},
		$_
	);
}

Reflex->run_all();

is($test_count,5,'There were 5 proper test responses');

done_testing;
