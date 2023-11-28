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
};

DONE_TESTING:
done_testing;
