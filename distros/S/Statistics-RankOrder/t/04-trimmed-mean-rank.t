use strict;
use warnings;

use Test::More;
use Statistics::RankOrder;

#--------------------------------------------------------------------------#
# Test Data
#--------------------------------------------------------------------------#

my %cases = (
    "N = 0" => [
        [
            [qw( A B C D E )], [qw( B A E D C )], [qw( B C A E D )], [qw( D E B A C )],
            [qw( A B C D E )],
        ],
        0,
        {
            A => 2,
            B => 1,
            C => 3,
            D => 3,
            E => 5,
        }
    ],
    "N = 1" => [
        [
            [qw( A B C D E )], [qw( B A E D C )], [qw( B C A E D )], [qw( D E B A C )],
            [qw( A B C D E )],
        ],
        1,
        {
            A => 2,
            B => 1,
            C => 3,
            D => 4,
            E => 4,
        }
    ],
    "N = 2" => [
        [
            [qw( A B C D E )], [qw( B A E D C )], [qw( B C A E D )], [qw( D E B A C )],
            [qw( A B C D E )],
        ],
        2,
        {
            A => 1,
            B => 1,
            C => 3,
            D => 4,
            E => 4,
        }
    ],
);

plan tests => 1 + scalar keys %cases;

while ( my ( $label, $case ) = each(%cases) ) {
    my ( $judges, $trim, $ranks ) = @$case;
    my $obj = Statistics::RankOrder->new();
    $obj->add_judge($_) for @$judges;
    is_deeply( { $obj->trimmed_mean_rank($trim) },
        $ranks, "is trim_mean_rank(N) correct for '$label'" );
}

while ( my ( $label, $case ) = each(%cases) ) {
    my ( $judges, $trim, $ranks ) = @$case;
    my $obj = Statistics::RankOrder->new();
    $obj->add_judge($_) for @$judges;
    eval { $obj->trimmed_mean_rank( 2 * @$judges ) };
    ok( $@, "dies if too much is trimmed" );
    last; # we really only need 1
}

