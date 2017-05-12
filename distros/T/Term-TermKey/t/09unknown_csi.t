#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

use Term::TermKey;

my $tk = Term::TermKey->new_abstract( "vt100", 0 );

$tk->push_bytes( "\e[>1;2v" );

my $key;
is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after unrecognised CSI > v' );

ok( $key->type_is_unknown_csi,  '$key->type_is_unknown_csi after unrecognised CSI > v' );

my ( $cmd, @args ) = $tk->interpret_unknown_csi( $key );

is( $cmd, ">v", '$cmd for unrecognised CSI > v' );
is_deeply( \@args, [ 1, 2 ], '@args for unrecognised CSI > v' );

$tk->push_bytes( "\e[?4; w" );

is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after unrecognised CSI ? Sp w' );
( $cmd, @args ) = $tk->interpret_unknown_csi( $key );

is( $cmd, "? w", '$cmd for unrecognised CSI ? Sp w' );
is_deeply( \@args, [ 4 ], '@args for unrecognised CSI ? Sp w' );
