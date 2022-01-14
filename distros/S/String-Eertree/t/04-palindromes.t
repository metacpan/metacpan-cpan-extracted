#! /usr/bin/perl
use Test2::V0;

use String::Eertree;
plan 2;

{   my $tree = 'String::Eertree'->new(string => 'referee');
    is  [$tree->palindromes],
        bag { item $_ for qw( r e f e r e e ee efe ere refer );
              end() },
        'referee';
}

{   my $tree = 'String::Eertree'->new(string => 'abcbabcba');
    is  [$tree->palindromes],
        bag { item $_ for qw( a b c b a b c b a
                              bcb bcb bab cbabc abcba abcba bcbabcb abcbabcba );
              end() },
        'abcbabcba';
}
