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
use Test::Fatal;
use Test::Moose::More 0.006;

# This is more of a "spot check" than an actual set of tests

{ package TestClass; use Reindeer; }

with_immutable {

    validate_class TestClass => (
        does       => [ qw{ MooseX::Traitor  } ],
    );

} 'TestClass';

done_testing;
