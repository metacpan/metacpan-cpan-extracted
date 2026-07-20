#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;

# _xlsx_col_idx: Excel column letters -> 0-based column index.  It backs the
# xlsx reader's fallback for a <c> element whose r="A1" is not the first
# attribute (so the fast-path regex misses it); that layout is rare, so the
# helper is exercised directly here.  Covers all three character branches
# (A-Z, a-z, and the non-letter terminator).

my $f = \&Stats::LikeR::_xlsx_col_idx;

is( $f->('A'),  0,  "A -> 0" );
is( $f->('B'),  1,  "B -> 1" );
is( $f->('Z'),  25, "Z -> 25" );
is( $f->('AA'), 26, "AA -> 26" );
is( $f->('AB'), 27, "AB -> 27" );
is( $f->('AZ'), 51, "AZ -> 51" );
is( $f->('BA'), 52, "BA -> 52" );
is( $f->('ZZ'), 701, "ZZ -> 701" );

# lowercase letters take the a-z branch
is( $f->('a'),  0,  "a -> 0 (lower-case branch)" );
is( $f->('aa'), 26, "aa -> 26 (lower-case branch)" );

# a trailing digit (or any non-letter) terminates the scan
is( $f->('A1'),  0,  "A1 -> 0 (digit terminates)" );
is( $f->('AB12'), 27, "AB12 -> 27 (digits terminate)" );

done_testing;
