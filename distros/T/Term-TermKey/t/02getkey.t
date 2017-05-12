#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 31;
use Test::Refcount;

use Term::TermKey;

my $tk = Term::TermKey->new_abstract( "vt100", 0 );

is_oneref( $tk, '$tk has refcount 1 initially' );

my $buffsize = $tk->get_buffer_size;
cmp_ok( $buffsize, '>', 0, 'get_buffer_size > 0' );

is( $tk->get_buffer_remaining, $buffsize, "get_buffer_remaining initially $buffsize" );

my $key;

is( $tk->getkey( $key ), RES_NONE, 'getkey yields RES_NONE when empty' );

ok( defined $key, '$key is defined' );

is_oneref( $key, '$key has refcount 1 after getkey()' );
is_refcount( $tk, 2, '$tk has refcount 2 after getkey()' );

is( $tk->push_bytes( "h" ), 1, 'push_bytes consumes 1 byte' );

is( $tk->get_buffer_remaining, $buffsize - 1, 'get_buffer_remaining after push_bytes' );

is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after h' );

is( $key->termkey, $tk, '$key->termkey after h' );

ok( $key->type_is_unicode,     '$key->type_is_unicode after h' );
is( $key->codepoint, ord("h"), '$key->codepoint after h' );
is( $key->modifiers, 0,        '$key->modifiers after h' );

is( $key->utf8, "h", '$key->utf8 after h' );

is( $key->format( 0 ), "h", '$key->format after h' );

is( $tk->get_buffer_remaining, $buffsize, 'get_buffer_remaining getkey' );

is( $tk->getkey( $key ), RES_NONE, 'getkey yields RES_NONE a second time' );

$tk->push_bytes( "\cA" );

is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after C-a' );

ok( $key->type_is_unicode,        '$key->type_is_unicode after C-a' );
is( $key->codepoint, ord("a"),    '$key->codepoint after C-a' );
is( $key->modifiers, KEYMOD_CTRL, '$key->modifiers after C-a' );

is( $key->format( 0 ), "C-a", '$key->format after C-a' );

$tk->push_bytes( "\eOA" );

is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after Up' );

ok( $key->type_is_keysym,              '$key->type_is_keysym after Up' );
is( $key->sym, $tk->keyname2sym("Up"), '$key->keysym after Up' );
is( $key->modifiers, 0,                '$key->modifiers after Up' );

is( $key->format( 0 ), "Up", '$key->format after Up' );

is_oneref( $key, '$key has refcount 1 before dropping' );
is_refcount( $tk, 2, '$tk has refcount 2 before dropping key' );

undef $key;

is_oneref( $tk, '$k has refcount 1 before EOF' );
