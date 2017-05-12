#!/usr/bin/perl
use Test::More;
use lib 'lib';
use Module::Pluggable search_path => [ 'Plack::App::ServiceStatus' ];

require_ok( $_ ) for sort 'Plack::App::ServiceStatus', __PACKAGE__->plugins;

done_testing();
