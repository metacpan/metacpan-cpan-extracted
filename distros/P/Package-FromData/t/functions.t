#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 20;
use Package::FromData;
use Test::Exception;

my $data = {
    'Foo' => { constructors => ['new'] },
    'Test::Package' => {
        functions => {
            constant => '42',
            add      => [
                [1, 1] => '2',
                [2, 2] => '4',
            ],
            subtract  => [
                [1, 2] => '-1',
                [2, 1] => '1',
                42
            ],
            list => [
                [1, 2] => [1, 2],
                [3, 4]
            ],
            reftest => [
                [{foo => 'bar'}] => 'foo bar',
                [[qw/foo baz/]]  => 'foo baz',
                'fallback',
            ],
            new_foo => [ { new => 'Foo' } ],
            context => [
                [1,2] => { 
                    scalar => '3',
                    list   => [1,2,3,4],
                },
            ],
        },
    },
};

create_package_from_data($data);

is Test::Package::constant(),   '42';
is Test::Package::constant(12), '42';

is Test::Package::add(1,1), '2';
is Test::Package::add(2,2), '4';
throws_ok { Test::Package::add(3,3) }
  qr/add cannot handle \[3 3\] as input/;

is Test::Package::subtract(), 42;
is Test::Package::subtract(1, 2), '-1';
is Test::Package::subtract(2, 1), '1';
is Test::Package::subtract(2, 2), 42;

is Test::Package::reftest(), 'fallback';
is Test::Package::reftest({foo => 'bar'}), 'foo bar';
is Test::Package::reftest([foo => 'baz']), 'foo baz';

is_deeply [Test::Package::list(1,2)], [1,2];
is_deeply [Test::Package::list(1337)], [3,4];
is Test::Package::list(1,2), 1;
is Test::Package::list(1337), 3;

isa_ok Foo->new(), 'Foo';
isa_ok Test::Package::new_foo(123), 'Foo';

is_deeply [Test::Package::context(1,2)], [1,2,3,4];
is Test::Package::context(1,2), 3;
