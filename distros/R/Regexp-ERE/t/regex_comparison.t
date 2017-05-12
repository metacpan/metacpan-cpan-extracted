use strict;
use warnings;

use Regexp::ERE qw(
    &ere_to_nfa
    &nfa_isomorph
    &nfa_to_min_dfa
);

our @ere_pairs;
BEGIN {
    @ere_pairs = (
        ['^[ab]*$', '^[ab]*a*$']
      , ['^[ab]*$', '^a*[ab]*$']
      , ['^[ab]*$', '^([ab]a*)*$']
      , ['^[ab]*$', '^(a*|[ab]*)$']
      , ['^[ab]*$', '^(a|b)*(b|)a*$']
      , ['^[ab]*$', '^(a|b)*(a|)*$']
      , ['^[ab]*$', '^((a|b)*(a|)*|(a|b)*(b|)a*)$']
      , ['a*b*c*', '.*']
      , ['$^$^', '^$']
      , ['^($x)*$', '^$']
      , ['^a{3,5}$', '^aa?aaa?$']
      , ['^a{3,5}$', '^aa{1,3}a$']
      , ['^a{3,}$', '^aa+a$']
      , ['^a{3,}$', '^aa*aa$']
      , ['^(a*ab)*$', '^(aa*b)*$']
      , ['^(a*ab)*$', '^(a+b)*$']
    );
}

use Test::Simple tests => scalar(@ere_pairs);

for my $ere_pair (@ere_pairs) {
   my ($ere1, $ere2) = @$ere_pair;
   my ($min_dfa1, $min_dfa2)
     = map { nfa_to_min_dfa(ere_to_nfa($_)) }
       ($ere1, $ere2)
   ;
    ok(
        nfa_isomorph($min_dfa1, $min_dfa2)
      , "ere equivalent: $ere1 ~ $ere2"
    );
}
