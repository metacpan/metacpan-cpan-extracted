#!perl
#
# Recursion

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Music::RecRhythm;

my @suite = (
    # sub-rhythm divides perfectly into parent
    {   sets => [ [ 2, 2 ], [ 1, 1 ] ],
        audible_levels => 2,
        levels         => 2,
        # TODO would like to if possible have the min factor on the
        # numbers for this special case, but for now getting
        # proportional durations in other cases slightly more important
        beatfactor => 8,
        durations  => [ [ 4, 4 ], [ 2, 2, 2, 2 ] ],
    },
    # sub-rhythm smaller (3 vs 7) or larger (3 vs 1) than beats of parent
    {   sets => [ [ 7, 1 ], [ 2, 1 ] ],
        audible_levels => 2,
        beatfactor     => 168,
        levels         => 2,
        durations      => [ [ 147, 21 ], [ 98, 49, 14, 7 ] ],
    },
    # audibility
    {   sets => [ [1], [1], [1], [ 1, 1 ] ],
        audible_levels => 1,
        beatfactor     => 2,
        levels         => 4,
        durations      => [ undef, undef, undef, [ 1, 1 ] ],
        silent         => { 0 => 1, 1 => 1, 2 => 1 },
    },
    # same pattern at increasing depth - a problem for beatfactor given
    # blcm() gets the same (1,2,12) input at each level and does not
    # account for depth :/
    {   sets => [ [ 2, 2, 1, 2, 2, 2, 1 ], [ 2, 2, 1, 2, 2, 2, 1 ] ],
        audible_levels => 2,
        beatfactor     => 144,
        levels         => 2,
        durations      => [
            [ 24, 24, 12, 24, 24, 24, 12 ],
            [   4, 4, 2, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 2, 2, 2, 1, 2, 2, 2, 1, 4, 4, 2, 4, 4,
                4, 2, 4, 4, 2, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 2, 2, 2, 1, 2, 2, 2, 1,
            ]
        ],
    },
    {   sets =>
          [ [ 2, 2, 1, 2, 2, 2, 1 ], [ 2, 2, 1, 2, 2, 2, 1 ], [ 2, 2, 1, 2, 2, 2, 1 ] ],
        beatfactor     => 1728,
        audible_levels => 3,
        levels         => 3,
        durations      => [
            [ 288, 288, 144, 288, 288, 288, 144 ],
            [   48, 48, 24, 48, 48, 48, 24, 48, 48, 24, 48, 48, 48, 24, 24, 24, 12, 24,
                24, 24, 12, 48, 48, 24, 48, 48, 48, 24, 48, 48, 24, 48, 48, 48, 24, 48,
                48, 24, 48, 48, 48, 24, 24, 24, 12, 24, 24, 24, 12
            ],
            [   8, 8, 4, 8, 8, 8, 4, 8, 8, 4, 8, 8, 8, 4, 4, 4, 2, 4, 4, 4, 2, 8, 8, 4, 8, 8,
                8, 4, 8, 8, 4, 8, 8, 8, 4, 8, 8, 4, 8, 8, 8, 4, 4, 4, 2, 4, 4, 4, 2, 8, 8, 4,
                8, 8, 8, 4, 8, 8, 4, 8, 8, 8, 4, 4, 4, 2, 4, 4, 4, 2, 8, 8, 4, 8, 8, 8, 4, 8,
                8, 4, 8, 8, 8, 4, 8, 8, 4, 8, 8, 8, 4, 4, 4, 2, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4,
                2, 4, 4, 2, 4, 4, 4, 2, 2, 2, 1, 2, 2, 2, 1, 4, 4, 2, 4, 4, 4, 2, 4, 4, 2, 4,
                4, 4, 2, 4, 4, 2, 4, 4, 4, 2, 2, 2, 1, 2, 2, 2, 1, 8, 8, 4, 8, 8, 8, 4, 8, 8,
                4, 8, 8, 8, 4, 4, 4, 2, 4, 4, 4, 2, 8, 8, 4, 8, 8, 8, 4, 8, 8, 4, 8, 8, 8, 4,
                8, 8, 4, 8, 8, 8, 4, 4, 4, 2, 4, 4, 4, 2, 8, 8, 4, 8, 8, 8, 4, 8, 8, 4, 8, 8,
                8, 4, 4, 4, 2, 4, 4, 4, 2, 8, 8, 4, 8, 8, 8, 4, 8, 8, 4, 8, 8, 8, 4, 8, 8, 4,
                8, 8, 8, 4, 4, 4, 2, 4, 4, 4, 2, 8, 8, 4, 8, 8, 8, 4, 8, 8, 4, 8, 8, 8, 4, 4,
                4, 2, 4, 4, 4, 2, 8, 8, 4, 8, 8, 8, 4, 8, 8, 4, 8, 8, 8, 4, 8, 8, 4, 8, 8, 8,
                4, 4, 4, 2, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 2, 2, 2, 1, 2,
                2, 2, 1, 4, 4, 2, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 2, 2, 2,
                1, 2, 2, 2, 1,
            ]
        ],
    },
    #{   sets => [
    #        [ 2, 2, 1, 2, 2, 2, 1 ],
    #        [ 2, 2, 1, 2, 2, 2, 1 ],
    #        [ 2, 2, 1, 2, 2, 2, 1 ],
    #        [ 2, 2, 1, 2, 2, 2, 1 ]
    #    ],
    #    audible_levels => 4,
    #    beatfactor => 20736,
    #    levels     => 4,
    #    durations  => [...],
    #},
);

my $testidx = 0;
for my $sref (@suite) {
    my @rrs;
    my $set_idx = 0;
    for my $set ( @{ $sref->{sets} } ) {
        push @rrs, Music::RecRhythm->new( set => $set );
        $rrs[-2]->next( $rrs[-1] ) if @rrs > 1;
        $rrs[-1]->is_silent(1) if $sref->{silent}{$set_idx};
        $set_idx++;
    }
    is( $rrs[0]->beatfactor, $sref->{beatfactor},
        "beatfactor for suite[$testidx]" );
    is( $rrs[0]->levels, $sref->{levels}, "levels for suite[$testidx]" );
    is( $rrs[0]->audible_levels,
        $sref->{audible_levels},
        "audible levels for suite[$testidx]"
    );
    my @durations;
    $rrs[0]->recurse(
        sub {
            my ( $rset, $param, $durs ) = @_;
            push @{ $durs->[ $param->{level} ] }, $param->{duration};
        },
        \@durations
    );
    $deeply->(
        \@durations, $sref->{durations}, "recursion results for suite[$testidx]"
    );
    $testidx++;
}

plan tests => 4 * @suite;
