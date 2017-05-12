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
use Test::Fatal;
use Test::Moose::More 0.004;

# This is more of a "spot check" than an actual set of tests

{
    package TestClass;
    use Reindeer;

    abstract 'abstract_method';
    requires 'another_abstract_method';
    requires 'should_be_implemented';
}
{
    package TestRole;
    use Reindeer::Role;

    abstract 'just_another_way_of_saying_requires';
}
{
    package TestClass::Two;
    use Reindeer;
    extends 'TestClass';
    sub should_be_implemented { 'hi there!' }
}

validate_class TestClass => (
    methods => [ qw{ abstract_method another_abstract_method } ],
    # XXX metaclass checks here when Test::Moose::More supports it
);

subtest 'abstracts from base class work as expected' => sub {

    my $lives = exception { TestClass->meta->make_immutable };
    my $dies  = exception { TestClass::Two->meta->make_immutable };

    is $lives, undef, 'TestClass lives on immutable';
    like
        $dies,
        qr/abstract methods have not been implemented/,
        'TestClass::Two dies on immutable w/o abstract impl'
        ;

    like $dies, qr/$_/, "$_ warning found" for
        'abstract_method .from TestClass.',
        'another_abstract_method .from TestClass.',
        ;

    unlike
        $dies,
        qr/should_be_implemented .from TestClass./,
        'should_be_implemented _not_ warned as abstract',
        ;
};

subtest 'role abstract/requires continues to work as expected' => sub {

    my $dies = exception { TestRole->meta->apply(TestClass::Two->meta) };

    like $dies,
        qr/'TestRole' requires the method 'just_another_way_of_saying_requires' to be implemented by 'TestClass::Two'/,
        'TestRole application dies',
        ;
};

done_testing;
