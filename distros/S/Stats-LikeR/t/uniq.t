#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
require 5.010;
use Test::More;
use Test::LeakTrace;
use Stats::LikeR qw(:all);

# The functional value is computed OUTSIDE the leak block: the whole
# no_leaks_ok statement is skipped under Devel::Cover (its instrumentation SVs
# look like leaks), and if the assigned-to variable lived inside that block it
# would be undef under coverage and the assertions below would fail.

# basic dedup, first-seen order
my @basic = uniq(1, 2, 2, 3, 1);
is_deeply \@basic, [1, 2, 3], 'uniq dedups and preserves first-seen order';
no_leaks_ok { eval { my @x = uniq(1, 2, 2, 3, 1) } } 'uniq no leaks: basic' unless $INC{'Devel/Cover.pm'};

# string dedup
my @str = uniq(qw/a b a c b a/);
is_deeply \@str, [qw/a b c/], 'uniq dedups strings preserving first-seen order';
no_leaks_ok { eval { my @x = uniq(qw/a b a c b a/) } } 'uniq no leaks: string dedup' unless $INC{'Devel/Cover.pm'};

# numeric / string collapse (eq semantics)
my @num = uniq(1, 1.0, "1", 2);
is_deeply \@num, [1, 2], 'uniq collapses 1, 1.0, "1" to the first occurrence';
no_leaks_ok { eval { my @x = uniq(1, 1.0, "1", 2) } } 'uniq no leaks: numeric/string collapse' unless $INC{'Devel/Cover.pm'};

# array-ref flattening (one level)
my @flat = uniq([1, 2, 2], [2, 3]);
is_deeply \@flat, [1, 2, 3], 'uniq expands array refs and dedups across them';
no_leaks_ok { eval { my @x = uniq([1, 2, 2], [2, 3]) } } 'uniq no leaks: array refs' unless $INC{'Devel/Cover.pm'};

# mixed scalars and array refs
my @mix = uniq(1, [2, 2, 3], 1, [3, 4]);
is_deeply \@mix, [1, 2, 3, 4], 'uniq dedups across scalars and array refs together';
no_leaks_ok { eval { my @x = uniq(1, [2, 2, 3], 1, [3, 4]) } } 'uniq no leaks: mixed args' unless $INC{'Devel/Cover.pm'};

# scalar context returns the distinct count
my $n = uniq(1, 2, 2, 3, 1);
is $n, 3, 'uniq returns the distinct count in scalar context';
no_leaks_ok { eval { my $x = uniq(1, 2, 2, 3, 1) } } 'uniq no leaks: scalar count' unless $INC{'Devel/Cover.pm'};

# empty input
my @empty = uniq();
is_deeply \@empty, [], 'uniq of empty list is empty in list context';
no_leaks_ok { eval { my @x = uniq() } } 'uniq no leaks: empty list' unless $INC{'Devel/Cover.pm'};

my $zero = uniq();
is $zero, 0, 'uniq of empty list is 0 in scalar context';
no_leaks_ok { eval { my $x = uniq() } } 'uniq no leaks: empty scalar' unless $INC{'Devel/Cover.pm'};

# UTF-8: identical wide chars collapse
my @wide = uniq("\x{263a}", "\x{263a}", "x");
is_deeply \@wide, ["\x{263a}", "x"], 'uniq collapses identical wide-character strings';
no_leaks_ok { eval { my @x = uniq("\x{263a}", "\x{263a}", "x") } } 'uniq no leaks: wide chars' unless $INC{'Devel/Cover.pm'};

# croak on undef scalar argument
my $e_scalar = '';
eval { uniq(1, undef, 3); 1 } or $e_scalar = $@;
like $e_scalar, qr/uniq: undefined value at argument index 1/, 'uniq croaks on an undef scalar arg';
no_leaks_ok { eval { uniq(1, undef, 3) } } 'uniq no leaks: undef scalar croak' unless $INC{'Devel/Cover.pm'};

# croak on undef inside an array ref
my $e_aref = '';
eval { uniq([1, undef, 3]); 1 } or $e_aref = $@;
like $e_aref, qr/uniq: undefined value at array ref index 1 \(argument 0\)/, 'uniq croaks on an undef array element';
no_leaks_ok { eval { uniq([1, undef, 3]) } } 'uniq no leaks: undef in aref croak' unless $INC{'Devel/Cover.pm'};

# 0.302 rewrote uniq's key table (perl HV -> the open-addressed arena
# drop_duplicates() and merge() intern into) and its key rendering (SvPV ->
# nk_num_pv).  Neither may change an answer, so the expected values below are
# the ones the 0.301 XSUB produced -- a verbatim copy of it was run beside the
# new one over 3000 rounds of randomly-drawn mixed input and had to agree on
# every value and on the scalar count.  There is no R or SciPy case to take
# these from: they pin perl-side surface (stringification, the UTF-8 flag,
# tied arrays, croak text), which unique() and pd.unique() have no counterpart
# for.

