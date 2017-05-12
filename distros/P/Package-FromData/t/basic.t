#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;

use ok 'Package::FromData';

lives_ok {
    create_package_from_data({'Foo::Bar' => {}});
};

throws_ok {
    create_package_from_data('foo');
} qr/please pass create/;

throws_ok {
    create_package_from_data(\my $foo);
} qr/please pass create/;

throws_ok {
    create_package_from_data({'Foo::Bar' => 'baz'});
} qr/must be a hashref/;

throws_ok {
    create_package_from_data({ '::not a package!!!' => {} });
} qr/invalid package name/;
