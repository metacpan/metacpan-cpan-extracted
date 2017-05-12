#!perl -T

use Plack::Middleware::HTMLMinify;
use Test::More;

use_ok('Plack::Middleware::HTMLMinify');

done_testing;
