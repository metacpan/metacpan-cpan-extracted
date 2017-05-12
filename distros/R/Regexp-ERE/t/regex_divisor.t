use strict;
use warnings;

use Regexp::ERE qw(
    &char_to_cc
    &cc_union
    &nfa_to_regex
    &nfa_to_min_dfa
);

my @mods;
my @test_range;
my $num_tests;
BEGIN {
    @mods = (1..6, 10, 15, 20);
    @test_range = (0..10);
    $num_tests = 0;
    for (map { $_ * @test_range } @mods) {
        $num_tests += $_;
    }
}

use Test::Simple tests => $num_tests;

my $builder = Test::Simple->builder;
binmode($builder->output        , ':encoding(UTF-8)');
binmode($builder->failure_output, ':encoding(UTF-8)');
binmode($builder->todo_output   , ':encoding(UTF-8)');

for my $mod (@mods) {
    # n = 0 mod $mod
    my $nfa = [
        map {
            my $rest = $_;
            my %index_to_cc;
            for (0..9) {
                my $digit = $_;
                push(
                    @{$index_to_cc{($rest * 10 + $digit) % $mod}}
                  , char_to_cc($digit)
                );
            }
            [0, [
                map { [ cc_union(@{$index_to_cc{$_}}) => $_ ] }
                (keys(%index_to_cc))
            ]]
        }
        (0..$mod-1)
    ];
    $$nfa[0][0] = 1;

    my $min_dfa = nfa_to_min_dfa($nfa);
    my $perlre = nfa_to_regex($min_dfa, 1);

    for my $zero ( map { $mod * $_ } @test_range ) {
        ok($zero =~ $perlre, "is zero modulo $mod: $zero");
    }
    for my $off (1..$mod-1) {
        for my $not_zero ( map { $mod * $_ + $off } @test_range ) {
            ok($not_zero !~ $perlre, "is not zero modulo $mod: $not_zero");
        }
    }
}
