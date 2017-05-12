#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use Term::TermKey;

my $tk = Term::TermKey->new_abstract( "vt100", 0 );

$tk->push_bytes( "\e[15;1\$y" );

my $key;
is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after ANSI mode report' );

ok( $key->type_is_modereport,  '$key->type_is_modereport after ANSI mode report' );

is( $key->initial, "", '$key->initial after ANSI mode report' );
is( $key->mode,    15, '$key->mode after ANSI mode report' );
is( $key->value,    1, '$key->value after ANSI mode report' );

$tk->push_bytes( "\e[?4;2\$y" );

is( $tk->getkey( $key ), RES_KEY, 'getkey yields RES_KEY after DEC mode report' );

ok( $key->type_is_modereport,  '$key->type_is_modereport after DEC mode report' );

is( $key->initial, "?", '$key->initial after DEC mode report' );
is( $key->mode,      4, '$key->mode after DEC mode report' );
is( $key->value,     2, '$key->value after DEC mode report' );
