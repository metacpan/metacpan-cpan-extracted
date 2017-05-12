use strict;
use warnings FATAL => 'all';
use Test::More;

use Moment;

sub main_in_test {

    my @leap_years = qw(
        1804
        2000
        2008
        2196
    );

    my @not_leap_years = qw(
        1800
        1801
        2001
    );

    foreach my $year (@leap_years) {
        ok(
            Moment->new(
                year => $year,
                month => 1,
                day => 1,
                hour => 0,
                minute => 0,
                second => 0,
            )->is_leap_year(),
            "$year is leap year",
        );
    }

    foreach my $year (@not_leap_years) {
        ok(
            !Moment->new(
                year => $year,
                month => 1,
                day => 1,
                hour => 0,
                minute => 0,
                second => 0,
            )->is_leap_year(),
            "$year is not leap year",
        );
    }

    done_testing;

}
main_in_test();
