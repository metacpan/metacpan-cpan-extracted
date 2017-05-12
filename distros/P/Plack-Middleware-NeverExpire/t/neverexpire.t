use strict;
no warnings;
use Plack::Test;
use Plack::Builder;
use Test::More;
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

done_testing;
