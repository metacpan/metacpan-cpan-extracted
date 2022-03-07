#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

use lib qw [lib ../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;


sub set ($size, $type1, $type2, $offset) {
    my $r = $type1 eq "main"  && $type2 eq "super" ? 1
          : $type1 eq "main"  && $type2 eq "sub"   ? 1     + $offset
          : $type1 eq "minor" && $type2 eq "super" ? $size - $offset
          : $type1 eq "minor" && $type2 eq "sub"   ? $size
          : die "Unknown types $type1/$type2";
    my $c = $type1 eq "main"  && $type2 eq "super" ? 1     + $offset
          : $type1 eq "main"  && $type2 eq "sub"   ? 1
          : $type1 eq "minor" && $type2 eq "super" ? 1
          : $type1 eq "minor" && $type2 eq "sub"   ? 1     + $offset
          : die "Unknown types $type1/$type2";
    my $dr = $type1 eq "main" ? 1 : -1;

    my @cells;
    for (;0 < $r && $r <= $size && $c <= $size; ($r, $c) = ($r + $dr, $c + 1)) {
        push @cells => "R${r}C${c}";
    }

    sort @cells;
}


sub run_test ($exp_name, $size = 9) {
    my  $type1   = $exp_name =~ /M/ ? "main"  : "minor";
    my  $type2   = $exp_name =~ /S/ ? "super" : "sub";
    my ($offset) = $exp_name =~ /-([0-9]+)/;
    my @exp_cells =  set ($size, $type1, $type2, $offset);
    my $method    = "set_diagonal_${type1}_${type2}_${offset}";
    subtest "$method for a $size x $size Sudoku" => sub {
        SKIP: {
            my $sudoku = Regexp::Sudoku:: -> new
                                          -> init (size => $size)
                                          -> $method;
            skip 1 + $size * $size,
                "Did not get a Sudoku object" unless $sudoku;
            ok $sudoku, "Got Sudoku object";
            my %exp_cells = map {$_ => 1} @exp_cells;
            my @got_cells = sort $sudoku -> house2cells ($exp_name);

            is_deeply \@got_cells, \@exp_cells, "Cells in house $exp_name";

            for my $r (1 .. $size) {
                for my $c (1 .. $size) {
                    my $cell = "R${r}C${c}";
                    my %got_houses = map {$_ => 1}
                                          $sudoku -> cell2houses ($cell);
                    ok !($exp_cells {$cell} xor $got_houses {$exp_name}),
                         $exp_cells {$cell}
                           ? "Cell $cell is in house '$exp_name'"
                           : "Cell $cell is not in house '$exp_name'"
                }
            }
        }
    }
}

run_test "DMS-1"; 
run_test "DMs-1";
run_test "DmS-1";
run_test "Dms-1";

run_test "DMS-3"; 
run_test "DMs-4";
run_test "DmS-5";
run_test "Dms-6";

run_test "DMS-1",  6;
run_test "DMs-1",  6;
run_test "DmS-1",  6;
run_test "Dms-1",  6;

run_test "DMS-3", 16;
run_test "DMs-4", 16;
run_test "DmS-5", 16;
run_test "Dms-6", 16;


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
