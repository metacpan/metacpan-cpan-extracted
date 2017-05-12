use strict;
use warnings;

use Regexp::ERE qw(
    &nfa_isomorph
    &nfa_to_regex
    &nfa_to_min_dfa
    &char_to_cc
    &cc_union
);

our $lit_a;
our $lit_b;
our $lit_0;
our $lit_1;
our @nfa_pairs;
BEGIN {
    $lit_a = char_to_cc('a');
    $lit_b = char_to_cc('b');
    $lit_0 = char_to_cc('0');
    $lit_1 = char_to_cc('1');
    @nfa_pairs = (

        # nfa pair: occurrences of b = 1 (mod 3)
        [
            [ # first nfa
                [      # state 0
                    0  # rejecting
                  , [
                        [$lit_a, 5]
                      , [$lit_b, 7]
                    ]
                ]
              , [      # state 1
                    0  # rejecting
                  , [
                        [$lit_a, 4]
                      , [$lit_b, 5]
                    ]
                ]
              , [      # state 2
                    0  # rejecting
                  , [
                        [$lit_a, 6]
                      , [$lit_b, 4]
                    ]
                ]
              , [      # state 3
                    1  # accepting
                  , [
                        [$lit_a, 7]
                      , [$lit_b, 1]
                    ]
                ]
              , [      # state 4
                    0  # rejecting
                  , [
                        [$lit_a, 1]
                      , [$lit_b, 0]
                    ]
                ]
              , [      # state 5
                    0  # rejecting
                  , [
                        [$lit_a, 0]
                      , [$lit_b, 3]
                    ]
                ]
              , [      # state 6
                    1  # accepting
                  , [
                        [$lit_a, 2]
                      , [$lit_b, 3]
                    ]
                ]
              , [      # state 7
                    1  # accepting
                  , [
                        [$lit_a, 3]
                      , [$lit_b, 4]
                    ]
                ]
            ]
          , [ # second nfa
                [      # state 0     occurrences of b = 0 (mod 3)
                    0  # rejecting
                  , [
                        [$lit_a, 0]
                      , [$lit_b, 2]
                    ]
                ]
              , [      # state 1     occurrences of b = 2 (mod 3)
                    0  # rejecting
                  , [
                        [$lit_a, 1]
                      , [$lit_b, 0]
                    ]
                ]
              , [      # state 2     occurrences of b = 1 (mod 3)
                    1  # accepting
                  , [
                        [$lit_a, 2]
                      , [$lit_b, 1]
                    ]
                ]
            ]
        ]

        # nfa pair: binary number b with b & 100 in (100, 110, 111)
      , [
            [ # first nfa
                [      # state 0    b & 111 = 000
                    0  # rejecting
                  , [
                        [$lit_0, 0]
                      , [$lit_1, 1]
                    ]
                ]
              , [      # state 1    b & 111 = 001
                    0  # rejecting
                  , [
                        [$lit_0, 2]
                      , [$lit_1, 3]
                    ]
                ]
              , [      # state 2    b & 111 = 010
                    0  # rejecting
                  , [
                        [$lit_0, 4]
                      , [$lit_1, 5]
                    ]
                ]
              , [      # state 3    b & 111 = 011
                    0  # rejecting
                  , [
                        [$lit_0, 6]
                      , [$lit_1, 7]
                    ]
                ]
              , [      # state 4    b & 111 = 100
                    1  # accepting
                  , [
                        [$lit_0, 0]
                      , [$lit_1, 1]
                    ]
                ]
              , [      # state 5    b & 111 = 101
                    0  # rejecting
                  , [
                        [$lit_0, 2]
                      , [$lit_1, 3]
                    ]
                ]
              , [      # state 6    b & 111 = 110
                    1  # accepting
                  , [
                        [$lit_0, 4]
                      , [$lit_1, 5]
                    ]
                ]
              , [      # state 7    b & 111 = 111
                    1  # accepting
                  , [
                        [$lit_0, 6]
                      , [$lit_1, 7]
                    ]
                ]
            ]
          , [ # second nfa
                [      # state 0    b & 111 = 000
                    0  # rejecting
                  , [
                        [$lit_0, 0]
                      , [$lit_1, 1]
                    ]
                ]
              , [      # state 1    b & 111 in (001, 101)
                    0  # rejecting
                  , [
                        [$lit_0, 2]
                      , [$lit_1, 3]
                    ]
                ]
              , [      # state 2    b & 111 = 010
                    0  # rejecting
                  , [
                        [$lit_0, 6]
                      , [$lit_1, 1]
                    ]
                ]
              , [      # state 3    b & 111 = 011
                    0  # rejecting
                  , [
                        [$lit_0, 4]
                      , [$lit_1, 5]
                    ]
                ]
              , [      # state 4    b & 111 = 110
                    1  # accepting
                  , [
                        [$lit_0, 6]
                      , [$lit_1, 1]
                    ]
                ]
              , [      # state 5    b & 111 = 111
                    1  # accepting
                  , [
                        [$lit_0, 4]
                      , [$lit_1, 5]
                    ]
                ]
              , [      # state 6    b & 111 = 100
                    1  # accepting
                  , [
                        [$lit_0, 0]
                      , [$lit_1, 1]
                    ]
                ]
            ]
        ]

        # nfa pair
      , [
            [ # first nfa
                [      # state 0
                    0  # rejecting
                  , [
                        [$lit_a, 1]
                      , [$lit_b, 2]
                    ]
                ]
              , [      # state 1
                    0  # rejecting
                  , [
                        [$lit_a, 3]
                      , [$lit_b, 2]
                    ]
                ]
              , [      # state 2
                    0  # rejecting
                  , [
                        [$lit_a, 4]
                      , [$lit_b, 1]
                    ]
                ]
              , [      # state 3
                    1  # accepting
                  , [
                        [$lit_a, 4]
                      , [$lit_b, 2]
                    ]
                ]
              , [      # state 4
                    1  # accepting
                  , [
                        [$lit_a, 3]
                      , [$lit_b, 1]
                    ]
                ]
            ]
          , [ # second nfa
                [      # state 0
                    0  # rejecting
                  , [
                        [cc_union($lit_a, $lit_b), 1 ]
                    ]
                ]
              , [      # state 1
                    0  # rejecting
                  , [
                        [$lit_a, 2]
                      , [$lit_b, 1]
                    ]
                ]
              , [      # state 2
                    1  # accepting
                  , [
                        [$lit_a, 2]
                      , [$lit_b, 1]
                    ]
                ]
            ]
        ]

    );
}

use Test::More tests => scalar(@nfa_pairs);

for my $nfa_pair (@nfa_pairs) {
    my ($nfa1, $nfa2) = @$nfa_pair;
    my $dfa1 = nfa_to_min_dfa($nfa1);
    my $dfa2 = nfa_to_min_dfa($nfa2);
    ok(
        nfa_isomorph($dfa1, $dfa2)
      , 'nfas equivalent: '
      . nfa_to_regex($nfa1) . ' ~ ' . nfa_to_regex($nfa2)
    );
}

