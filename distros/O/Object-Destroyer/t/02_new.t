#!/usr/bin/perl

##
## Test for constructor of Object::Destroyer
##

use strict;
BEGIN {
    $|  = 1;
    $^W = 1;
}

use Test::More tests => 19;
use Object::Destroyer 2.01;

my $foo = Foo->new;
my $bar = Bar->new;

##
## Object::destroyer->new($object)
## $object must have 'DESTROY' method
##
ok( Object::Destroyer->new($foo) );
ok( !eval{ Object::Destroyer->new($bar); 1; } );
like( $@, qr/Object::Destroyer requires that Bar has a DESTROY method at.*/ );

##
## Object::Destroyer->new($object, $method)
## $object must have method $method
##
ok( Object::Destroyer->new($foo, 'hello') );
ok( Object::Destroyer->new($foo, 'DESTROY') );
ok( Object::Destroyer->new($foo, 'release') );
ok( Object::Destroyer->new($bar, 'delete') );

##
## Negative tests: non-existent methods, extra params to constructor
## and no method names
##
ok( !eval{ Object::Destroyer->new($foo, 'BAZ'); 1; } );
like( $@, qr/^Object::Destroyer requires that Foo has a BAZ method at.*/ );
ok( !eval{ Object::Destroyer->new($foo, 'hello', 'hello'); 1; } );
like( $@, qr/^Extra arguments to constructor at.*/  );
ok( !eval{ Object::Destroyer->new($foo,  $foo); 1; } );
like( $@, qr/^Second argument to constructor must be a method name*/ );


##
## Object::Destroyer->new($codereference);
##
ok( Object::Destroyer->new(sub {}) );
ok( Object::Destroyer->new(\&Foo::hello) );

##
## Negative tests - extra params lead to die()
##
ok( !eval{ Object::Destroyer->new(sub {}, 'extra'); 1;} );
like( $@, qr/^Extra arguments to constructor at.*/ );

##
## Unknown arguments to constructor leads to die
##
ok( !eval{ Object::Destroyer->new('extra'); 1;} );
like( $@, qr/^You should pass an object or code reference to constructor at .*/ );





#####################################################################
# Test Classes

package Foo;

sub new {
    my $self = shift;
    return bless {}, ref $self || $self;
}

sub hello { }
sub release { }

sub DESTROY { }

package Bar;

sub new {
    my $self = shift;
    return bless {}, ref $self || $self;
}

sub delete { }

1;
