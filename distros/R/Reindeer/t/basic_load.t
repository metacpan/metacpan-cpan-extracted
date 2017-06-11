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
BEGIN { pass 'TestClass compiled OK' }
pass 'TestClass built OK';
{
    package TestClass::Role;
    use Reindeer::Role;

    has two => (is => 'ro');
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

done_testing;
