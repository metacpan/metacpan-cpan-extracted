use strict;
use warnings;

use Test::More;
use Statistics::RankOrder;

#--------------------------------------------------------------------------#
# Test Data
#--------------------------------------------------------------------------#

my %cases = (
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
    "tie for 3rd" => [
        [
            [qw( A B C D E )], [qw( B A E D C )], [qw( B C A E D )], [qw( D E B A C )],
            [qw( A B C D E )],
        ],
        {
            A => 2,
            B => 1,
            C => 3,
            D => 3,
            E => 5,
        }
    ],
);

plan tests => scalar keys %cases;

while ( my ( $label, $case ) = each(%cases) ) {
    my ( $judges, $ranks ) = @$case;
    my $obj = Statistics::RankOrder->new();
    $obj->add_judge($_) for @$judges;
    is_deeply( { $obj->mean_rank }, $ranks, "is mean_rank() correct for '$label'" );
}

