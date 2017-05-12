use strict;
use warnings;

use Test::More;

use Number::Format::SouthAsian;

my @tests = (
    [ 1,                                                          '1', ],
    [ 10,                                                        '10', ],
    [ 100,                                                      '100', ],
    [ 1000,                                                   '1,000', ],
    [ 10000,                                                 '10,000', ],
    [ 100000,                                                '1 lakh', ],
    [ 1000000,                                             '10 lakhs', ],
    [ 10000000,                                             '1 crore', ],
    [ 100000000,                                          '10 crores', ],
    [ 1000000000,                                            '1 arab', ],
    [ 10000000000,                                         '10 arabs', ],
    [ 100000000000,                                        '1 kharab', ],
    [ 1000000000000,                                     '10 kharabs', ],
    [ 10000000000000,                                        '1 neel', ],
    [ 1000000000000000,                                     '1 padma', ],
    [ 100000000000000000,                                  '1 shankh', ],
    [ 10000000000000000000,                           '1 maha shankh', ],
    [ 1000000000000000000000,                                 '1 ank', ],
    [ 100000000000000000000000,                              '1 jald', ],
    [ 10000000000000000000000000,                            '1 madh', ],
    [ 1000000000000000000000000000,                     '1 paraardha', ],
    [ 100000000000000000000000000000,                         '1 ant', ],
    [ 10000000000000000000000000000000,                  '1 maha ant', ],
    [ 1000000000000000000000000000000000,                  '1 shisht', ],
    [ 100000000000000000000000000000000000,               '1 singhar', ],
    [ 10000000000000000000000000000000000000,        '1 maha singhar', ],
    [ 1000000000000000000000000000000000000000,     '1 adant singhar', ],

    [ 123000,                                            '1.23 lakhs', ],
    [ 10100000,                                         '1.01 crores', ],
    [ 12300000,                                         '1.23 crores', ],
    [ 1230000000,                                        '1.23 arabs', ],
    [ 123000000000,                                    '1.23 kharabs', ],
    [ 12300000000000,                                    '1.23 neels', ],
    [ 1234560000000000,                              '1.23456 padmas', ],
    [ 12345600000000000,                             '12.3456 padmas', ],
);

plan tests => 2 * (1 + @tests);

{
    my $formatter = Number::Format::SouthAsian->new();
    ok($formatter, 'created $formatter object');

    foreach my $test (@tests) {
        my ($input, $output) = @$test;

        is(
            $formatter->format_number($input, words => 1),
            $output,
            "wordy method call - $output"
        );
    }
}

{
    my $formatter = Number::Format::SouthAsian->new(words => 1);
    ok($formatter, 'created $formatter object with words => 1 default');

    foreach my $test (@tests) {
        my ($input, $output) = @$test;

        is(
            $formatter->format_number($input),
            $output,
            "wordy formatter - $output"
        );
    }
}
