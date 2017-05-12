use strict;

package Salvation::_t00_02::Class;

package main;

use Test::More tests => 1;

use Salvation::Stuff '&load_class';

ok( &load_class( 'Salvation::_t00_02::Class' ) );

