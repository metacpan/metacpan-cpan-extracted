use strict;
use warnings FATAL => 'all';
use Test::More;

use Moment;

sub main_in_test {

    my $data = [
        {
            timestamp => 0,
            dt => '1970-01-01 00:00:00',
        },
        {
            timestamp => 1,
            dt => '1970-01-01 00:00:01',
        },
        {
            timestamp => -1,
            dt => '1969-12-31 23:59:59',
        },
        {
            timestamp => 1000000000,
            dt => '2001-09-09 01:46:40',
        },
        {
            timestamp => -5364662400,
            dt => '1800-01-01 00:00:00',
        },
        {
            timestamp => 7258118399,
            dt => '2199-12-31 23:59:59',
        },
    ];

    foreach my $element (@{$data}) {
        my $timestamp_moment = Moment->new( timestamp => $element->{timestamp});
        is( $timestamp_moment->get_dt(), $element->{dt}, "$element->{timestamp} => $element->{dt}");

        my $dt_moment = Moment->new( dt => $element->{dt});
        is( $dt_moment->get_timestamp(), $element->{timestamp}, "$element->{dt} => $element->{timestamp}");

    }

    done_testing();
}
main_in_test();
