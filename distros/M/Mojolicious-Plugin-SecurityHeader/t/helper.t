#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Mojolicious::Plugin::SecurityHeader;

my %tests = (
    _check_csp => [
        {
            input  => undef,
            result => '',
        },
        {
            input  => 1,
            result => '',
        },
        {
            input  => ['test'],
            result => '',
        },
        {
            input  => [],
            result => '',
        },
        {
            input  => {},
            result => '',
        },
        {
            input  => { object => '*' },
            result => 'object-src *; ',
        },
    ],
    _check_methods => [
        {
            input  => undef,
            result => undef,
        },
        {
            input  => 'get',
            result => 'GET',
        },
        {
            input  => 'GET',
            result => 'GET',
        },
        {
            input  => {'GET' => 1},
            result => undef,
        },
        {
            input  => [],
            result => undef,
        },
        {
            input  => [qw//],
            result => undef,
        },
        {
            input  => [undef],
            result => undef,
        },
        {
            input  => ['invalid'],
            result => undef,
        },
        {
            input  => [qw/GET/],
            result => 'GET',
        },
        {
            input  => [qw/GET post/],
            result => 'GET, POST',
        },
        {
            input  => [qw/GET post invalid/],
            result => 'GET, POST',
        },
        {
            input  => [qw/INVALID GET post/],
            result => 'GET, POST',
        },
        {
            input  => [qw/GET INVALID post/],
            result => 'GET, POST',
        },
    ],
    _check_list => [
        {
            input  => undef,
            result => undef,
        },
        {
            input  => 'get',
            result => 'get',
        },
        {
            input  => 'GET',
            result => 'GET',
        },
        {
            input  => {'GET' => 1},
            result => undef,
        },
        {
            input  => [qw//],
            result => undef,
        },
        {
            input  => [qw/GET/],
            result => 'GET',
        },
        {
            input  => [qw/GET post/],
            result => 'GET, post',
        },
        {
            input  => [qw/GET post invalid/],
            result => 'GET, post, invalid',
        },
        {
            input  => [qw/INVALID GET post/],
            result => 'INVALID, GET, post',
        },
    ],
    _check_xp => [
        {
            input  => 2,
            result => undef,
        },
        {
            input  => 1,
            result => 1,
        },
        {
            input  => undef,
            result => undef,
        },
        {
            input  => 0,
            result => 0,
        },
        {
            input  => [1],
            result => undef,
        },
        {
            input  => {},
            result => undef,
        },
        {
            input  => { value => 2 },
            result => undef,
        },
        {
            input  => { value => 1 },
            result => '1; ',
        },
        {
            input  => { value => 1, mode => 'test' },
            result => '1; ',
        },
        {
            input  => { value => 1, anything => 'test' },
            result => '1; ',
        },
        {
            input  => { value2 => 1 },
            result => undef,
        },
        {
            input  => { value => 1, mode => 'block' },
            result => '1; mode=block',
        },
        {
            input  => { value => 1, report => 'http://perl-services.de' },
            result => '1; report=http://perl-services.de',
        },
    ],
    _check_fo => [
        {
            input  => undef,
            result => 'DENY',
        },
        {
            input  => 'DENY',
            result => 'DENY',
        },
        {
            input  => 'SAMEORIGIN',
            result => 'SAMEORIGIN',
        },
        {
            input  => 'ANYTHING',
            result => undef,
        },
        {
            input  => ['TEST'],
            result => undef,
        },
        {
            input  => { test => 1 },
            result => undef,
        },
        {
            input  => { 'ALLOW-FROM' => undef },
            result => undef,
        },
        {
            input  => { 'ALLOW-FROM' => 0 },
            result => undef,
        },
        {
            input  => { 'ALLOW-FROM' => 1 },
            result => 'ALLOW-FROM 1',
        },
        {
            input  => { 'ALLOW-FROM' => 'http://perl-services.de' },
            result => 'ALLOW-FROM http://perl-services.de',
        },
    ],
    _check_sts => [
        {
            input  => -2,
            result => undef,
        },
    ],
    _is_int => [
        {
            input  => undef,
            result => undef,
        },
        {
            input  => -2,
            result => undef,
        },
        {
            input  => 0,
            result => 0,
        },
        {
            input  => 2,
            result => 2,
        },
        {
            input  => {},
            result => undef,
        },
        {
            input  => [],
            result => undef,
        },
        {
            input  => 'test',
            result => undef,
        },
    ],
);

for my $method ( sort keys %tests ) {
    my $sub = Mojolicious::Plugin::SecurityHeader->can( $method );

    my $cnt = 0;
    for my $method_test ( @{ $tests{$method} || [] } ) {
        my $check = $method_test->{result};
        my $input = $method_test->{input};

        my $result = $sub->( $input );
        is $result, $check, "$method - $cnt";

        $cnt++;
    }
}

done_testing();
