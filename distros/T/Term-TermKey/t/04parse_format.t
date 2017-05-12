#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;

use Term::TermKey;

my $tk = Term::TermKey->new_abstract( "vt100", FLAG_NOTERMIOS );

my $key;

ok( defined( $key = $tk->parse_key( "A", 0 ) ), '->parse_key "A" defined' );

ok( $key->type_is_unicode,     '$key->type_is_unicode' );
is( $key->codepoint, ord("A"), '$key->codepoint' );
is( $key->modifiers, 0,        '$key->modifiers' );

is( $tk->format_key( $key, 0 ), "A", '->format_key yields "A"' );

ok( defined( $key = $tk->parse_key( "Ctrl-b", FORMAT_LONGMOD ) ), '->parse_key "Ctrl-b" defined' );

ok( $key->type_is_unicode,        '$key->type_is_unicode' );
is( $key->codepoint, ord("b"),    '$key->codepoint' );
is( $key->modifiers, KEYMOD_CTRL, '$key->modifiers' );

is( $tk->format_key( $key, FORMAT_LONGMOD ), "Ctrl-b", '->format_key yields "Ctrl-b"' );

ok( !defined( $key = $tk->parse_key( "NoSuchKey", 0 ) ), '->parse_key "NoSuchKey" not defined' );

{
   my $str = "bind Alt-V = verbose";
   pos($str) = 5;

   ok( defined( $key = $tk->parse_key_at_pos( $str, FORMAT_LONGMOD ) ), '->parse_key_at_pos defined' );

   ok( $key->type_is_unicode,       '$key->type_is_unicode' );
   is( $key->codepoint, ord("V"),   '$key->codepoint' );
   is( $key->modifiers, KEYMOD_ALT, '$key->modifiers' );

   is( pos($str), 10, 'pos($str) after ->parse_key_at_pos' );
}

{
   my $str = "Ctrl-Up = up-page";

   ok( defined( $key = $tk->parse_key_at_pos( $str, FORMAT_LONGMOD ) ), '->parse_key_at_pos defined upgrade' );
   is( pos($str), 7, 'pos($str) after ->parse_key_at_pos upgrade' );
}
