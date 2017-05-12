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

# make sure methods installed from attributes (accessors and the like) satisfy
# our abstract requirement

use Test::More 0.82;
use Test::Moose;
use Moose::Util 'does_role';

{
    package foo;
    use Moose;
    use namespace::autoclean;
    use MooseX::AbstractMethod;

    requires 'one';
}
{
    package bar;
    use Moose;

    extends 'foo';

    has one => (is => 'ro');
}


with_immutable {

    meta_ok('foo');

    with_immutable {

        meta_ok('bar');
        isa_ok(bar->meta->get_method('one'), 'Moose::Meta::Method::Accessor');

    } qw{ bar };

} qw{ foo };

done_testing;
