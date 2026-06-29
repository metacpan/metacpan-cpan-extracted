#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
require 5.010;
use Test::More;
use Test::LeakTrace;
use Stats::LikeR;

# --- basic dedup, first-seen order ---------------------------------------
my @basic;
no_leaks_ok { eval { @basic = uniq(1, 2, 2, 3, 1) } } 'uniq no leaks: basic' unless $INC{'Devel/Cover.pm'};
is_deeply \@basic, [1, 2, 3], 'uniq dedups and preserves first-seen order';

# --- string dedup --------------------------------------------------------
my @str;
no_leaks_ok { eval { @str = uniq(qw/a b a c b a/) } } 'uniq no leaks: string dedup' unless $INC{'Devel/Cover.pm'};
is_deeply \@str, [qw/a b c/], 'uniq dedups strings preserving first-seen order';

# --- numeric / string collapse (eq semantics) ----------------------------
my @num;
no_leaks_ok { eval { @num = uniq(1, 1.0, "1", 2) } } 'uniq no leaks: numeric/string collapse' unless $INC{'Devel/Cover.pm'};
is_deeply \@num, [1, 2], 'uniq collapses 1, 1.0, "1" to the first occurrence';

# --- array-ref flattening (one level) ------------------------------------
my @flat;
no_leaks_ok { eval { @flat = uniq([1, 2, 2], [2, 3]) } } 'uniq no leaks: array refs' unless $INC{'Devel/Cover.pm'};
is_deeply \@flat, [1, 2, 3], 'uniq expands array refs and dedups across them';

# --- mixed scalars and array refs ----------------------------------------
my @mix;
no_leaks_ok { eval { @mix = uniq(1, [2, 2, 3], 1, [3, 4]) } } 'uniq no leaks: mixed args' unless $INC{'Devel/Cover.pm'};
is_deeply \@mix, [1, 2, 3, 4], 'uniq dedups across scalars and array refs together';

# --- scalar context returns the distinct count ---------------------------
my $n;
no_leaks_ok { eval { $n = uniq(1, 2, 2, 3, 1) } } 'uniq no leaks: scalar count' unless $INC{'Devel/Cover.pm'};
is $n, 3, 'uniq returns the distinct count in scalar context';

# --- empty input ---------------------------------------------------------
my @empty;
no_leaks_ok { eval { @empty = uniq() } } 'uniq no leaks: empty list' unless $INC{'Devel/Cover.pm'};
is_deeply \@empty, [], 'uniq of empty list is empty in list context';

my $zero;
no_leaks_ok { eval { $zero = uniq() } } 'uniq no leaks: empty scalar' unless $INC{'Devel/Cover.pm'};
is $zero, 0, 'uniq of empty list is 0 in scalar context';

# --- UTF-8: identical wide chars collapse --------------------------------
my @wide;
no_leaks_ok { eval { @wide = uniq("\x{263a}", "\x{263a}", "x") } } 'uniq no leaks: wide chars' unless $INC{'Devel/Cover.pm'};
is_deeply \@wide, ["\x{263a}", "x"], 'uniq collapses identical wide-character strings';

# --- croak on undef scalar argument --------------------------------------
my $e_scalar = '';
no_leaks_ok { eval { uniq(1, undef, 3); 1 } or $e_scalar = $@ } 'uniq no leaks: undef scalar croak' unless $INC{'Devel/Cover.pm'};
like $e_scalar, qr/uniq: undefined value at argument index 1/, 'uniq croaks on an undef scalar arg';

# --- croak on undef inside an array ref ----------------------------------
my $e_aref = '';
no_leaks_ok { eval { uniq([1, undef, 3]); 1 } or $e_aref = $@ } 'uniq no leaks: undef in aref croak' unless $INC{'Devel/Cover.pm'};
like $e_aref, qr/uniq: undefined value at array ref index 1 \(argument 0\)/, 'uniq croaks on an undef array element';

done_testing();
