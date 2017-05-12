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

Note that we're directly accessing the attribute values here via the
metaclass, bypassing any installed accessors.

=cut

use strict;
use warnings;

# FIXME
use Test::More skip_all => 'Meta attribute tests incomplete';

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
    );

}

with_immutable {

    my $tc = TestClass->new;

    isa_ok $tc, 'TestClass';
    meta_ok $tc;

    has_attribute_ok $tc, 'one';
    has_attribute_ok $tc, 'two';

    my $two = $tc->meta->get_attribute('two');

    isa_ok $two => 'Moose::Meta::Attribute', 'two isan attribute metaclass';

    # some basic attribute tests
    has_attribute_ok $two, 'ttl';
    ok $two->has_ttl, 'two has a ttl';
    is $two->ttl => 5, 'ttl value is correct';

    # check with our instance
    ok !$two->has_value($tc), 'two has no value yet';
    $two->set_value($tc => 'w00t');
    is $two->get_value($tc), 'w00t', 'two set correctly';
    diag 'sleeping';
    sleep 8;
    ok !$two->has_value($tc), 'no value for two (autodestruct)';

    # check our clearer

} 'TestClass';

done_testing;
