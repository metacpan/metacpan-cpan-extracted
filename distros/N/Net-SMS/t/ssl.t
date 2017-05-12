#!/usr/bin/perl -w

use Test::More tests => 3;
use LWP::UserAgent;

$http = LWP::UserAgent->new();

ok( defined $http,				"new test");
ok( $http->isa('LWP::UserAgent'), "class test" );
ok( $http->is_protocol_supported('https'), "ssl test" );

