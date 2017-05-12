#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::HTTP::Server;
use Reflexive::Client::HTTP;
use HTTP::Request;

my $server = Test::HTTP::Server->new();
my $test_count;

{
	package MySampleClient;

	use Moose;
	with 'Reflexive::Client::HTTP::Role';

	sub on_http_response {
		my ( $self, $response_event ) = @_;
		my $http_response = $response_event->response;
		my ( $who ) = @{$response_event->args};
		main::is($http_response->code,'200',$who.' response is a success');
		my $request = HTTP::Request->parse($http_response->content);
		main::is($request->uri->as_string,'/echo',$who.' request has proper uri');
		main::is($request->method,'GET',$who.' request has proper method');
		main::is($request->content,'',$who.' request has proper content');
		$test_count++;
		$server = undef if $test_count == 3;
	}

	sub request {
		my ( $self, $who ) = @_;
		$self->http_request( HTTP::Request->new( GET => $server->uri.'echo' ), $who );
	}
}

my $msc = MySampleClient->new;
ok($msc->does('Reflexive::Client::HTTP::Role'),'MySampleClient does Reflexive::Client::HTTP::Role');

$msc->request('peter');
$msc->request('paul');
$msc->request('marry');

Reflex->run_all();

done_testing;
