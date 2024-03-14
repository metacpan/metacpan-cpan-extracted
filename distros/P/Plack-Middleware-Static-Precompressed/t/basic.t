use strict; use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::Middleware::Static::Precompressed;
use Plack::MIME;
use lib 't/lib';
use MockPSGIBodyFH;

Plack::MIME->add_type( '.pm' => 'fake/fake' );

my $app = Plack::Middleware::Static::Precompressed->new(
	files => [qw(
		t/lib/MockPSGIBodyFH.pm
		t/lib/test.js
		t/lib/test.gzipjs
		t/lib/test.txt
		t/basic.t
	)],
	path_info => sub {
		push @{ $_[1] }, 'Content-Type' => $1 if /(basic)/;
		s!^t/!!;
		( $_, s!(gzip)!! ? $1 : undef );
	},
	default_charset => 'us-ascii',
);

test_psgi app => $app, client => sub {
	my $cb = shift;
	my $res;

	$res = $cb->( GET '/lib/test.txt' );
	is $res->code, 200, 'requesting test.txt succeeds';
	is $res->content, 'This is only a test.', '... with the expected content';
	is $res->content_type, 'text/plain', '... and the expected MIME type';
	is +( $res->content_type )[1], 'charset=us-ascii', '... with the expected charset';

	$res = $cb->( GET '/basic.t' );
	is $res->code, 200, 'requesting ourselves succeeds';
	like $res->content, qr/match this literal string/, '... with the expected content';
	is $res->content_type, 'basic', '... and the MIME type returned by path_info';

	$res = $cb->( GET '/lib/MockPSGIBodyFH.pm' );
	is $res->content_type, 'fake/fake', 'Plack::MIME is used by default';

	$res = $cb->( GET '/lib/test.js' );
	is $res->content, '// uncompressed', 'requests without compression headers work';
	is $res->header( 'Vary' ), 'Accept-Encoding', '... aside from Accept-Encoding being declared as a Vary criterion';

	$res = $cb->( GET '/lib/test.js', 'Accept-Encoding' => 'gzip' );
	is $res->content(), '// compressed', 'requests with compression headers get served from precompressed files';
	is $res->header( 'Vary' ), 'Accept-Encoding', '... with Accept-Encoding as a Vary criterion';
	is $res->header( 'Content-Encoding' ), 'gzip', '... and the right Content-Encoding';
	is $res->header( 'Content-Type' ), 'application/javascript', '... using the MIME type of the uncompressed file';

	$res = $cb->( GET '/lib/test.txt', 'Accept-Encoding' => 'gzip' );
	is $res->content(), 'This is only a test.', 'requests with compression headers but no precompressed file still get served';
	is $res->header( 'Content-Encoding' ), undef, '... with no Content-Encoding header';
	is $res->header( 'Vary' ), undef, '... and no Vary header';

	$res = $cb->( GET '/foo' );
	is $res->header( 'Vary' ), undef, 'failed and non-content requests are left alone';

	$res = $cb->( GET '/foo', 'Accept-Encoding' => 'gzip' );
	is $res->header( 'Vary' ), undef, '... even with compression request headers given';
};

done_testing;
