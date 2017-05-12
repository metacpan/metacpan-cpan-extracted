use strict;
use warnings;
use Test::More;

use Plack::Test;
use Plack::Builder;
use Plack::Middleware::REST;

use HTTP::Request::Common qw(GET PUT POST DELETE HEAD);
use HTTP::Status qw(status_message);

# simple OPTIONS and PATCH requests not provided by HTTP::Request::Common
sub OPTIONS { HTTP::Request->new( 'OPTIONS' => @_ ) }
sub PATCH { my $req = PUT(@_); $req->method('PATCH'); $req }

use lib 't/lib';
use RESTApp;

my $backend = RESTApp->new;

my $app = builder {
	enable 'REST',
		get         => sub { $backend->get(@_) },
		create      => sub { $backend->create(@_) },
		upsert      => sub { $backend->update(@_) },
		delete      => sub { $backend->delete(@_) },
        list        => sub { $backend->list(@_) },
        patch       => sub { $backend->patch(@_) },
        patch_types => [ 'text/plain' ];
        sub { [501,[],[status_message(501)]] };
};

test_psgi $app, sub {
	my $cb  = shift;

	my $res = $cb->(PUT '/');
	is $res->code, '405', 'PUT / not allowed';
	is $res->header('Allow'), 'GET, HEAD, OPTIONS, POST', 'GET, HEAD, OPTIONS, POST';

    $res = $cb->(OPTIONS '*');
	is $res->code, '200', 'found (OPTIONS)';
    is $res->header('Allow'), 'DELETE, GET, HEAD, OPTIONS, PATCH, PUT', 
                              'DELETE, GET, HEAD, OPTIONS, PATCH, PUT';
    is $res->header('Accept-Patch'), 'text/plain', 'only text/plain';

    $res = $cb->(OPTIONS '/');
	is $res->code, '200', 'found (OPTIONS)';
    is $res->header('Allow'), 'GET, HEAD, OPTIONS, POST', 'only GET, HEAD, OPTIONS, POST';

	$res = $cb->(GET '/1');
	is $res->code, '404', 'empty collection';

	$res = $cb->(POST '/', Content => 'hello', 'Content-Type' => 'text/plain');
	is $res->code, '201', 'created';
	is $res->header('Location'), 'http://localhost/1', 'with new URI';

	$res = $cb->(GET '/1');
	is $res->code, '200', 'found (GET)';
	is $res->content, 'hello', 'got back';

	$res = $cb->(HEAD '/1');
	is $res->code, '200', 'found (HEAD)';
	is $res->content, '', 'no content';

	$res = $cb->(PUT '/1', Content => 'world', 'Content-Type' => 'text/plain');
	is $res->code, 200, 'updated';
	
    $res = $cb->(GET '/1');
	is $res->content, 'world', 'modified';

	$res = $cb->(PATCH '/1', Content => 'universe', 'Content-Type' => 'text/plain');
	is $res->code, '204', 'updated';

    $res = $cb->(PATCH '/1', Content => '<data>world</data>', 'Content-Type' => 'application/xml');
	is $res->code, '415', 'unsupported patch type';

	$res = $cb->(GET '/1');
	is $res->content, 'universe', 'modified';

    $res = $cb->(OPTIONS '/1');
	is $res->code, '200', 'found (OPTIONS)';

    is $res->header('Allow'), 'DELETE, GET, HEAD, OPTIONS, PATCH, PUT',
                              'DELETE, GET, HEAD, OPTIONS, PATCH, PUT';
    is $res->header('Accept-Patch'), 'text/plain', 'only text/plain';

	$res = $cb->(POST '/', Content => 'hi', 'Content-Type' => 'text/plain');
    is $res->code, '201', 'created';
	is $res->header('Location'), 'http://localhost/2', 'with new URI';

    $res = $cb->(GET '/');
    is $res->content, "http://localhost/1\nhttp://localhost/2", 'list URIs';

	$res = $cb->(POST '/1');
	is $res->code, '405', 'POST on resource not allowed';
	is $res->header('Allow'), 'DELETE, GET, HEAD, OPTIONS, PATCH, PUT', 
                              'DELETE, GET, HEAD, OPTIONS, PATCH, PUT';
	$res = $cb->(DELETE '/1');
	is $res->code, '204', 'deleted resource';

	$res = $cb->(GET '/1');
	is $res->code, '404', 'resource gone (GET)';

	$res = $cb->(HEAD '/1');
	is $res->code, '404', 'resource gone (HEAD)';

};

{
    my $app = builder {
        enable 'REST',
            get => sub { $backend->get(@_) },
            head => 0,
            options => 0;
        sub { };
    };
    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(HEAD '/{id}');
        is $res->code, '405', 'HEAD disabled';
        is $res->header('Allow'), 'GET', 'only GET';
        $res = $cb->(OPTIONS '/{id}');
        is $res->code, '405', 'OPTIONS disabled';
        is $res->header('Allow'), 'GET', 'only GET';
        $res = $cb->(OPTIONS '/');
        is $res->code, '405', 'OPTIONS disabled';
        is $res->header('Allow'), 'GET', 'only GET';
    };
}

{
    my $app = builder {
        enable 'REST',
            get => sub { [200,[],['test']] },
            head => 'auto';
        sub { };
    };
    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/{id}');
        is $res->content, 'test';
        $res = $cb->(HEAD '/{id}');
        is $res->content, '', 'auto HEAD';
    };
}

done_testing;
