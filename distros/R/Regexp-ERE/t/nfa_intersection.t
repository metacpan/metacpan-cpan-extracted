use strict;
use warnings;

use Regexp::ERE qw(
    &nfa_inter
    &nfa_isomorph
    &nfa_to_min_dfa
    &char_to_cc
    &cc_union
);

our @divisor_pairs_digits_list;
BEGIN {
    @divisor_pairs_digits_list = (
        [2, 7,  [(0..9)]]
      , [3, 5,  [(0..9)]]
      , [3, 11, [(0..9)]]
      , [3, 7,  [(0..4)]]
      , [2, 7,  [(0..1)]]
      , [5, 8,  [qw(a b c d)]]
    );
}

sub nfa_make_is_multiple_of {
    my (
        $d       # divisor > 0
      , $digits # @$digits > 1
    ) = @_;

    my $b = @$digits;

    use integer;
    my @transition_cases = (0..($d < $b ? $d-1 : $b-1));
    my %rest_to_character_class
      = map {
            my $rest = $_;
            ( $rest => cc_union(
                map { char_to_cc($$digits[$rest + $_*$d]) }
                (0..(($b - 1 - $_) / $d))
            ))
        }
        @transition_cases
    ;
    return [                           # nfa
        map {
            my $cur_rest = $_;
            [                          # state
                $cur_rest == 0 ? 1 : 0 # accepting
              , [                      # transitions
                    map {
                        my $next_r = $_;
                        my $cc = $rest_to_character_class{$next_r};
                        [ $cc, ($cur_rest * $b + $next_r) % $d ]
                    }
                    @transition_cases
                ]
            ]
        }
        (0..$d-1)
    ];
}

use Test::Simple tests => scalar(@divisor_pairs_digits_list);

for my $divisor_pair_digits (@divisor_pairs_digits_list) {
    my ($d1, $d2, $digits) = @$divisor_pair_digits;
    my $nfa1 = nfa_inter(
        nfa_make_is_multiple_of($d1, $digits)
      , nfa_make_is_multiple_of($d2, $digits)
    );
    my $nfa2 = nfa_make_is_multiple_of($d1*$d2, $digits);
    my $dfa1 = nfa_to_min_dfa($nfa1);
    my $dfa2 = nfa_to_min_dfa($nfa2);
    ok(
        nfa_isomorph($dfa1, $dfa2)
      , 'divisor nfa:'
      . " divisor_0 = $$divisor_pair_digits[0]"
      . ", divisor_1 = $$divisor_pair_digits[1]"
      . ", digits = (@{$$divisor_pair_digits[2]})"
    );
}
