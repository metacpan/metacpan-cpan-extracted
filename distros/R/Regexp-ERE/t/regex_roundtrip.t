use strict;
use warnings;

use Regexp::ERE qw(
    &ere_to_nfa
    &nfa_to_regex
    &nfa_isomorph
    &nfa_to_min_dfa
);

our @eres;
BEGIN {
    @eres = (
        '^a$'
      , '^((a)*)*$'
      , '^(()())()$'
      , '^(a|)$'
      , '^(|a)$'
      , '^(a*|b*)c*def$'
      , '^a*()a*$'
      , '^[ab]*a*$'
      , '^a*[ab]*$'
      , '^([ab]a*)*$'
      , '^(a|b)*(a|)*$'
      , '^(ab|cd)*(ef)?$'
      , '^(a*|a*)$'
      , '^(a*a?)$'
      , '^(a*|[ab]*)$'
      , '^(a|b)*(b|)a*$'
      , '^((a|b)*(a|)*|(a|b)*(b|)a*)$'
      , '^(|)$'
      , '^((ab*|ac*)*)$'
      , '^(ab|cd)-(01|23)$'
      , '(^a)*b$'
      , '(^a)+b$'
      , '.*'
      , '^.*$'
      , '^((aa(bb|cc))|(dd(ee|ff)))((11(22|33))|(44(55|66)))$'
      , '^(x[ab]*|y[ac]*|z[bc]*)a*c$'
      , '$.'
      , '^((xy)*|a){0,3}$'
      , '^a*$'
      , '^(a*)*$'
      , '^(a*b)*$'
      , '^(a*b)?(cd|ef)$'
      , '^(a*b)*(cd|ef)$'
      , '(ab)*(cd|ef)$'
      , '^(ab)*(cd|ef)$'
      , '$^$^'
      , '(a*b)*$'
    );
}

use Test::Simple tests => scalar(@eres);

for my $ere (@eres) {
    my $nfa = ere_to_nfa($ere);
    my $min_dfa = nfa_to_min_dfa($nfa);

    my $ere2 = nfa_to_regex($min_dfa);
    my $nfa2 = ere_to_nfa($ere2);
    my $min_dfa2 = nfa_to_min_dfa($nfa2);

    ok(
        nfa_isomorph($min_dfa, $min_dfa2)
      , "regex roundtrip: $ere"
    );
}
