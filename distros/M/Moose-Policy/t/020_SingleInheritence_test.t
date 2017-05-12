#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    require Moose;

    plan skip_all => 'Moose::Policy does not work with recent versions of Moose'
        if Moose->VERSION >= 1.05;

    plan tests => 2;

    use_ok('Moose::Policy');
}

{
    package Foo;
    use Moose::Policy 'Moose::Policy::SingleInheritence';
    use Moose;
    
    package Bar;
    use Moose::Policy 'Moose::Policy::SingleInheritence';
    use Moose;    

    extends 'Foo';
    
    package Baz;
    use Moose::Policy 'Moose::Policy::SingleInheritence';    
    use Moose;    
    
    ::dies_ok {
        extends 'Foo', 'Bar';
    } '... violating the policy';
}

