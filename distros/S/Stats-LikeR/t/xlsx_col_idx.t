#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;

# _xlsx_col_idx: Excel column letters -> 0-based column index.  It is
# xlsx_ref_col() in LikeR.xs, which places every cell the xlsx reader reads --
# exposed to perl so the letter arithmetic can be exercised on its own here.
# Covers all three character branches (A-Z, a-z, and the non-letter
# terminator); t/read_table.xlsx.parser.t covers the -1 it returns for a
# reference too long to be one.

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
