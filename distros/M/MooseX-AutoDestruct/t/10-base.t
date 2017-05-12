#!/usr/bin/env perl
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
        is => 'rw', predicate => 'has_two', ttl => 5, clearer => 'clear_two',
    );
}

with_immutable {

    my $tc = TestClass->new;

    isa_ok $tc, 'TestClass';
    meta_ok $tc;

    has_attribute_ok $tc, 'one';
    has_attribute_ok $tc, 'two';

    # basic autodestruct checking
    ok !$tc->has_two, 'no value for two yet';
    $tc->two('w00t');
    ok $tc->has_two, 'two has value';
    is $tc->two, 'w00t', 'two value set correctly';
    diag 'sleeping';
    sleep 8;
    ok !$tc->has_two, 'no value for two (autodestruct)';

    # check our generated clearer
    $tc->two('w00t');
    ok $tc->has_two, 'two has value';
    is $tc->two, 'w00t', 'two value set correctly';
    $tc->clear_two;
    ok !$tc->has_two, 'no value for two (clearer method)';

} 'TestClass';

done_testing;
