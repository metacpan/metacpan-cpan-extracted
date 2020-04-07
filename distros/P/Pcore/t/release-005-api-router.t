#!/usr/bin/env perl

package main v0.1.0;

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;

        Test::More::plan( skip_all => 'these tests are for release candidate testing' );
    }
}

use Pcore;
use Test::More;
use Pcore::App::API::Auth;
use Pcore::App::Router;

my $router = bless {}, 'Pcore::App::Router';

my $test = [
    [ '/', '/' ],

    [ '/ap',      '/', 'ap' ],
    [ '/ap/',     '/', 'ap/' ],
    [ '/ap/path', '/', 'ap/path' ],

    [ '/api',  '/api' ],
    [ '/api/', '/api' ],
    [ '/api/path', '/api', 'path' ],

    [ '/api/ok',  '/api/ok' ],
    [ '/api/ok/', '/api/ok' ],
    [ '/api/ok/path', '/api/ok', 'path' ],

    [ '/api-path',      '/', 'api-path' ],
    [ '/api-path/',     '/', 'api-path/' ],
    [ '/api-path/path', '/', 'api-path/path' ],
];

our $TESTS = $test->@*;

plan tests => $TESTS;

my $re = $router->_build_re( [ keys { map { $_->[1] => undef } $test->@* }->%* ] );

for my $path ( $test->@* ) {
    $path->[0] =~ $re;

    ok( $1 eq $path->[1] && $2 eq ( $path->[2] // $EMPTY ), $path->[0] );
}

done_testing $TESTS;

1;
__END__
=pod

=encoding utf8

=cut
