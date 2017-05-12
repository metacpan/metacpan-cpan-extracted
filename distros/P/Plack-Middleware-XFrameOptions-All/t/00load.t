#!perl -T

use Plack::Middleware::XFrameOptions::All;
use Test::More;

use_ok('Plack::Middleware::XFrameOptions::All');

done_testing;
