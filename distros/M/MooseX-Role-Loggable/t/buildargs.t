#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

# making sure BUILDARGS doesn't fuck up object's method as well

{
    package Object;
    use Moo;
    with 'MooseX::Role::Loggable';
    has hello => ( is => 'ro' );
    sub BUILDARGS {
        my $class = shift;
        my %args  = @_;
        $args{'hello'} = 'What up!';
        return {%args};
    }
}

my $object = Object->new();
isa_ok( $object, 'Object' );
cmp_ok( $object->does('MooseX::Role::Loggable'), '==', 1, 'Role applied' );
can_ok( $object, 'hello' );
can_ok( $object, 'debug', 'log', 'log_debug' );
is( $object->hello, 'What up!', 'BUILDARGS not overwritten' );

done_testing;

