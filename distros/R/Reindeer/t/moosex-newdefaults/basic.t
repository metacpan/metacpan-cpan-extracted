#!/usr/bin/env perl
#
# This file is part of Reindeer
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

use strict;
use warnings;

use Test::More;
use Test::Moose;

# This is more of a "spot check" than an actual set of tests

{
    package TestClass;
    use Reindeer;

    has oneA => (is => 'ro');
    has oneB => (is => 'ro', isa => Str);

    has oneC => (is => 'lazy');
    has oneD => (is => 'rw', isa => NonEmptySimpleStr);

    my $i;
    $i++;
}
{
    package TestClass::Role;
    use Reindeer::Role;

    has two => (is => 'ro');
}
{
    package TestClass::Two;
    use Reindeer;
    extends 'TestClass';
    with 'TestClass::Role';

    default_for oneA => 'boo!';
    default_for two  => 'boo!';
}

# make sure classes behave as we expect
with_immutable {

    has_attribute_ok('TestClass::Two', $_) for qw{ oneA two };
    my %atts = map { $_ => TestClass::Two->meta->get_attribute($_) } qw{ oneA two };

    for my $name (sort keys %atts) {

        ok $atts{$name}->has_default, "$name has a default";
        is $atts{$name}->default, 'boo!', "${name}'s default is correct";
    }

} qw{ TestClass::Two };

done_testing;
