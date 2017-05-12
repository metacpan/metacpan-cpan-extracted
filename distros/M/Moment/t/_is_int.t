use strict;
use warnings FATAL => 'all';
use Test::More;

use Moment;

sub main_in_test {

    my $self;

    my @numbers = (
        +0,
        -0,
        0,
        1,
        +1,
        +4,
        -4,
        2014,
        +2014,
        -2014,
        +100_000,
        -100_000,
        0123,
    );

    my @not_numbers = (
        '0 but true',
        'NaN',
        '00',
        'asdf',
        '1.2',
        '-1.2',
        '1,2',
        '-1,2',
        '0123',
        '-0123',
    );

    foreach (@numbers) {
        ok(Moment::_is_int($self, $_), "_is_int($_)");
    }

    foreach (@not_numbers) {
        ok(!Moment::_is_int($self, $_), "not _is_int($_)");
    }

    done_testing;

}
main_in_test();
