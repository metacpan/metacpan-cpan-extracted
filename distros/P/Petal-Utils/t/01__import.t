#!/usr/bin/perl

##
## Tests for Petal::Utils->import
##

use blib;
use strict;
#use warnings;

use Test::More qw(no_plan);
use Carp;

# use_ok() doesn't let us avoid calling import() so:
eval 'use Petal::Utils qw();';
is( $@, '', 'use Petal::Utils' );

eval 'use Petal::Utils qw( :none );';
is( $@, '', 'use set :none' );

eval 'use Petal::Utils qw( :default );';
is( $@, '', 'use set :default' );

eval 'use Petal::Utils qw( UpperCase );';
is( $@, '', 'use plugin UpperCase' );

{
    no warnings;
    eval 'use Petal::Utils qw( :non_existent );';
    isnt( $@, '', 'error loading non-existent set' );

    eval 'use Petal::Utils qw( non_existent );';
    isnt( $@, '', 'error loading non-existent plugin' );
}
