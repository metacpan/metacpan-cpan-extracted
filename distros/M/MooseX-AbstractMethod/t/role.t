#!/usr/bin/env perl
#
# This file is part of MooseX-AbstractMethod
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

# make sure we don't mess with Moose::Role's require, and simply pass off
# our abstract requirement

use Test::More 0.82;
use Test::Moose;
use Moose::Util 'does_role';
use Test::Fatal;

{
    package TestClass::Role;
    use Moose::Role;
    use namespace::autoclean;
    use MooseX::AbstractMethod;

    requires 'one';
    #abstract 'two';
}
{
    package TestClass;
    use Moose;

    with 'MooseX::Traits';
    #with 'TestClass::Role';
}
#{
#    package TestClass::Role2;
#    use Moose::Role;

meta_ok('TestClass');
meta_ok 'TestClass::Role';

my $dies = exception { TestClass->with_traits('TestClass::Role') };

like
    $dies,
    qr/'TestClass::Role' requires the method 'one' to be implemented/,
    'TestClass + role correctly requires one()',
    ;

is_deeply
    [ TestClass::Role->meta->get_required_method_list ],
    [ 'one'                                           ],
    'TestClass::Role correctly passes to Moose::Role::require',
    ;

done_testing;
