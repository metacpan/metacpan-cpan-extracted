use strict;
use warnings;

use Test::More tests => 19;

my $CLASS = 'Perl6::Roles';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

# create 2 roles

{
    package rFoo;
    use base 'Perl6::Roles';
    
    sub foo { 'rFoo::foo' }
}

{
    package rBar;
    use base 'Perl6::Roles';  
}

# combine them into a third role

{
    package rFooBar;

    use base 'Perl6::Roles';
    
    rFoo->apply(__PACKAGE__);
    rBar->apply(__PACKAGE__);    
}

ok(rFoo->isa('Perl6::Roles'), '... rFoo isa Perl6::Roles');
ok(rBar->isa('Perl6::Roles'), '... rBar isa Perl6::Roles');
ok(rFooBar->isa('Perl6::Roles'), '... rFooBar isa Perl6::Roles');
ok( !rFooBar->isa( 'rFoo' ), "... but rFooBar isn't a rFoo" );
ok( !rFooBar->isa( 'rBar' ), "... nor is it an rBar" );

ok(rFoo->does('rFoo'), '... rFoo does rFoo');
ok(rBar->does('rBar'), '... rBar does rBar');
ok(rFooBar->does('rFoo'), '... rFooBar does rFoo');
ok(rFooBar->does('rBar'), '... rFooBar does rBar');
ok(rFooBar->does('rFooBar'), '... rFooBar does rFooBar');

# create another role

{
    package rBaz;
    use base 'Perl6::Roles';  
    
    rFoo->apply(__PACKAGE__);
}

ok(rBaz->isa('Perl6::Roles'), '... rBaz isa Perl6::Roles');

ok(rBaz->does('rFoo'), '... rBaz does rFoo');
ok(rBaz->does('rBaz'), '... rBaz does rBaz');

# now test our composition method

# The role below (rFooBarBaz) will be getting rFoo twice, first
# from the rFooBar role, and then from rBaz role. If roles are 
# not composed properly (see above), this will cause a method 
# conflict to arise since rBaz and rFooBar will seem to both 
# have a copy of &foo. 
#
# Roles should *never* be composed into one another, and in fact, 
# they should only be composed at the very last possible moment.
#
# The roles (and subroles) being composed need to be linearized 
# into a list of unique roles (ordering is unimportant), and then
# composed into the class itself (following the method compostion
# rules).

{
    package FooBarBaz;

    eval {
        rFooBar->apply(__PACKAGE__);
        rBaz->apply(__PACKAGE__);    
    };
    Test::More::ok(!$@, '... this should not create a conflict');
}

ok(FooBarBaz->does('rFoo'), '... FooBarBaz does rFoo');
ok(FooBarBaz->does('rBar'), '... FooBarBaz does rBar');
ok(FooBarBaz->does('rFooBar'), '... FooBarBaz does rFooBar');
ok(FooBarBaz->does('rBaz'), '... FooBarBaz does rBaz');
