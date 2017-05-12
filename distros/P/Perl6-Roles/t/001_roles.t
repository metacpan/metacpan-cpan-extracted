use strict;
use warnings;

use Test::More tests => 71;

my $CLASS = 'Perl6::Roles';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

package bark;

use base 'Perl6::Roles';

sub talk {
    return 'woof';
}

package animal;

use base 'Perl6::Roles';

sub eat {
    return 'munch';
}

sub sleep {
    return 'zzz';
}

package Dog;

use Perl6::Roles;

bark->apply( __PACKAGE__ );
animal->apply( __PACKAGE__ );

sub new {
    return bless {}, shift;
}

sub wag {
    return 'tail';
}

sub eat {
    return 'slobber';
}

package Doberman;
use base 'Dog';

package Doberman::Pinscher;
use base 'Doberman';

package No::Roles;

package No::Roles::Child;
use base 'No::Roles';

package main;

foreach my $dog ( qw( Dog Doberman Doberman::Pinscher ) ) {
    can_ok( $dog, qw( eat wag ) );
    can_ok( $dog, qw( talk ) );
    can_ok( $dog, qw( eat sleep ) );

    ok( $dog->does( $dog ), "$dog does $dog" );
    ok( $dog->does( 'animal' ), "$dog does animal" );
    ok( $dog->does( 'bark' ), "$dog does bark" );

    is( $dog->wag, 'tail', "Method without a role is ok" );
    is( $dog->eat, 'slobber', "Method in a class is not overridden" );
    is( $dog->sleep, 'zzz', "Method from animal ok" );
    is( $dog->talk, 'woof', "Method from bark ok" );

    my $obj = $dog->new;

    can_ok( $obj, qw( eat wag ) );
    can_ok( $obj, qw( talk ) );
    can_ok( $obj, qw( eat sleep ) );

    ok( $obj->does( $dog ), "$dog object does $dog" );
    ok( $obj->does( 'animal' ), "$dog object does animal" );
    ok( $obj->does( 'bark' ), "$dog object does bark" );

    is( $obj->wag, 'tail', "Method without a role is ok" );
    is( $obj->eat, 'slobber', "Method in a class is not overridden" );
    is( $obj->sleep, 'zzz', "Method from animal ok" );
    is( $obj->talk, 'woof', "Method from bark ok" );
}

ok( Doberman->does( 'Dog' ), 'child class does the parent class' );
ok( Doberman->new->does( 'Dog' ), 'child object does the parent class' );

ok( Doberman::Pinscher->does( 'Doberman' ), 'child class does the parent class' );
ok( Doberman::Pinscher->new->does( 'Doberman' ), 'child object does the parent class' );
ok( Doberman::Pinscher->does( 'Dog' ), 'grandchild class does the parent class' );
ok( Doberman::Pinscher->new->does( 'Dog' ), 'grandchild object does the parent class' );

ok( !No::Roles->does( 'Dog' ), "Check the failure case for does()" );
ok( !No::Roles::Child->does( 'Dog' ), "Check the failure case for does( child )" );

package Bad::Role;
use base 'animal';

package This::Should::Crash;

eval {
    Bad::Role->apply(__PACKAGE__);    
};
Test::More::ok($@, "... this should die because Bad::Role isn't a valid role");

package Bad::Role2;

use base 'Perl6::Roles', 'Dog';

package This::Should::Crash2;

eval {
    Bad::Role2->apply(__PACKAGE__);    
};
Test::More::ok($@, "... this should die because Bad::Role2 isn't a valid role");
