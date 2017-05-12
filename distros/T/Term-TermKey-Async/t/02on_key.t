#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use IO::Async::Test;

use IO::Async::Loop;
use IO::Async::OS;

use Term::TermKey::Async;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $rd, $wr ) = IO::Async::OS->pipepair or die "Cannot pipe() - $!";

# Sanitise this just in case
$ENV{TERM} = "vt100";

my $key;

my $tka = Term::TermKey::Async->new(
   term => $rd,
   on_key => sub { ( undef, $key ) = @_; },
);

$loop->add( $tka );

ok( !defined $key, '$key is not yet defined' );

$wr->syswrite( "h" );

undef $key;
wait_for { defined $key };

is( $key->termkey, $tka->termkey, '$key->termkey after h' );

ok( $key->type_is_unicode,     '$key->type_is_unicode after h' );
is( $key->codepoint, ord("h"), '$key->codepoint after h' );
is( $key->modifiers, 0,        '$key->modifiers after h' );

is( $key->utf8, "h", '$key->utf8 after h' );

is( $key->format( 0 ), "h", '$key->format after h' );

$wr->syswrite( "\cA" );

undef $key;
wait_for { defined $key };

ok( $key->type_is_unicode,        '$key->type_is_unicode after C-a' );
is( $key->codepoint, ord("a"),    '$key->codepoint after C-a' );
is( $key->modifiers, KEYMOD_CTRL, '$key->modifiers after C-a' );

is( $key->format( 0 ), "C-a", '$key->format after C-a' );

$wr->syswrite( "\eOA" );

undef $key;
wait_for { defined $key };

ok( $key->type_is_keysym,               '$key->type_is_keysym after Up' );
is( $key->sym, $tka->keyname2sym("Up"), '$key->keysym after Up' );
is( $key->modifiers, 0,                 '$key->modifiers after Up' );

is( $key->format( 0 ), "Up", '$key->format after Up' );

done_testing;
