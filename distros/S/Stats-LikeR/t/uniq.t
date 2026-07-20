#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
require 5.010;
use Test::More;
use Test::LeakTrace;
use Stats::LikeR;

# The functional value is computed OUTSIDE the leak block: the whole
# no_leaks_ok statement is skipped under Devel::Cover (its instrumentation SVs
# look like leaks), and if the assigned-to variable lived inside that block it
# would be undef under coverage and the assertions below would fail.

# --- basic dedup, first-seen order ---------------------------------------
my @basic = uniq(1, 2, 2, 3, 1);
is_deeply \@basic, [1, 2, 3], 'uniq dedups and preserves first-seen order';
no_leaks_ok { eval { my @x = uniq(1, 2, 2, 3, 1) } } 'uniq no leaks: basic' unless $INC{'Devel/Cover.pm'};

# --- string dedup --------------------------------------------------------
my @str = uniq(qw/a b a c b a/);
is_deeply \@str, [qw/a b c/], 'uniq dedups strings preserving first-seen order';
no_leaks_ok { eval { my @x = uniq(qw/a b a c b a/) } } 'uniq no leaks: string dedup' unless $INC{'Devel/Cover.pm'};

# --- numeric / string collapse (eq semantics) ----------------------------
my @num = uniq(1, 1.0, "1", 2);
is_deeply \@num, [1, 2], 'uniq collapses 1, 1.0, "1" to the first occurrence';
no_leaks_ok { eval { my @x = uniq(1, 1.0, "1", 2) } } 'uniq no leaks: numeric/string collapse' unless $INC{'Devel/Cover.pm'};

# --- array-ref flattening (one level) ------------------------------------
my @flat = uniq([1, 2, 2], [2, 3]);
is_deeply \@flat, [1, 2, 3], 'uniq expands array refs and dedups across them';
no_leaks_ok { eval { my @x = uniq([1, 2, 2], [2, 3]) } } 'uniq no leaks: array refs' unless $INC{'Devel/Cover.pm'};

# --- mixed scalars and array refs ----------------------------------------
my @mix = uniq(1, [2, 2, 3], 1, [3, 4]);
is_deeply \@mix, [1, 2, 3, 4], 'uniq dedups across scalars and array refs together';
no_leaks_ok { eval { my @x = uniq(1, [2, 2, 3], 1, [3, 4]) } } 'uniq no leaks: mixed args' unless $INC{'Devel/Cover.pm'};

# --- scalar context returns the distinct count ---------------------------
my $n = uniq(1, 2, 2, 3, 1);
is $n, 3, 'uniq returns the distinct count in scalar context';
no_leaks_ok { eval { my $x = uniq(1, 2, 2, 3, 1) } } 'uniq no leaks: scalar count' unless $INC{'Devel/Cover.pm'};

# --- empty input ---------------------------------------------------------
my @empty = uniq();
is_deeply \@empty, [], 'uniq of empty list is empty in list context';
no_leaks_ok { eval { my @x = uniq() } } 'uniq no leaks: empty list' unless $INC{'Devel/Cover.pm'};

my $zero = uniq();
is $zero, 0, 'uniq of empty list is 0 in scalar context';
no_leaks_ok { eval { my $x = uniq() } } 'uniq no leaks: empty scalar' unless $INC{'Devel/Cover.pm'};

# --- UTF-8: identical wide chars collapse --------------------------------
my @wide = uniq("\x{263a}", "\x{263a}", "x");
is_deeply \@wide, ["\x{263a}", "x"], 'uniq collapses identical wide-character strings';
no_leaks_ok { eval { my @x = uniq("\x{263a}", "\x{263a}", "x") } } 'uniq no leaks: wide chars' unless $INC{'Devel/Cover.pm'};

# --- croak on undef scalar argument --------------------------------------
my $e_scalar = '';
eval { uniq(1, undef, 3); 1 } or $e_scalar = $@;
like $e_scalar, qr/uniq: undefined value at argument index 1/, 'uniq croaks on an undef scalar arg';
no_leaks_ok { eval { uniq(1, undef, 3) } } 'uniq no leaks: undef scalar croak' unless $INC{'Devel/Cover.pm'};

# --- croak on undef inside an array ref ----------------------------------
my $e_aref = '';
eval { uniq([1, undef, 3]); 1 } or $e_aref = $@;
like $e_aref, qr/uniq: undefined value at array ref index 1 \(argument 0\)/, 'uniq croaks on an undef array element';
no_leaks_ok { eval { uniq([1, undef, 3]) } } 'uniq no leaks: undef in aref croak' unless $INC{'Devel/Cover.pm'};

done_testing();
