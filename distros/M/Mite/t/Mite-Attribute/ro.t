#!/usr/bin/perl

use lib 't/lib';
use Test::Mite;

use Mite::Attribute;

after_case "Create a class to test with" => sub {
    package Foo;

    sub new {
        my $class = shift;
        bless { @_ }, $class
    }

    eval Mite::Attribute->new(
        name    => 'foo',
        is      => 'ro',
    )->compile;
};

tests "Basic read-only" => sub {
    my $obj = new_ok 'Foo', [foo => 23];
    is $obj->foo, 23;
    throws_ok { $obj->foo("Flower child") }
        qr{(foo is a read-only attribute of Foo|Usage: Foo::foo\(self\))};
};

tests "Various tricky values" => sub {
    my $obj = new_ok 'Foo', [foo => undef];
    is $obj->foo, undef;

    $obj = new_ok 'Foo', [foo => 0];
    is $obj->foo, 0;

    $obj = new_ok 'Foo', [foo => ''];
    is $obj->foo, '';
};

done_testing;
