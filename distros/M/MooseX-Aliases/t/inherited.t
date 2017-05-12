#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;
use Test::Moose;

{
    package Foo;
    use Moose;

    sub foo { ref(shift) }
}

{
    package Bar;
    use Moose;
    use MooseX::Aliases;
    extends 'Foo';
    alias bar => 'foo';
}

with_immutable {
    can_ok('Bar', 'bar');
    my $bar_method = Bar->meta->get_method('bar');
    is($bar_method->package_name, 'Bar',
       'alias reports being from the correct package');
    is($bar_method->original_package_name, 'Bar',
       'alias reports being originally from the correct package');
    my $foo_method = $bar_method->package_name->meta->find_method_by_name($bar_method->aliased_from);
    is($foo_method->package_name, 'Foo',
       'aliased_from method has the correct package');
    is($foo_method->original_package_name, 'Foo',
       'aliased_from method has the correct original package');
} 'Foo', 'Bar';
