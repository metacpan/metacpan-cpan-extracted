use warnings FATAL => 'all';
use strict;

use Test::More tests => 11;

use Quote::Code;

is "foo {2 + 2}", 'foo {2 + 2}';
is length("{0}"), 3;
is qc"foo {2 + 2}", "foo 4";
is length(qc'{0}'), 1;
$_ = "abc";
is qc($_ {substr $_, 1}\t(\n)), "\$_ bc\t(\n)";

is qc<\xff>, "\xff";
is qc'\x{20AC}', "\x{20AC}";
is qc'\x20AC', "\x20AC";

is qc[[[*]]], q[[[*]]];
is qc<a<b\<c>d\>e>, qq<a<b\<c>d\>e>;
is qc{a {sqrt 4} b {0; lc qc{\{{"}C"} D};} e}, 'a 2 b {}c d e';
