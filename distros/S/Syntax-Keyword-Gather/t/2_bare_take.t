#!perl
use strict;
use warnings;

use Test::More tests => 8;
use Syntax::Keyword::Gather;

# instructive example
my @numbers_with_two = gather {
    for (1..20) {
        take if /2/
    }
};
ok eq_array(
    [@numbers_with_two],
    [2,12,20],
), 'bare take works';


# tests copied from 1.t to show they all work without $_
ok eq_array(
   [gather { take for 1..10; take 99 }],
   [1..10, 99],
), 'basic gather works (bare take)' ;
ok eq_array(
   [gather { take for 1..10; take 99 unless gathered }],
   [1..10],
), 'gathered works with bare take in boolean context (true)';
ok eq_array(
   [gather { take for 1..10; pop @{+gathered} }],
   [1..9]
), 'gathered allows modification of underlying data with bare take';


# some special tests
ok eq_array(
    [gather { take for (undef, undef)}],
    [undef, undef]
), 'undef gathers';

# as a warning: never forget to take the loop variable or you are
# taking $_ magically..
$_ = 99;
ok eq_array(
    [
        gather {
            for my $i (1..2) {
                take
            }
        }
    ],
    [99, 99]
), 'takes 99 because hacker forgot to "take $i"';

# and also inside loop..
ok eq_array(
    [
        gather {
            for my $i (1..2) {
                $_ = $i *2;
                take;
            }
        }
    ],
    [2,4]
), 'taking manipulated $_ instead of (possibly intended $i)';


# and, rather as a question:

# not sure if this is wanted behaviour
is(
    gather { take undef },
    '',
    'take: undef becomes ""');



