#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 28;
use Test::Moose;


{
    package MyTestRole;
    use Moose::Role;
    use MooseX::Aliases;

    has foo => (
        is      => 'rw',
        alias   => 'bar',
    );

    has baz => (
        is      => 'rw',
        init_arg => undef,
        alias   => [qw/quux quuux/],
    );
}

{
    package MyTest;
    use Moose;
    with 'MyTestRole';
}

with_immutable {

    my $test1 = MyTest->new(foo => 'foo', baz => 'baz');
    is($test1->foo, 'foo', 'Attribute set with default init_arg');
    is($test1->baz, undef, 'Attribute set with default init_arg (undef)');

    $test1->baz('baz');
    is($test1->baz, 'baz',
       'Attribute set with default writer, read with default reader');
    is($test1->quux, 'baz',
       'Attribute set with default writer, read with aliased reader');

    $test1->quux('quux');
    is($test1->baz, 'quux', 'Attribute set with aliased writer');
    is($test1->quux, 'quux', 'Attribute set with aliased writer');

    my $test2 = MyTest->new(bar => 'foo', baz => 'baz');
    is($test2->foo, 'foo', 'Attribute set wtih aliased init_arg');
    is($test2->baz, undef, 'Attribute set with default init_arg (undef)');

    $test2->baz('baz');
    is($test2->baz, 'baz',
       'Attribute set with default writer, read with default reader');
    is($test2->quux, 'baz',
       'Attribute set with default writer, read with aliased reader');

    $test2->quux('quux');
    is($test2->baz, 'quux', 'Attribute set with aliased writer');
    is($test2->quux, 'quux', 'Attribute set with aliased writer');

    my $foo = MyTest->meta->find_attribute_by_name('foo');
    is($foo->init_arg, 'foo', 'Attribute has correct init_arg');

    my $baz = MyTest->meta->find_attribute_by_name('baz');
    is($baz->init_arg, undef, 'Attribute has correct init_arg');
} 'MyTest';

