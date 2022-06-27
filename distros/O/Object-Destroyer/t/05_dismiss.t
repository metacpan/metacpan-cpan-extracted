#!/usr/bin/perl

##
## Test for wrapping abilities of Object::Destroyer
##

use strict;
use warnings;

use Test::More;
use Object::Destroyer;


SCOPE: {
    my $foo = Foo->new;
}
is($Foo::destroy_counter, 0, 'Foo must not be destroyed');

SCOPE: {
    my $foo = Foo->new;
    my $sentry = Object::Destroyer->new($foo, 'release');
    is($Foo::destroy_counter, 0, 'Pre-check');
    ok( $sentry->self_test, 'Wrapper is ok');
}
is($Foo::destroy_counter, 1, 'Foo must be destroyed');

$Foo::destroy_counter = 0;
SCOPE: {
    my $foo = Foo->new;
    my $sentry = Object::Destroyer->new($foo, 'release');
    is($Foo::destroy_counter, 0, 'Pre-check');
    ok( $sentry->self_test, 'Wrapper is ok' );
    $sentry->dismiss;
    ok( $sentry->self_test, 'Wrapper is still ok');
}
is($Foo::destroy_counter, 0, 'Foo must not ve destroyed');

done_testing;



#####################################################################
# Test Classes

package Foo;

use vars qw{$destroy_counter @ISA};
BEGIN { $destroy_counter = 0; };

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $self = bless {}, $class;
    $self->{self} = $self; ## This is a circular reference
    return $self;
}

sub self_test{
    my $self = shift;
    return $self==$self->{self};
}

sub DESTROY {
    $destroy_counter++;
}

sub release{
    my $self = shift;
    undef $self->{self};
}
