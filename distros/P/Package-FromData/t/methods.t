#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 21;
use Package::FromData;
use Test::Exception;

my $data = {
    'Foo' => { constructors => ['new'] },
    'Test::Package' => {
        constructors => ['new'],
        methods => {
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

my $test = Test::Package->new;
isa_ok $test, 'Test::Package';

is $test->constant(),   '42';
is $test->constant(12), '42';

is $test->add(1,1), '2';
is $test->add(2,2), '4';
throws_ok { $test->add(3,3) }
  qr/add cannot handle \[3 3\] as input/;

is $test->subtract(), 42;
is $test->subtract(1, 2), '-1';
is $test->subtract(2, 1), '1';
is $test->subtract(2, 2), 42;

is $test->reftest(), 'fallback';
is $test->reftest({foo => 'bar'}), 'foo bar';
is $test->reftest([foo => 'baz']), 'foo baz';

is_deeply [$test->list(1,2)], [1,2];
is_deeply [$test->list(1337)], [3,4];
is $test->list(1,2), 1;
is $test->list(1337), 3;

isa_ok Foo->new(), 'Foo';
isa_ok $test->new_foo(123), 'Foo';

is_deeply [$test->context(1,2)], [1,2,3,4];
is $test->context(1,2), 3;
