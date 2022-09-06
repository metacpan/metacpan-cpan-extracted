use strict; no warnings;

use Test::More tests => 2;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hi' ] ] };

$app = builder {
	enable 'NeverExpire';
	$app;
};

test_psgi app => $app, client => sub {
	my $cb = shift;
	my $res = $cb->( GET 'http://localhost/' );
	ok $res->header( 'Expires' ), 'Expires header is added';
	like $res->header( 'Cache-Control' ), qr/max-age=\d+, public/, 'Cache-Control header is added';
};
