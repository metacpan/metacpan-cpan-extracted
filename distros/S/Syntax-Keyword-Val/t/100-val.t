#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most 'no_plan';

use Syntax::Keyword::Val;

# scalar
val $foo = 123;
throws_ok { $foo = "abc" } qr/Modification of a read-only value/;
throws_ok { undef $foo } qr/Modification of a read-only value/;
is $foo, 123;

# arrayref
val $barr = [qw[abc def ghi jkl]];
is_deeply $barr, [qw[abc def ghi jkl]];
throws_ok { $barr = [qw[xyz]] } qr/Modification of a read-only value/;
throws_ok { $$barr[1] = 'xxx' } qr/Modification of a read-only value/;
throws_ok { push @$barr, 'qwe' } qr/Modification of a read-only value/;
is_deeply $barr, [qw[abc def ghi jkl]];

# hashref
val $h = {abc => 123, def => 456};
is_deeply $h, {abc => 123, def => 456};
throws_ok { $h = {xyz => 666 } } qr/Modification of a read-only value/;
throws_ok { $$h{abc} = 666 }     qr/Modification of a read-only value/;
# different error due to the way perl implements read-only hashes
throws_ok { $$h{xyz} = 666 }  qr/Attempt to access disallowed key/;
throws_ok { delete $$h{abc} } qr/Attempt to delete readonly key/;

# array doesn't work (nor does a hash, no tests for that yet)
# it will issue a compile-time warning, which the test shuts up
SKIP: {
    skip "dlock doesn't affect arrays or hashrefs at all";
    no warnings;
    val @bar = qw[abc def ghi jkl];
    is_deeply [@bar], [qw[abc def ghi jkl]];
    throws_ok { @bar = qw[xyz] } qr/Modification of a read-only value/;
    throws_ok { $bar[1] = 'xxx' } qr/Modification of a read-only value/;
    is_deeply [@bar], [qw[abc def ghi jkl]];
}

# This only applies the magic to $x, and a compile-time warning is
# also issued (which again is shut up by the test)
SKIP: {
    skip "magic doesn't take on other vals in a list";
    no warnings;
    val ($x, $y) = (66,77);
    is $x, 66;
    is $y, 77;
    throws_ok { $x = 123 } qr/Modification of a read-only value/;
    throws_ok { $y = 456 } qr/Modification of a read-only value/;
}

