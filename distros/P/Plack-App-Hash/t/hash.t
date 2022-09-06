use strict; use warnings;

use Test::More tests => 18;
use Plack::App::Hash;
use Plack::Test;
use HTTP::Request::Common;

my $app = Plack::App::Hash->new( content => { 'index.html' => 'Hi!', selfdestruct => [] } );

test_psgi app => $app, client => sub {
	my $cb = shift;

	my $res;

	####################################################################

	$res = $cb->( GET '/index.html' );
	is $res->code, 200, 'Request for existing resource succeeds...';
	is $res->content, 'Hi!', '... with the right content';
	ok !$res->content_type, '... and no type';

	$res = $cb->( GET '/santaclaus' );
	is $res->code, 404, '... but for non-existing resource fails';

	####################################################################

	$app->default_type( 'text/html' );
	$res = $cb->( GET '/index.html' );
	is $res->content_type, 'text/html', 'Setting a default content type works';

	$app->default_type( undef );
	$res = $cb->( GET '/index.html' );
	ok !$res->content_type, '... as does resetting it';

	####################################################################

	$app->auto_type(1);
	$res = $cb->( GET '/index.html' );
	is $res->content_type, 'text/html', 'Setting automatic content type works';

	$app->auto_type( undef );
	$res = $cb->( GET '/index.html' );
	ok !$res->content_type, '... as does resetting it';

	####################################################################

	$app->default_type( 'text/plain' );
	$app->auto_type(1);
	$res = $cb->( GET '/index.html' );
	is $res->content_type, 'text/html', 'Automatic content type overrides the default type';

	$app->auto_type( undef );
	$app->default_type( undef );
	$res = $cb->( GET '/index.html' );
	ok !$res->content_type, '(commercial break to clean the test slate)';

	####################################################################

	$app->headers->{ 'index.html' } = '["Content-Type","text/plain"]';
	$res = $cb->( GET '/index.html' );
	is $res->content_type, 'text/plain', 'Adding JSON headers for particular resources works';

	$app->headers->{ 'index.html' } = [qw( Content-Type text/plain )];
	$res = $cb->( GET '/index.html' );
	is $res->content_type, 'text/plain', '... as does adding actual arrayrefs';

	$app->default_type( 'application/octet-stream' );
	$res = $cb->( GET '/index.html' );
	is $res->content_type, 'text/plain', '... and it overrides the default content type';

	$app->auto_type(1);
	$res = $cb->( GET '/index.html' );
	is $res->content_type, 'text/plain', '... as well as the automatic content type';

	$app->auto_type( undef );
	$app->default_type( undef );
	delete $app->headers->{ 'index.html' };
	$res = $cb->( GET '/index.html' );
	ok !$res->content_type, '... and it can be reset';

	####################################################################

	$res = $cb->( GET '/selfdestruct' );
	is $res->code, 500, 'Bad data throws a server error';

	$app->headers->{ 'index.html' } = {};
	$res = $cb->( GET '/index.html' );
	is $res->code, 500, '... as do bad headers';

	$app->headers->{ 'index.html' } = 'badaboom';
	$res = $cb->( GET '/index.html' );
	is $res->code, 500, '... and in JSON too';
};
