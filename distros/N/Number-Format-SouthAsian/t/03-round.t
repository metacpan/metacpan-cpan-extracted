use strict;
use warnings;

use Test::More;

use Number::Format::SouthAsian;

my @tests = (
    [ 123456,                                            '1.23 lakhs', ],
    [ 10100000,                                         '1.01 crores', ],
    [ 10010000,                                             '1 crore', ],
    [ 1234567891,                                        '1.23 arabs', ],
    [ 123456789123,                                    '1.23 kharabs', ],
    [ 12345678912345,                                    '1.23 neels', ],
    [ 1234567891234567,                                 '1.23 padmas', ],
    [ 12345678912345678,                               '12.35 padmas', ],
);

plan tests => 2 * (1 + @tests);

{
    my $formatter = Number::Format::SouthAsian->new();
    ok($formatter, 'created $formatter object');

    foreach my $test (@tests) {
        my ($input, $output) = @$test;

        is(
            $formatter->format_number($input, words => 1, decimals => 2),
            $output,
            "rounded wordy method call - $output"
        );
    }
}

{
    my $formatter = Number::Format::SouthAsian->new(words => 1, decimals => 2);
    ok($formatter, 'created $formatter object with words => 1, decimals => 2');

    foreach my $test (@tests) {
        my ($input, $output) = @$test;

        is(
            $formatter->format_number($input),
            $output,
            "rounded wordy formatter - $output"
        );
    }
}
