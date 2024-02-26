#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Set::Streak qw(gen_longest_streaks_table);

subtest "gen_longest_streaks_table" => sub {
    subtest "basics" => sub {
        my $res = gen_longest_streaks_table(
            sets => [
                [qw/A B C D E/],
                [qw/B C D E F/],
                [qw/B D E G/],
                [qw/B H/],
            ],
        );
        is_deeply($res, [
            {item=>"B", start=>1, len=>4, status=>"ongoing"},
            {item=>"D", start=>1, len=>3, status=>"might-break"},
            {item=>"E", start=>1, len=>3, status=>"might-break"},
            {item=>"C", start=>1, len=>2, status=>"broken"},
            {item=>"A", start=>1, len=>1, status=>"broken"},
            {item=>"F", start=>2, len=>1, status=>"broken"},
            {item=>"G", start=>3, len=>1, status=>"might-break"},
            {item=>"H", start=>4, len=>1, status=>"ongoing"},
        ]) or diag explain $res;
    };

    subtest "arg:exclude_broken" => sub {
        my $res = gen_longest_streaks_table(
            sets => [
                [qw/A B C D E/],
                [qw/B C D E F/],
                [qw/B D E G/],
                [qw/B H/],
            ],
            exclude_broken => 1,
        );
        is_deeply($res, [
            {item=>"B", start=>1, len=>4, status=>"ongoing"},
            {item=>"D", start=>1, len=>3, status=>"might-break"},
            {item=>"E", start=>1, len=>3, status=>"might-break"},
            {item=>"G", start=>3, len=>1, status=>"might-break"},
            {item=>"H", start=>4, len=>1, status=>"ongoing"},
        ]) or diag explain $res;
    };

    subtest "arg:raw" => sub {
        my $res = gen_longest_streaks_table(
            sets => [
                [qw/A B C D E/],
                [qw/B C D E F/],
                [qw/B D E G A/],
                [qw/B H/],
            ],
            raw => 1,
        );
        is_deeply($res, {
            '1.A' => [1,2],
            '1.B' => [4,undef],
            '1.C' => [2,3],
            '1.D' => [3,4],
            '1.E' => [3,4],
            '2.F' => [1,3],
            '3.A' => [1,4],
            '3.G' => [1,4],
            '4.H' => [1,undef],
        }) or diag explain $res;
    };

    subtest "arg:streaks & arg:start_period" => sub {
        my $streaks = {
            '1.A' => [1,2],
            '1.B' => [4,undef],
            '1.C' => [2,3],
            '1.D' => [3,4],
            '1.E' => [3,4],
            '2.F' => [1,3],
            '3.A' => [1,4],
            '3.G' => [1,4],
            '4.H' => [1,undef],
        };

        # update periode 4 & add periode 5
        my $res = gen_longest_streaks_table(
            sets => [
                [qw/B H I/], # periode 4: add I
                [qw/H J/],   # periode 5
            ],
            streaks => $streaks,
            start_period => 4,
            raw => 1,
        );
        is_deeply($res, {
            '1.A' => [1,2],
            '1.B' => [4,5],
            '1.C' => [2,3],
            '1.D' => [3,4],
            '1.E' => [3,4],
            '2.F' => [1,3],
            '3.A' => [1,4],
            '3.G' => [1,4],
            '4.H' => [2,undef],
            '4.I' => [1,5],
            '5.J' => [1,undef],
        }) or diag explain $res;

        $streaks = $res;

        # add periode 6
        my $res = gen_longest_streaks_table(
            sets => [
                [qw/J K/], # periode 6
            ],
            streaks => $streaks,
            start_period => 6,
            raw => 1,
        );
        is_deeply($res, {
            '1.A' => [1,2],
            '1.B' => [4,5],
            '1.C' => [2,3],
            '1.D' => [3,4],
            '1.E' => [3,4],
            '2.F' => [1,3],
            '3.A' => [1,4],
            '3.G' => [1,4],
            '4.H' => [2,6],
            '4.I' => [1,5],
            '5.J' => [2,undef],
            '6.K' => [1,undef],
        }) or diag explain $res;

    };
};

DONE_TESTING:
done_testing;
