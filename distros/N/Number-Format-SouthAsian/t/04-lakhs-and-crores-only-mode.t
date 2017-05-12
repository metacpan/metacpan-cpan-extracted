use strict;
use warnings;

use Test::More;

use Number::Format::SouthAsian;

my @tests = (
    [ 1_23_456,                         '1.235 lakhs', ],
    [ 1_23_45_678,                     '1.235 crores', ],
    [ 1_23_45_67_890,                '123.457 crores', ],
    [ 12_34_56_78_91_234,         '1.235 lakh crores', ],
);

plan tests => 2 * (1 + @tests);

{
    my $formatter = Number::Format::SouthAsian->new();
    ok($formatter, 'created $formatter object');

    foreach my $test (@tests) {
        my ($input, $output) = @$test;

        is(
            $formatter->format_number($input, words => 1, decimals => 3, lakhs_and_crores_only => 1),
            $output,
            "lakhs and crores only rounded wordy method call - $output"
        );
    }
}

{
    my $formatter = Number::Format::SouthAsian->new(words => 1, decimals => 3, lakhs_and_crores_only => 1);
    ok($formatter, 'created $formatter object with words => 1, decimals => 2, lakhs_and_crores_only => 1');

    foreach my $test (@tests) {
        my ($input, $output) = @$test;

        is(
            $formatter->format_number($input),
            $output,
            "lakhs and crores only rounded wordy formatter - $output"
        );
    }
}
