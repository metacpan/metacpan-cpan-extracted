use strict; use warnings;

use Test::More tests => 18;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

our $key = 'PATH_INFO';
my $status = sub { 200 };
my $app = sub { return [ $status->($_[0]), [ 'Content-Type' => 'text/plain' ], [ $_[0]{ $key } ] ] };

$app = builder {
	enable 'Precompressed', match => qr/\.js\z/;
	$app;
};

test_psgi app => $app, client => sub {
	my $cb = shift;
	my $res;

	$status = sub { 200 };

	$res = $cb->( GET 'http://localhost/foo' );
	is $res->content(), '/foo', 'Unmatched requests are unmolested';
	ok !$res->header( 'Vary' ), '... as are their headers';

	$res = $cb->( GET 'http://localhost/foo', 'Accept-Encoding' => 'gzip' );
	is $res->content(), '/foo', '... even with compression request headers given';
	ok !$res->header( 'Vary' ), '... which have no effect on response headers either';

	$res = $cb->( GET 'http://localhost/foo.js' );
	is $res->content(), '/foo.js', 'Matched requests without compression headers are unmolested';
	is $res->header( 'Vary' ), 'Accept-Encoding', '... aside from Accept-Encoding being declared as a Vary criterion';

	$res = $cb->( GET 'http://localhost/foo.js', 'Accept-Encoding' => 'gzip' );
	is $res->content(), '/foo.js.gz', 'Matched requests with compression headers get served from precompressed files';
	is $res->header( 'Content-Type' ), 'application/javascript', '... using a locally detected MIME type';
	is $res->header( 'Content-Encoding' ), 'gzip', '... and have the right encoding declared';
	is $res->header( 'Vary' ), 'Accept-Encoding', '... along with Accept-Encoding a Vary criterion';

	{
	local $key = 'HTTP_ACCEPT_ENCODING';
	$res = $cb->( GET 'http://localhost/foo.js', 'Accept-Encoding' => 'gzip' );
	is $res->content(), '', '... and with Accept-Encoding hidden from the wrapped PSGI app';
	}

	$status = sub { 404 };

	$res = $cb->( GET 'http://localhost/foo' );
	ok !$res->header( 'Vary' ), 'Failed and non-content requests are unmolested';

	$res = $cb->( GET 'http://localhost/foo', 'Accept-Encoding' => 'gzip' );
	ok !$res->header( 'Vary' ), '... even with compression request headers given';

	$res = $cb->( GET 'http://localhost/foo.js' );
	ok !$res->header( 'Vary' ), '... regardless of whether they match';

	$res = $cb->( GET 'http://localhost/foo.js', 'Accept-Encoding' => 'gzip' );
	ok !$res->header( 'Vary' ), '... with or without compression headers';

	$status = sub { $_[0]{'PATH_INFO'} =~ /\.gz\z/ ? 404 : 200 };

	$res = $cb->( GET 'http://localhost/foo.js', 'Accept-Encoding' => 'gzip' );
	is $res->content(), '/foo.js', 'Matched requests with compression headers but no precompressed file still get served';
	ok !$res->header( 'Content-Encoding' ), '... with no encoding header';
	ok !$res->header( 'Vary' ), '... and no Vary header';
};
