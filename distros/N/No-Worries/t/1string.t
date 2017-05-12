#!perl

use strict;
use warnings;
use Test::More tests => 15;

use No::Worries::String qw(string_escape string_plural string_trim);

is(string_escape(""), "", "string_escape()");
is(string_escape("x"), "x", "string_escape(x)");
is(string_escape("a\\x00\0"), "a\\\\x00\\x00", "string_escape(a\\\\x00\\0)");
is(string_escape("a\eb\nc\rd\te"), "a\\eb\\nc\\rd\\te", "string_escape(a\\eb\\nc\\rd\\te)");
is(string_escape("<\x{263a}>"), "<\\x{263a}>", "string_escape(smiley)");
is(string_escape("<\x{26}\x{3a}>"), "<&:>", "string_escape(&:)");

is(string_plural("foot"), "feet", "string_plural(foot)");
is(string_plural("directory"), "directories", "string_plural(directory)");
is(string_plural("file"), "files", "string_plural(file)");

is(string_trim(""), "", "string_trim()");
is(string_trim("x"), "x", "string_trim(x)");
is(string_trim(" x "), "x", "string_trim( x )");
is(string_trim("   x   "), "x", "string_trim(   x   )");
is(string_trim(" x y "), "x y", "string_trim( x y )");
is(string_trim("\t\r\nx\n\r\t"), "x", "string_trim(\\t\\r\\nx\\n\\r\\t)");
