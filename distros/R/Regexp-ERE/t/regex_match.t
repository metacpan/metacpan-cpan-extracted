use strict;
use warnings;

use Regexp::ERE qw(
   &ere_to_nfa
   &nfa_to_regex
   &nfa_match
);

our @ere_strings_ok_strings_nok_list;
our $num_tests;
BEGIN {
    use utf8;
    @ere_strings_ok_strings_nok_list = (
        [
            '^(Россия|Ελλάδα)$'
          , ['Россия', 'Ελλάδα']
          , [
                'Россия suffix', 'Ελλάδα suffix'
              , 'prefix Россия', 'prefix Ελλάδα'
              , 'оссия', 'λλάδα'
              , 'Росси', 'Ελλάδ'
              , 'Russia', 'Greece'
            ]
        ]
      , [
            'rs\tuv'
          , ['xrstuvy']
          , ['xrs\\tuvy', "xrs\tuvy"]
        ]
      , [
            '.^'
          , []
          , ['']
        ]
      , [
            '$.'
          , []
          , ['']
        ]
      , [
            '$^^$'
          , ['']
          , ['x']
        ]
    );
    $num_tests = 0;
    for (@ere_strings_ok_strings_nok_list) {
        $num_tests += 2 * (@{$$_[1]} + @{$$_[2]});
    }
}


use Test::Simple tests => $num_tests;

my $builder = Test::Simple->builder;
binmode($builder->output        , ':encoding(UTF-8)');
binmode($builder->failure_output, ':encoding(UTF-8)');
binmode($builder->todo_output   , ':encoding(UTF-8)');

for my $ere_strings_ok_strings_nok (@ere_strings_ok_strings_nok_list) {
    my $ere = $$ere_strings_ok_strings_nok[0];
    my $nfa = ere_to_nfa($ere);
    my $perlre = nfa_to_regex($nfa, 1);
    for my $string_ok (@{$$ere_strings_ok_strings_nok[1]}) {
        ok(
            nfa_match($nfa, $string_ok)
          , "ere match $ere against '$string_ok'"
        );
        ok(
            $string_ok =~ $perlre
          , "perlre match $perlre against '$string_ok'"
        );
    }
    for my $string_nok (@{$$ere_strings_ok_strings_nok[2]}) {
        ok(
            !nfa_match($nfa, $string_nok)
          , "ere no match $ere against '$string_nok'"
        );
        ok(
            $string_nok !~ $perlre
          , "perlre no match $perlre against '$string_nok'"
        );
    }
}
