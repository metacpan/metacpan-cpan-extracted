#!perl -w
use strict;
use Test::Tester;
use Test::More;
use Time::Piece;

use Test::Deep;
use Test::Deep::Between;

sub generate_time_piece {
    my $mysql_format = shift;
    return Time::Piece->strptime($mysql_format, '%Y-%m-%d %T');
}

my $check_hash = {
    hoge => generate_time_piece('2000-01-01 12:00:00'),
};

check_test(
    sub {
        cmp_deeply $check_hash, {
            hoge => between(
                generate_time_piece('2000-01-01 00:00:00'),
                generate_time_piece('2000-01-02 00:00:00')
            ),
        };
    },
    {
        actual_ok => 1,
        diag => '',
    },
    'got is in 2000-01-01 00:00:00 to 2000-01-02 00:00:00'
);

check_test(
    sub {
        cmp_deeply $check_hash, {
            hoge => between(
                generate_time_piece('2000-01-02 00:00:00'),
                generate_time_piece('2000-01-03 00:00:00')
            ),
        };
    },
    {
        actual_ok => 0,
        diag => '$data->{"hoge"} is not in Sun Jan  2 00:00:00 2000 to Mon Jan  3 00:00:00 2000.',
    },
    'got is not in 2000-01-02 00:00:00 to 2000-01-03 00:00:00'
);


done_testing;
