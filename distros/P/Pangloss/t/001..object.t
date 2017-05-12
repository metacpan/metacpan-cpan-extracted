#!/usr/bin/perl

##
## Tests for Pangloss::Object
##

use blib;
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok("Pangloss::Object") }
BEGIN { use_ok("accessors") }

ok( $Pangloss::Object::VERSION, 'version' );

my $test = new Test::Object;
isa_ok( $test, 'Test::Object', 'new' );
is    ( $test->{init}, 1,      'init');

is( $test->test(1), $test, 'accessor test(set)' );
is( $test->test,    1,     'accessor test(get)' );

BEGIN {
package Test::Object;
use base qw( Pangloss::Object );
use accessors qw( test );
sub init {
    my $self = shift;
    $self->{init} = 1;
}
};
