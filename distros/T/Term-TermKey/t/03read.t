#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use Test::Refcount;

use IO::Handle;

use Term::TermKey;

pipe( my ( $rd, $wr ) ) or die "Cannot pipe() - $!";

# Sanitise this just in case
$ENV{TERM} = "vt100";

is_oneref( $rd, '$rd has refcount 1 initially' );

my $tk = Term::TermKey->new( $rd, 0 );

is_oneref( $tk, '$tk has refcount 1 initially' );
is_refcount( $rd, 2, '$rd has refcount 2 after Term::TermKey->new' );

my $key;

is( $tk->getkey( $key ), RES_NONE, 'getkey yields RES_NONE when empty' );

ok( defined $key, '$key is defined' );

is_oneref( $key, '$key has refcount 1 after getkey()' );
is_refcount( $tk, 2, '$tk has refcount 2 after getkey()' );

$wr->syswrite( "h" );

is( $tk->getkey( $key ), RES_NONE, 'getkey yields RES_NONE before advisereadable' );

$tk->advisereadable;

is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after h' );

is( $key->termkey, $tk, '$key->termkey after h' );

ok( $key->type_is_unicode,     '$key->type_is_unicode after h' );
is( $key->codepoint, ord("h"), '$key->codepoint after h' );
is( $key->modifiers, 0,        '$key->modifiers after h' );

is( $key->utf8, "h", '$key->utf8 after h' );

is( $key->format( 0 ), "h", '$key->format after h' );

is( $tk->getkey( $key ), RES_NONE, 'getkey yields RES_NONE a second time' );

undef $key;

is_oneref( $tk, '$k has refcount 1 before EOF' );

is_refcount( $rd, 2, '$rd has refcount 2 before dropping $tk' );

undef $tk;

is_oneref( $rd, '$rd has refcount 1 before EOF' );
