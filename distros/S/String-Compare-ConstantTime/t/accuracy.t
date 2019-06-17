#!/usr/bin/env perl

use strict;
use warnings;

use String::Compare::ConstantTime qw/equals/;

use utf8;
use Encode;

use Test::More tests => 26;


ok(equals("asdf", "asdf"));
ok(!equals("asdf", "asdg"));
ok(!equals("asdf", "asdfg"));
ok(!equals("asdfg", "asdf"));

ok(equals("a"x1000, "a"x1000));
ok(!equals("a"x1000, "a"x999 . "b"));
ok(!equals("a"x400 . "b" . "a"x599, "a"x1000));

ok(equals("\x00"x65, "\x00"x65));
ok(!equals("\x00"x65, "\x00"x64));

ok(equals(1, 1));
ok(equals(10000000, 10000000));
ok(!equals(10000000, 10000070));

ok(equals("λ", "λ"));
ok(equals("λλλλλλλ", "λλλλλλλ"));

ok(equals(join("", ( map { chr } (0 .. 255) )) x 10,
           join("", ( map { chr } (0 .. 255) )) x 10));

ok(!equals("asdf", undef));
ok(!equals(undef, "asdf"));
ok(equals(undef, undef));

my $string_utf8_on = "äßλ";
ok( utf8::is_utf8($string_utf8_on), "utf8 flag on");
my $string_utf8_off = Encode::encode("utf8", $string_utf8_on);
ok( !utf8::is_utf8($string_utf8_off), "utf8 flag off");
ok(equals($string_utf8_on, $string_utf8_off));

my $latin1_e_acute = "\xe9";
ok( !utf8::is_utf8($latin1_e_acute), "latin-1 e-acute has utf8 flag off");
my $utf8_e_acute = "é";
ok( utf8::is_utf8($utf8_e_acute), "UTF-8 e-acute has utf8 flag on");
ok(!equals($latin1_e_acute, $utf8_e_acute), "latin-1 vs UTF-8 not equal to us");
ok($latin1_e_acute eq $utf8_e_acute, "but perl thinks they are");

utf8::encode($utf8_e_acute);
utf8::encode($latin1_e_acute);
ok(equals($latin1_e_acute, $utf8_e_acute), "after encoding, they are equal to us");
