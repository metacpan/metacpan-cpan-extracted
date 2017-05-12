#!/usr/bin/perl
#
# This file is part of MooseX-AutoDestruct
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

=head1 DESCRIPTION

This test exercises some basic attribute functionality, to make sure things
are working "as advertized" with the AutoDestruct trait.

This is probably redundant against the main Moose test suite, but it doesn't
hurt to check it a little bit here as well.

=cut

use strict;
use warnings;

use Test::More;
use Test::Moose;

{
    package TestClass;
    use Moose;
    use MooseX::AutoDestruct;

    has one => (is => 'ro', isa => 'Str');

    has two => (
        traits => ['AutoDestruct'],
        is => 'rw', predicate => 'has_two', ttl => 5,
        lazy => 1, builder => '_build_two',
    );

    sub _build_two { 'foo' }
}

with_immutable {

    my $tc = TestClass->new;

    isa_ok $tc, 'TestClass';
    meta_ok $tc;

    has_attribute_ok $tc, 'one';
    has_attribute_ok $tc, 'two';

    # basic autodestruct checking
    for my $i (1..2) {

        ok !$tc->has_two, 'no value for two yet';
        is $tc->two, 'foo', 'two value set correctly';
        ok $tc->has_two, 'two has value';
        diag 'sleeping';
        sleep 8;
        ok !$tc->has_two, 'no value for two (autodestruct)';
    }

} 'TestClass';

done_testing;
