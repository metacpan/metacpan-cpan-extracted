use strict;
use warnings;

use Test::More 0.88;
use Statistics::RankOrder;

#--------------------------------------------------------------------------#
# Test Data
#--------------------------------------------------------------------------#

my %cases = (
    "median w/o ties" => [
        [
            [qw( A B E C D )], [qw( B A E D C )], [qw( A D B E C )], [qw( D E B A C )],
            [qw( A B C D E )],
        ],
        {
            A => 1,
            B => 2,
            C => 5,
            D => 4,
            E => 3,
        }
    ],
    "tie break w/ size of majority" => [
        [
            [qw( A C E B D )], [qw( B A E D C )], [qw( A D B E C )], [qw( D E B A C )],
            [qw( A B C D E )],
        ],
        {
            A => 1,
            B => 2,
            C => 5,
            D => 4,
            E => 3,
        }
    ],
    "tie break w/ total ordinals of majority" => [
        [
            [qw( A C E B D )], [qw( B A E D C )], [qw( A D B E C )], [qw( D E B A C )],
            [qw( A B E D C )],
        ],
        {
            A => 1,
            B => 2,
            C => 5,
            D => 4,
            E => 3,
        }
    ],
    "tie break w/ total ordinals" => [
        [
            [qw( A B E D C )], [qw( B A E C D )], [qw( D B A C E )], [qw( E D A B C )],
            [qw( C A B E D )],
        ],
        {
            A => 1,
            B => 2,
            C => 5,
            D => 4,
            E => 3,
        }
    ],
    "all tie first" => [
        [
            [qw( A E D C B )], [qw( B A E D C )], [qw( C B A E D )], [qw( D C B A E )],
            [qw( E D C B A )],
        ],
        {
            A => 1,
            B => 1,
            C => 1,
            D => 1,
            E => 1,
        }
    ],
);

plan tests => scalar keys %cases;

while ( my ( $label, $case ) = each(%cases) ) {
    my ( $judges, $ranks ) = @$case;
    my $obj = Statistics::RankOrder->new();
    $obj->add_judge($_) for @$judges;
    my $mr = { $obj->best_majority_rank() };
    is_deeply( $mr, $ranks, "is best_majority_rank() correct for '$label'" )
      or diag explain { got => $mr, expected => $ranks };
}

