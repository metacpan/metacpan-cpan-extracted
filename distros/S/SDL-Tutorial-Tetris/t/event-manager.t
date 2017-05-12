#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan tests => 6;

use_ok('SDL::Tutorial::Tetris::EventManager');

my $evt_manager = SDL::Tutorial::Tetris::EventManager->new();

can_ok( $evt_manager, 'reg_listener' );

# let's register a few listeners

$evt_manager->reg_listener('foo');
$evt_manager->reg_listener('bar');

# can we retrieve these listeners?

ok( defined $evt_manager->listeners->{foo} );
ok( defined $evt_manager->listeners->{bar} );

# can we unregister these listeners?

$evt_manager->un_reg_listener('foo');
$evt_manager->un_reg_listener('bar');

ok( !defined $evt_manager->listeners->{foo} );
ok( !defined $evt_manager->listeners->{bar} );
