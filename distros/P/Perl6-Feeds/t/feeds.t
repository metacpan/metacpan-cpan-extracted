#!/usr/bin/perl -w
use strict;
use Test::Simple tests => 6;

BEGIN {push @INC, '../lib'}
use Perl6::Feeds;

ok 'A' eq ('a' ==> uc)[0], 'single feed';

ok  join(" " => grep {$_>10} map {$_**2} 1..10) eq
        (1..10 ==> map {$_**2} ==> grep {$_>10} ==> join " ")[0],
    'multi feed';

ok  join( ", ", 1..5, reverse 1..4 ) eq
        (1..5, (1..4 ==> reverse) ==> join ", ")[0],
    'complex single line';

1..5 ==> my @a;

ok "@a" eq '1 2 3 4 5', 'assignment';

6..10 ==>> @a;

ok "@a" eq '1 2 3 4 5 6 7 8 9 10', 'push';

ok join( '' => (
1 .. 3000
    ==> map [$_, $_ ** 2 ]
    ==> grep {$$_[1] =~ s/(([^0])\2{3,})/ ($1) /g}
    ==> our @list
    ==> map {@$_ ==> map "[$_]"
                 ==> join '^2 ==> '}
    ==>>< "\nnumbers with squares containing " .
         "non zero runs of 4+ digits:\n"
    ==>>> "\nfound ".@list.' numbers: '
    ==>  join ("\n")
    ==>>> (@list ==> map $$_[0] ==> join ' ')
    ===>>> "\n"
)) eq <<'END', 'complex multi line';

numbers with squares containing non zero runs of 4+ digits:

[1291]^2 ==> [1 (6666) 81]
[1609]^2 ==> [25 (8888) 1]
[1633]^2 ==> [2 (6666) 89]
[2357]^2 ==> [ (5555) 449]
[2582]^2 ==> [ (6666) 724]
[2848]^2 ==> [8 (1111) 04]

found 6 numbers: 1291 1609 1633 2357 2582 2848
END
