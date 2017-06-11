#!/usr/bin/env perl
#
# This file is part of Reindeer
#
# This software is Copyright (c) 2017, 2015, 2014, 2012, 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;

use Test::More;
use Test::Moose;

use Test::Requires {
    'MooseX::AutoDestruct' => '0.009',
};

# This is more of a "spot check" than an actual set of tests

{
    package TestClass;
    use Reindeer;

    has one => (traits => [AutoDestruct], is => 'ro', ttl => 400);

}
BEGIN { pass 'TestClass compiled OK' }
pass 'TestClass built OK';
{
    package TestClass::Role;
    use Reindeer::Role;

    has one => (traits => [AutoDestruct], is => 'ro', ttl => 400);
}
BEGIN { pass 'TestClass::Role compiled OK' }
pass 'TestClass::Role built OK';
{
    package TestClass::Compose;
    use Reindeer;
    with 'TestClass::Role';
}
BEGIN { pass 'TestClass::Compose compiled OK' }
pass 'TestClass::Compose built OK';

for my $class (qw{ TestClass TestClass::Compose }) {

    with_immutable {
        meta_ok($class);
        has_attribute_ok($class, 'one');

        my $attmeta = $class->meta->get_attribute('one');
        does_ok($attmeta, 'MooseX::AutoDestruct::Trait::Attribute');
    } $class;
}

done_testing;
