#!/usr/bin/perl

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

use lib qw [lib ../lib ../../lib];

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Regexp::Sudoku;

sub run_test ($name, @anti_battenburgs) {
    subtest $name => sub {
        my %exp;
        my $sudoku = Regexp::Sudoku:: -> new -> init;
        $sudoku -> set_anti_battenburg (@anti_battenburgs);

        foreach my $cell (@anti_battenburgs) {
            my $name = $cell;
            my ($r, $c) = $cell =~ /R([0-9]+)C([0-9]+)/;
            my @exp_set = (sprintf ("R%dC%d", $r,     $c),
                           sprintf ("R%dC%d", $r,     $c + 1),
                           sprintf ("R%dC%d", $r + 1, $c),
                           sprintf ("R%dC%d", $r + 1, $c + 1));
            $exp {$_} {$name} = 1 for @exp_set;

            my @got = $sudoku -> anti_battenburg2cells ($name);
            is_deeply [sort @got], [sort @exp_set],
                                        "anti_battenburg2cells ($name)";
        }
        foreach my $cell (keys %exp) {
            my @got = $sudoku -> cell2anti_battenburgs ($cell);
            is_deeply [sort @got], [sort keys %{$exp {$cell}}],
                                        "cell2anti_battenburgs ($cell)";
        }
    }
}

run_test "Single anti-Battenburg",               qw [R1C1];
run_test "Two non-overlapping anti-Battenburgs", qw [R2C2 R7C4];
run_test "Two overlapping anti-Battenburgs",     qw [R3C3 R4C3];
run_test "Many anti-Battenburgs",                qw [R1C1 R2C2 R3C3 R4C4 R5C5
                                                     R6C6 R7C7 R8C8];

Test::NoWarnings::had_no_warnings () if $r;

done_testing;

__END__
