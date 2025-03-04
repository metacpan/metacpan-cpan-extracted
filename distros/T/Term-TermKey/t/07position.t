#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Term::TermKey;

my $tk = Term::TermKey->new_abstract( "vt100", 0 );

$tk->push_bytes( "\e[?3;5R" );

my $key;
is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after cursor position report' );

ok( $key->type_is_position,  '$key->type_is_position after cursor position report' );

is( $key->line, 3, '$key->line after cursor position report' );
is( $key->col,  5, '$key->col after cursor position report' );

done_testing;
