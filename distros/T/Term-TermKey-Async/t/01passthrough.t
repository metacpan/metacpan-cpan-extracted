#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Term::TermKey::Async;

use IO::Handle; # to keep IO::Async::Handle happy

my $tka = Term::TermKey::Async->new(
   term => \*STDIN,
   on_key => sub { },
);

defined $tka or die "Cannot create termkey instance";

# We know 'Space' ought to exist
my $sym = $tka->keyname2sym( 'Space' );

ok( defined $sym, "defined keyname2sym('Space')" );

is( $tka->get_keyname( $sym ), 'Space', "get_keyname eq Space" );

my $key;

ok( defined( $key = $tka->parse_key( "A", 0 ) ), '->parse_key "A" defined' );

ok( $key->type_is_unicode,     '$key->type_is_unicode' );
is( $key->codepoint, ord("A"), '$key->codepoint' );
is( $key->modifiers, 0,        '$key->modifiers' );

is( $tka->format_key( $key, 0 ), "A", '->format_key yields "A"' );

done_testing;
