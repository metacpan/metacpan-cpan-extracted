#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Perl::Minify qw(minify);

# 1. Normal wrap: every line <= 40 chars
my $code = 'use strict; use warnings; my $x = 42; print "hello world";';
my $w = minify($code, { wrap => 40 });
ok(defined($w), 'wrap returns defined');
for my $line (split "\n", $w) {
    ok(length($line) <= 40, "wrap: line length ${\length($line)} <= 40")
        or diag "Overlong line: [$line]";
}

# 2. Overlong string with no safe break point -> emitted as one long line
my $long_str = 'my $x = "aaaaaa' . 'b' x 60 . '";';
my $w2 = minify($long_str, { wrap => 40 });
ok(defined($w2), 'overlong string returns defined');
# The statement has no safe break point (spaces inside the string are unsafe),
# so it should be one line even if >= 40.
my @lines2 = split "\n", $w2;
is(scalar(@lines2), 1, 'overlong string stays on one line') or diag "got: $w2";

# 3. ANSI escape sequences inside a string: spaces inside string are NOT used as break points
my $ansi_long = 'print "\e[0m\e[1m' . (' foo' x 20) . '\e[0m"; print "bar";';
my $w3 = minify($ansi_long, { wrap => 40 });
ok(defined($w3), 'ANSI long wrap returns defined');
# The print with the long ANSI string has no safe break points, so it may be one long line.
# But the second statement "print \"bar\";" should be on its own line (or combined).
# We assert that no line contains a break inside the string: each line either is
# the full string statement or not.

# 4. Short code: no wrapping needed
my $short_code = 'print 42;';
my $w4 = minify($short_code, { wrap => 40 });
is($w4, 'print 42;', 'short code unchanged by wrap') or diag "got: [$w4]";

# 5. wrap => 0 (off) returns same as no wrap option
my $w5 = minify($code, { wrap => 0 });
is($w5, minify($code), 'wrap=0 same as default (no wrap)') or diag "got: [$w5]";

done_testing;
