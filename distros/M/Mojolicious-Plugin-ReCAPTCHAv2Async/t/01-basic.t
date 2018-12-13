use strict;
use warnings;
use Test::Mojo;
use Test::More;

require_ok( 'Mojolicious::Plugin::ReCAPTCHAv2Async' ) or BAIL_OUT("Can't load module");

done_testing;
