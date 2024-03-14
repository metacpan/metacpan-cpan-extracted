use strict; use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::File::Precompressed;
use Plack::Middleware::Static::Precompressed;

test_psgi(
	app => Plack::App::File::Precompressed->new,
	client => sub {
		my $cb = shift;
		my $res = $cb->( GET '/non/existent.txt' );
		is $res->code, 404, 'the app returns 404 for non-existent URLs';
	},
);

test_psgi(
	app => Plack::Middleware::Static::Precompressed->wrap( sub { [ 202, [], [] ] } ),
	client => sub {
		my $cb = shift;
		my $res = $cb->( GET '/non/existent.txt' );
		is $res->code, 202, '... whereas the middleware falls through';
	},
);

done_testing;
