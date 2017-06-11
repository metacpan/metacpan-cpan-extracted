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
use Test::Moose::More;

# This is more of a "spot check" than an actual set of tests

my $with_self  = 0;
my $with_other = 0;

{
    package TestClass;
    use Reindeer;

    sub with_self  { $with_self++  if ref $_[1] eq 'TestClass::Delegatee' }
    sub with_other { $with_other++ if $_[1] == 5 }
}
{
    package TestClass::Delegatee;
    use Reindeer;

    sub other { 5 }

    has del => (

        is      => 'ro',
        isa     => 'TestClass',
        default => sub { TestClass->new() },

        handles => {

            to_with_self  => { with_self  => [ curry_to_self      ] },
            to_with_other => { with_other => [ sub { shift->other } ] },
        },
    );
}

with_immutable {

    validate_class TestClass => (
        methods => [ qw{ with_self with_other } ],
    );

    validate_class 'TestClass::Delegatee' => (
        attributes => [ qw{ del } ],
        methods    => [ qw{ other del to_with_self to_with_other } ],
    );

    my $tc = TestClass::Delegatee->new;

    $tc->to_with_self;
    $tc->to_with_other;
    is $with_self,  1, 'inc correctly';
    is $with_other, 1, 'inc correctly';

    $with_self = $with_other = 0;

} qw{ TestClass TestClass::Delegatee };

done_testing;
