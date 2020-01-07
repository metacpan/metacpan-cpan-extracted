use strict;
use warnings;

use MooseX::Types::DateTime;
use MooseX::Types::ISO8601 qw/
    ISO8601DateStr
    ISO8601TimeStr
    ISO8601DateTimeStr
    ISO8601DateTimeTZStr
    ISO8601StrictDateStr
    ISO8601StrictTimeStr
    ISO8601StrictDateTimeStr
    ISO8601StrictDateTimeTZStr
    ISO8601DateDurationStr
    ISO8601TimeDurationStr
    ISO8601DateTimeDurationStr
/;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

for (
    [ ISO8601DateStr,             '2009-06-11' ],
    [ ISO8601TimeStr,             '12:06:34Z' ],
    [ ISO8601DateTimeStr,         '2009-06-11T12:06:34Z' ],
    [ ISO8601DateTimeTZStr,       '2009-06-11T12:06:34+00:00' ],
    [ ISO8601StrictDateStr,       '2009-06-11' ],
    [ ISO8601StrictTimeStr,       '12:06:34Z' ],
    [ ISO8601StrictDateTimeStr,   '2009-06-11T12:06:34Z' ],
    [ ISO8601StrictDateTimeTZStr, '2009-06-11T12:06:34+00:00' ],
    [ ISO8601DateDurationStr,     'P01Y01M01D' ],
    [ ISO8601TimeDurationStr,     'PT01H01M01S' ],
    [ ISO8601DateTimeDurationStr, 'P01Y01M01DT01H01M01S' ],
)
{
    my ($type, $testdata) = @{ $_ };

    ok($type->check($testdata), 'ascii ' . $type->name);
    foreach my $unicode_digit (
        "\x{0661}",     # \N{ARABIC-INDIC DIGIT ONE} unicode 1.1
        "\x{09EA}",     # \N{BENGALI DIGIT FOUR}     unicode 1.1
        "\x{1E951}",    # \N{ADLAM DIGIT ONE}        unicode 9.0
    ) {
        my $bad_data = $testdata =~ s/[0-9]/$unicode_digit/;
        ok(!$type->check($bad_data), 'non-ascii ' . $type->name);
    }
}

done_testing;
