#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;
use Package::FromData;

my $data = {
    'Test::Package' => {
        variables => {
            '@FOO' => [qw/this is foo/],
            '%FOO' => {this => 'is', foo => '!'},
            '$FOO' => 'this is foo',
        },
    },
};

create_package_from_data($data);

is_deeply [@Test::Package::FOO], [qw/this is foo/];
is_deeply {%Test::Package::FOO}, {this => 'is', foo => '!'};
is $Test::Package::FOO, 'this is foo';
