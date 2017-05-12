#!/usr/bin/env perl
#
# This file is part of MooseX-AbstractMethod
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

# basically, a test suite to make sure my understanding of how the method MOP
# works is correct... and that it stays that way :)

use Test::More 0.82;
use Test::Moose;
use Moose::Util 'does_role';


{
    package Test::Trait::Method;
    use Moose::Role;
    use namespace::autoclean;

}

my $abstract_meta = Moose::Meta::Class->create_anon_class(
    superclasses => [ 'Moose::Meta::Method' ],
    roles        => [ 'Test::Trait::Method' ],
    cache        => 1,
);

{
    package foo;
    use Moose;

    sub _abstract {
        my $name = shift;

        my $method = $abstract_meta->name->wrap(sub { die },
                name         => $name,
                package_name => __PACKAGE__,
        );

        __PACKAGE__->meta->add_method($name => $method)
    }

    _abstract('dne');
    _abstract('dne2');
}
{
    package bar;
    use Moose;

    extends 'foo';

    sub dne { warn "now implemented!" }
}

use constant TESTTRAIT => 'Test::Trait::Method';

with_immutable {

    # base class
    my $foo_mmeta = foo->meta->get_method('dne');
    meta_ok('foo');
    does_ok($foo_mmeta, TESTTRAIT);

    with_immutable {

        # descendents
        my $bar_mmeta  = bar->meta->find_method_by_name('dne');
        my $dne2_mmeta = bar->meta->find_method_by_name('dne2');

        # method is overridden
        ok !does_role($bar_mmeta, TESTTRAIT), 'bar::dne does not do TESTTRAIT';;
        is 'bar', $bar_mmeta->original_package_name, 'bar::dne from bar';

        # method is not overridden
        ok does_role($dne2_mmeta, TESTTRAIT);
        is 'foo', $dne2_mmeta->original_package_name, 'bar::dne2 from foo';
    } qw{ bar };

} qw{ foo };

done_testing;
