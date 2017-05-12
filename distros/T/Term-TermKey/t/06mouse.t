#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use Term::TermKey;

my $tk = Term::TermKey->new_abstract( "vt100", 0 );

$tk->push_bytes( "\e[M \"#" );

my $key;
is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after mouse press' );

ok( $key->type_is_mouse,  '$key->type_is_mouse after mouse press' );

is( $key->mouseev, MOUSE_PRESS, '$key->mouseev after mouse press' );
is( $key->button,  1,           '$key->button after mouse press' );
is( $key->line,    3,           '$key->line after mouse press' );
is( $key->col,     2,           '$key->col after mouse press' );
