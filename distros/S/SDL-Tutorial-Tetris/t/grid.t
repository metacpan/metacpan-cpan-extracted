#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan tests => 4;

use_ok('SDL::Tutorial::Tetris::Model::Grid');

my $grid = SDL::Tutorial::Tetris::Model::Grid->new();

# is it correctly registered?
ok( defined $grid->evt_manager->listeners->{$grid} );

ok( defined $grid->{width}  );
ok( defined $grid->{height} );
