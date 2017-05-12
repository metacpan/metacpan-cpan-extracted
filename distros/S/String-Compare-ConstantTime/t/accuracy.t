use String::Compare::ConstantTime qw/equals/;

use strict;

use utf8;

use Test::More tests => 18;


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
