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
use Test::Moose;

# This is more of a "spot check" than an actual set of tests

{
    package TestClass;
    use Reindeer;

    has oneA => (is => 'ro');
    has oneB => (is => 'ro', isa => 'Str');
}

with_immutable {

    my $dies  = exception { TestClass->new(oneA => 1, bad  => 'xxx' ) };
    my $lives = exception { TestClass->new(oneA => 1, oneB => 'xxx' ) };
    like(
        $dies,
        qr/unknown attribute.+: bad/,
        'strict constructor blows up on unknown params'
    );

    is $lives, undef, 'with proper args passes';

} 'TestClass';

done_testing;
