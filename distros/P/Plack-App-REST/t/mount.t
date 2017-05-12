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

	$res = $cb->(GET "http://localhost/api");
	use Data::Dumper;
	print STDERR "RES: ".Dumper($res);
	is_deeply( [$res->code, $res->headers->as_string, $res->content], [200, '', 'app/root'], 'Test 1' );

	$res = $cb->(GET "http://localhost/api/");
	is_deeply( [$res->code, $res->headers->as_string, $res->content], [200, '', 'app/root'], 'Test 2' );

	$res = $cb->(GET "http://localhost/api/123");
	is_deeply( [$res->code, $res->headers->as_string, $res->content], [200, '', 'app/root1'], 'Test 3' );

	$res = $cb->(GET "http://localhost/api1/test");
	is_deeply( [$res->code, $res->headers->as_string, $res->content], [404, "Content-Type: text/plain\n", 'Not Found'], 'Test 4' );

	$res = $cb->(POST "http://localhost/api");
	is_deeply( [$res->code, $res->headers->as_string, $res->content], [405, "Content-Type: text/plain\n", 'Method Not Allowed'], 'Test 5' );

};

done_testing;

package Test::Root;
use parent qw(Plack::App::REST);

sub GET {
	my ($self, $env, $data) = @_;

	my $param = $env->{'rest.ids'};

	if ($param){
		return ['app/root1'];
	}else{
		return ['app/root'];
	}		
}