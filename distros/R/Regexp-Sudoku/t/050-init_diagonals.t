#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';

use lib qw [lib ../lib];

use Test::More 0.88;
use Test::Exception;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;
use Regexp::Sudoku::Constants qw [:Diagonals];
use List::Util                qw [max];

my $NAME       = 0;
my $IS_MINOR   = 1;
my $ROW_OFFSET = 2;
my $COL_OFFSET = 3;

my %type2info = (
    $MAIN           =>  ["DM",    0,  0,  0],
    $MINOR          =>  ["Dm",    1,  0,  0],
);
foreach my $i (1 .. 34) {
    no strict 'refs';
    $type2info {${"SUPER$i"}}       = ["DMS$i", 0,   0,  $i];
    $type2info {${"SUB$i"}}         = ["DMs$i", 0,  $i,   0];
    $type2info {${"MINOR_SUPER$i"}} = ["DmS$i", 1, -$i,   0];
    $type2info {${"MINOR_SUB$i"}}   = ["Dms$i", 1,   0,  $i];
}

sub exp_cells ($type, $size) {
    my @exp_cells;
    my ($is_minor, $row_offset, $col_offset) = 
       @{$type2info {$type}} [$IS_MINOR, $ROW_OFFSET, $COL_OFFSET];
    my $max_offset = max map {abs $_} ($row_offset, $col_offset);

    if (!$is_minor) {
        @exp_cells = map {sprintf "R%dC%d",
                                      $_ + $row_offset, $_ + $col_offset}
                              1 .. $size - $max_offset;
    }
    else {
        @exp_cells = map {sprintf "R%dC%d",
                          $size - $_ + 1 + $row_offset, $_ + $col_offset}
                              1 .. $size - $max_offset;
    }

    return sort @exp_cells;
}

sub test ($name, $type, $size = 9) {
    my $sudoku = Regexp::Sudoku:: -> new -> init (size      => $size,
                                                  diagonals => $type);
    subtest $name, sub {
        foreach my $target_type (sort keys %type2info) {
            if (($type &. $target_type) =~ /[^\0]/) {
                my $name = $type2info {$target_type} [$NAME];
                my @exp_cells = exp_cells $target_type, $size;
                my %exp_cells = map {$_ => 1} @exp_cells;
                my @got_cells = sort $sudoku -> house2cells ($name);
                is_deeply \@got_cells, \@exp_cells, "Cells in house '$name'";

                for my $r (1 .. $size) {
                    for my $c (1 .. $size) {
                        my $cell = "R${r}C${c}";
                        my %got_houses = map {$_ => 1}
                                              $sudoku -> cell2houses ($cell);
                        ok !($exp_cells {$cell} xor $got_houses {$name}),
                             $exp_cells {$cell} ?  "Cell $cell is in $name"
                                                :  "Cell $cell is not in $name";
                    }
                }
            }
        }
    }
}


test "Main diagonal",           $MAIN;
test "Minor diagonal",          $MINOR;
test "Both diagonals",          $CROSS;
test "Both diagonals (6x6)",    $CROSS,            6;
test "Main diagonal (16x16)",   $MAIN,            16;
test "Both diagonals (35x35)",  $CROSS,           35;
test "Super diagonal",          $SUPER;
test "Sub diagonal",            $SUB;
test "Super minor diagonal",    $MINOR_SUPER;
test "Sub minor diagonal",      $MINOR_SUB;
test "Super diagonal 2",        $SUPER2;
test "Sub diagonal 2",          $SUB2;
test "Super minor diagonal 2",  $MINOR_SUPER2;
test "Sub minor diagonal 2",    $MINOR_SUB2;
test "Argyle",                  $ARGYLE;
test "Argyle (12x12)",          $ARGYLE,          12;


vec (my $diag = "", 200, 1) = 1;
throws_ok {
    Regexp::Sudoku:: -> new -> init (diagonals => $diag)
} qr /^Unknown diagonal\(s\)/, "Do not allow unknown diagonals";


Test::NoWarnings::had_no_warnings () if $r;

done_testing;
