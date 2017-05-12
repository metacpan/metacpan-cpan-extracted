use strict;
use warnings;

use Regexp::ERE qw(
    &ere_to_nfa
    &nfa_concat
    &nfa_isomorph
    &nfa_to_min_dfa
    &nfa_to_regex
    &char_to_cc
);

our @trees;
BEGIN {
    our @trees = (
        # empty string
        $Regexp::ERE::cc_none

        # single char
      , char_to_cc('a')

        # empty string (longer tree representation)
      , [ 0, [] ]

        # starified word (ab)*
      , [ 1, [[char_to_cc('a'), char_to_cc('b')]] ]

        # non-starified word (ab)
      , [ 0, [[char_to_cc('a'), char_to_cc('b')]] ]
    );
}

use Test::Simple tests => scalar(@trees) * scalar(@trees);

for my $tree_0 (@trees) {
for my $tree_1 (@trees) {
    my $dfa1 = nfa_to_min_dfa(ere_to_nfa(
        '^'
      . Regexp::ERE::tree_dump(Regexp::ERE::tree_concat2(
            $tree_0
          , $tree_1
        ))
      . '$'
    ));
    my $dfa2 = nfa_to_min_dfa(nfa_concat(ere_to_nfa(
        '^'
      . Regexp::ERE::tree_dump($tree_0)
      . Regexp::ERE::tree_dump($tree_1)
      . '$'
    )));
    ok(nfa_isomorph($dfa1, $dfa2)
      , 'tree concatenation:'
      . " '" . Regexp::ERE::tree_dump($tree_0) . "'"
      . " concat"
      . " '" . Regexp::ERE::tree_dump($tree_1) . "'"
      . ', exp: ' . nfa_to_regex($dfa1)
      . ', got: ' . nfa_to_regex($dfa2)
    );
}}
