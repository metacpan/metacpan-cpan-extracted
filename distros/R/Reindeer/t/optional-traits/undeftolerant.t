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
use Test::Moose::More 0.009;

use Test::Requires {
    'MooseX::UndefTolerant::Attribute' => 0,
};

# Validate that the trait is applied

{ package TestClass;          use Reindeer;       has one => (traits => [UndefTolerant], is => 'ro'); }
{ package TestClass::Role;    use Reindeer::Role; has one => (traits => [UndefTolerant], is => 'ro'); }
{ package TestClass::Compose; use Reindeer;       with 'TestClass::Role';                   }

for my $class (qw{ TestClass TestClass::Compose }) {

    with_immutable {
        validate_class $class => (
            attributes => [ one => { does => [ 'MooseX::UndefTolerant::Attribute' ] } ],
        );
    } $class;
}

done_testing;