# UTF-8 keys are canonicalised the way a perl hash canonicalises them
# hv_common() downgrades a UTF-8 key whose every code point is below 256
# before it hashes, so these are the same key -- as `eq` also says.
is scalar(uniq("\x{e9}", "\xe9")), 1,
	'uniq collapses a UTF-8 char with the byte it downgrades to';
no_leaks_ok { eval { my @x = uniq("\x{e9}", "\xe9") } } 'uniq no leaks: UTF-8 downgrade' unless $INC{'Devel/Cover.pm'};

# ... but the flag is still part of the key: these two are byte-identical and
# are two different strings.
is scalar(uniq("\x{263a}", "\xe2\x98\xba")), 2,
	'uniq keeps a wide char distinct from its own UTF-8 bytes';
is scalar(uniq("\x{e9}", "\xc3\xa9")), 2,
	'uniq keeps a downgradable UTF-8 char distinct from its encoded bytes';

my $upgraded = "abc";
utf8::upgrade($upgraded);
is scalar(uniq($upgraded, "abc")), 1,
	'uniq collapses an upgraded ASCII string with its plain twin';
no_leaks_ok { eval { my @x = uniq($upgraded, "abc") } } 'uniq no leaks: upgraded ASCII' unless $INC{'Devel/Cover.pm'};

# stringification, not value
# Both pairs are chosen to be interesting to a value comparison: the first two
# are the same number written two ways, the second two are different doubles.
# Which way each falls is a property of the build's NV -- 1e15 reaches %.15g's
# exponent form on a double and not on a long double -- so the expectation is
# taken from `eq`, which is the semantics uniq documents, rather than written
# out for the NV this happens to be running on.
{
	my ($iv, $nv) = (1000000000000000, 1e15);
	is scalar(uniq($iv, $nv)), ("$iv" eq "$nv" ? 1 : 2),
		'uniq splits 1000000000000000 from 1e15 exactly when perl prints them apart';
	my ($sum, $lit) = (0.1 + 0.2, 0.3);
	is scalar(uniq($sum, $lit)), ("$sum" eq "$lit" ? 1 : 2),
		'uniq splits 0.1+0.2 from 0.3 exactly when perl prints them apart';
}

# non-finite values
my $inf = 9**9**9;
my $nan = $inf - $inf;
is scalar(uniq($inf, -$inf, $nan, $nan, $inf)), 3,
	'uniq keeps Inf, -Inf and NaN apart and collapses repeats of each';
no_leaks_ok { eval { my @x = uniq($inf, -$inf, $nan) } } 'uniq no leaks: non-finite' unless $INC{'Devel/Cover.pm'};

# the empty string is a value, and is not 0
is_deeply [uniq("", 0, "0", "")], ["", 0],
	'uniq treats the empty string as its own value';

# nested refs are compared as opaque values
my $inner = [1, 2];
is scalar(uniq([$inner, $inner, [1, 2]])), 2,
	'uniq compares nested array refs by identity, not contents';

# a tied array
# Up to 0.301 this croaked "undefined value at array ref index 0": av_fetch()
# on a tied array hands back a PVLV that reads undef until mg_get() has run on
# it, which is the bug sum() and the rest were fixed for in 0.301.
{
	package Stats::LikeR::Test::TiedArray;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
}
tie my @tied, 'Stats::LikeR::Test::TiedArray';
@tied = (1, 2, 2, 3, 'a', 'a');
is_deeply [uniq(\@tied)], [1, 2, 3, 'a'], 'uniq reads a tied array';
is scalar(uniq(\@tied)), 4, 'uniq counts a tied array in scalar context';
no_leaks_ok { eval { my @x = uniq(\@tied) } } 'uniq no leaks: tied array' unless $INC{'Devel/Cover.pm'};

# uniq must not stringify the caller's numeric SVs
# SvPV() on an NV leaves the rendered buffer behind, which is what made asking
# a large numeric column for its distinct values grow that column for good.
SKIP: {
	eval { require B; 1 } or skip 'B not available', 1;
	my $nv = 0.5;
	uniq([$nv]);
	ok !(B::svref_2object(\$nv)->FLAGS & B::SVf_POK()),
		'uniq leaves no cached PV on a numeric input SV';
}

# enough distinct keys to grow the arena and rehash the slot table
# dd_presize() sizes from the element count but caps the hint, so a run this
# long exercises both the doubling and the arena's Renew().
{
	my @many = map { "row.$_.of.some.length" } 1 .. 5000;
	my @dup  = (@many, @many);
	is scalar(uniq(\@dup)), 5000, 'uniq dedups 10000 elements down to 5000';
	is_deeply [(uniq(\@dup))[0, 4999]], [$many[0], $many[4999]],
		'uniq keeps first-seen order across the rehashes';
}

done_testing();
