use strict;
use warnings FATAL => 'all';
use Test::More;

use Moment;

sub main_in_test {

    my $tests = [
        {
            iso_string => '1800-01-01T00:00:00Z',
            dt => '1800-01-01 00:00:00',
            d => '1800-01-01',
            t => '00:00:00',
            timestamp => -5364662400,
            year => 1800,
            month => 1,
            day => 1,
            hour => 0,
            minute => 0,
            second => 0,
            weekday => 'wednesday',
            month_start_dt => '1800-01-01 00:00:00',
            month_end_dt => '1800-01-31 23:59:59',
        },
        {
            iso_string => '1970-01-01T00:00:00Z',
            dt => '1970-01-01 00:00:00',
            d => '1970-01-01',
            t => '00:00:00',
            timestamp => 0,
            year => 1970,
            month => 1,
            day => 1,
            hour => 0,
            minute => 0,
            second => 0,
            weekday => 'thursday',
            month_start_dt => '1970-01-01 00:00:00',
            month_end_dt => '1970-01-31 23:59:59',
        },
        {
            iso_string => '1999-02-03T01:02:03Z',
            dt => '1999-02-03 01:02:03',
            d => '1999-02-03',
            t => '01:02:03',
            timestamp => 918003723,
            year => 1999,
            month => 2,
            day => 3,
            hour => 1,
            minute => 2,
            second => 3,
            weekday => 'wednesday',
            month_start_dt => '1999-02-01 00:00:00',
            month_end_dt => '1999-02-28 23:59:59',
        },
        {
            iso_string => '1999-02-28T01:02:03Z',
            dt => '1999-02-28 01:02:03',
            d => '1999-02-28',
            t => '01:02:03',
            timestamp => 920163723,
            year => 1999,
            month => 2,
            day => 28,
            hour => 1,
            minute => 2,
            second => 3,
            weekday => 'sunday',
            month_start_dt => '1999-02-01 00:00:00',
            month_end_dt => '1999-02-28 23:59:59',
        },
        {
            iso_string => '2000-02-03T01:02:03Z',
            dt => '2000-02-03 01:02:03',
            d => '2000-02-03',
            t => '01:02:03',
            timestamp => 949539723,
            year => 2000,
            month => 2,
            day => 3,
            hour => 1,
            minute => 2,
            second => 3,
            weekday => 'thursday',
            month_start_dt => '2000-02-01 00:00:00',
            month_end_dt => '2000-02-29 23:59:59',
        },
        {
            iso_string => '2000-02-29T01:02:03Z',
            dt => '2000-02-29 01:02:03',
            d => '2000-02-29',
            t => '01:02:03',
            timestamp => 951786123,
            year => 2000,
            month => 2,
            day => 29,
            hour => 1,
            minute => 2,
            second => 3,
            weekday => 'tuesday',
            month_start_dt => '2000-02-01 00:00:00',
            month_end_dt => '2000-02-29 23:59:59',
        },
        {
            iso_string => '2014-11-29T23:44:10Z',
            dt => '2014-11-29 23:44:10',
            d => '2014-11-29',
            t => '23:44:10',
            timestamp => 1417304650,
            year => 2014,
            month => 11,
            day => 29,
            hour => 23,
            minute => 44,
            second => 10,
            weekday => 'saturday',
            month_start_dt => '2014-11-01 00:00:00',
            month_end_dt => '2014-11-30 23:59:59',
        },
        {
            iso_string => '2014-07-03T01:02:03Z',
            dt => '2014-07-03 01:02:03',
            d => '2014-07-03',
            t => '01:02:03',
            timestamp => 1404349323,
            year => 2014,
            month => 7,
            day => 3,
            hour => 1,
            minute => 2,
            second => 3,
            weekday => 'thursday',
            month_start_dt => '2014-07-01 00:00:00',
            month_end_dt => '2014-07-31 23:59:59',
        },
        {
            iso_string => '2199-12-31T23:59:59Z',
            dt => '2199-12-31 23:59:59',
            d => '2199-12-31',
            t => '23:59:59',
            timestamp => 7258118399,
            year => 2199,
            month => 12,
            day => 31,
            hour => 23,
            minute => 59,
            second => 59,
            weekday => 'tuesday',
            month_start_dt => '2199-12-01 00:00:00',
            month_end_dt => '2199-12-31 23:59:59',
        },
    ];

    foreach my $test (@{$tests}) {
        my $moments = [
            Moment->new( iso_string => $test->{iso_string} ),
            Moment->new( timestamp => $test->{timestamp} ),
            Moment->new( dt => $test->{dt} ),
            Moment->new(
                year => $test->{year},
                month => $test->{month},
                day => $test->{day},
                hour => $test->{hour},
                minute => $test->{minute},
                second => $test->{second},
            ),
        ];

        foreach my $moment (@{$moments}) {
            is($moment->get_iso_string(), $test->{iso_string}, 'get_iso_string()');
            is($moment->get_timestamp(), $test->{timestamp}, 'get_timestamp()');
            is($moment->get_dt(), $test->{dt}, 'get_dt()');
            is($moment->get_d(), $test->{d}, 'get_d()');
            is($moment->get_t(), $test->{t}, 'get_t()');

            is($moment->get_year(), $test->{year}, 'get_year()');
            is($moment->get_month(), $test->{month}, 'get_month()');
            is($moment->get_day(), $test->{day}, 'get_day()');
            is($moment->get_hour(), $test->{hour}, 'get_hour()');
            is($moment->get_minute(), $test->{minute}, 'get_minute()');
            is($moment->get_second(), $test->{second}, 'get_second()');

            is($moment->get_weekday_name(), $test->{weekday}, 'get_weekday_name()');

            is($moment->get_month_start()->get_dt(), $test->{month_start_dt}, 'get_month_start()');
            is($moment->get_month_end()->get_dt(), $test->{month_end_dt}, 'get_month_end()');
        }

    }

    done_testing;

}
main_in_test();
