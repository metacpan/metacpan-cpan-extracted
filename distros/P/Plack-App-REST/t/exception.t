#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::URLMap;
use Plack::App::REST;

BEGIN {
	use_ok( 'Plack::App::REST' ) || print "Bail out!\n";
}

my $urlmap = Plack::App::URLMap->new;

my $app = builder {
		mount "/api" => builder {
			mount '/' => Test::Root->new();
		};
};

test_psgi app => $app, client => sub {
	my $cb = shift;

	my $res ;

	$res = $cb->(GET "http://localhost/api/test");
	is_deeply( [$res->code, $res->headers->as_string, $res->content], [404, "Content-Type: text/plain\n", 'Not Found'], 'Test 4' );

	$res = $cb->(GET "http://localhost/api/405");
	is_deeply( [$res->code, $res->headers->as_string, $res->content], [405, "Content-Type: text/plain\n", 'Method Not Allowed'], 'Test 5' );

	$res = $cb->(GET "http://localhost/api");
	is_deeply( [$res->code, $res->headers->as_string], [500, "Content-Type: text/plain\n"], 'Test 5' );

};

done_testing;

package Test::Root;
use parent qw(Plack::App::REST);

use HTTP::Exception;

sub GET {
	my ($self, $env, $data) = @_;

	my ($param) = @{$env->{'rest.ids'}};

	if ($param && $param eq 'test'){
		HTTP::Exception::404->throw(message=>"Not Found");
	}elsif($param && $param eq '405'){
		HTTP::Exception::405->throw(message=>"Method Not Allowed");
	}else{
		die 'test';
	}

	return {}
}