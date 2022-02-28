package Test;

use 5.028;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';
use experimental 'lexical_subs';

chdir "t" if -d "t";

#
# Little module to help use test a sudoku
#

use lib qw [lib ../lib];

use Exporter ();
our @ISA    = qw [Exporter];
our @EXPORT = qw [run_sudoku];

use Regexp::Sudoku;
use Test::More;

sub show ($size, $matches) {
    say "    # ";
    say "    # Got solution: ";
    say "    # ";
    for (my $r = 1; $r <= $size; $r ++) {
        print "    # ";
        for (my $c = 1; $c <= $size; $c ++) {
            my $cell = "R${r}C${c}";
            print $$matches {$cell}, " ";
        }
        print "\n";
    }
    say "    # ";
}

sub run_sudoku ($file) {
    #
    # First, slurp in the file
    #
    my $test = do {local (@ARGV, $/) = ($file); <>};
    my @chunks = split /\n==\n/ => $test;

    #
    # First one is always the sudoku.
    #
    my $clues = shift @chunks;

    #
    # Find a solution
    #
    my ($solution) = grep {/^Solution/} @chunks;

    #
    # Find args, if any
    #
    my ($arg_section) = grep {/^Args/} @chunks;
    my  $args = {};
    if ($arg_section) {
        $arg_section =~ s/^.*\n//;
        $args = eval $arg_section;
        die $@ if $@;
    }

    #
    # Find the size
    #
    my ($first) = split /\n/ => $clues;
    my  $size   = () = $first =~ /\S+/g;

    #
    # Find the name, if any
    #
    my ($name)   = $test =~ /^Name:\s*(.*)/m;
        $name  //= "Sudoku size $size";
    if ($test =~ /^Author:\s*(.*)/m) {
        $name .= " by $1";
    }

    subtest $name => sub {
        #
        # Sudoku object
        #
        my $sudoku = Regexp::Sudoku:: -> new -> init (size  => $size,
                                                      clues => $clues,
                                                      %$args);

        ok $sudoku, "Regexp::Sudoku object";
        return unless $sudoku;

        #
        # Get the subject and pattern
        #
        my $subject = $sudoku -> subject;
        my $pattern = $sudoku -> pattern;

        ok $subject, "Got a subject";
        ok $pattern, "Got a pattern";
        return unless $subject && $pattern;

        #
        # Do the actual match
        #
        my $r = $subject =~ $pattern;
        ok $r, "Match";
        return unless $r;

        my %plus = %+;

        if ($solution) {
            $solution =~ s/^.*\n//;
            my @exp  = map {[/\S+/g]} grep {/\S/} split /\n/ => $solution;
            my $pass = 1;
            foreach my $r (1 .. $size) {
                foreach my $c (1 .. $size) {
                    my $cell = "R${r}C${c}";
                    is $plus {$cell}, $exp [$r - 1] [$c - 1], "Cell $cell";
                    $pass &&= $plus {$cell} eq $exp [$r - 1] [$c - 1];
                }
            }
            show $size, \%plus unless $pass;
        }
    }
}
