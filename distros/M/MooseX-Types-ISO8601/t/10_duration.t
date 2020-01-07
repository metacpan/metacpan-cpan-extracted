use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;

# TODO: instead of relying on Moose attributes, just call ->check,
# ->assert_coerce etc on the type object directly (see
# Moose::Meta::TypeConstraint for the available API).

{
    package MyClass;
    use Moose;
    use MooseX::Types::ISO8601 qw/
        ISO8601TimeDurationStr
        ISO8601DateDurationStr
        ISO8601DateTimeDurationStr
    /;
    use namespace::autoclean;

    foreach my $attr (
            [time_duration => ISO8601TimeDurationStr],
            [date_duration => ISO8601DateDurationStr],
            [datetime_duration => ISO8601DateTimeDurationStr],
    ) {
        has $attr->[0] => (
            isa => $attr->[1], coerce => 1, required => 1, is => 'ro'
        );
    }
}

is(exception {
    my ($time_duration, $date_duration, $datetime_duration)
        = ('PT00H00M00S', 'P01Y01M01D', 'P01Y01M01DT00H00M00S');
    my $i = MyClass->new(
        time_duration => $time_duration,
        date_duration => $date_duration,
        datetime_duration => $datetime_duration,
    );
    is($i->time_duration, $time_duration,
        'Time duration string unmangled');
    is($i->date_duration, $date_duration,
        'Date duration string unmangled');
    is($i->datetime_duration, $datetime_duration,
        'DateTime duration string unmangled');
}, undef, 'Create with string duration');

is(exception {
    my $i = MyClass->new(
        time_duration => 60,
        date_duration => 259200,
        datetime_duration => 262800,
    );
    is($i->time_duration, 'PT00H01M00S',
        'Time duration number coerced');
    is($i->date_duration, 'P00Y00M03D',
        'Date duration number coerced');
    is($i->datetime_duration, 'P00Y00M03DT01H00M00S',
        'DateTime duration number coerced');
}, undef, 'Create with Numeric duration');

use MooseX::Types::ISO8601 qw/
        ISO8601TimeDurationStr
        ISO8601DateDurationStr
        ISO8601DateTimeDurationStr
    /;
use MooseX::Types::DateTime qw/ Duration /;

# Time durations

ok !is_ISO8601TimeDurationStr("PT");

foreach my $tp (
        ['PT0H15M.507S', 'PT00H15M00.507000S'], # Note pairs, as we normalise whilst
                                                # roundtripping..
        ['PT4M10S','PT00H04M10S'],
        ['PT51S', 'PT00H00M51S'],
        ['PT001H15M01S', 'PT01H15M01S'],
        ['PT0006M03S', 'PT00H06M03S'],
    ) {
    my $t = $tp->[0];
    my $ret = $tp->[1] || $t;
    ok is_ISO8601TimeDurationStr($t), $t . ' is an ISO8601TimeDurationStr';
    ok is_ISO8601DateTimeDurationStr($t), $t . ' is not a ISO8601DateTimeDurationStr, with no date elements';
    ok !is_ISO8601DateDurationStr($t), $t . ' is not an ISO8601DateDurationStr';
    my $dt = to_Duration($t);
    ok $dt, 'Appears to coerce to DateTime::Duration';
    isa_ok $dt, 'DateTime::Duration';
    is to_ISO8601TimeDurationStr($dt), $ret, $t . ' round trips';
}

# DateTime durations

ok !is_ISO8601DateTimeDurationStr("P");
ok !is_ISO8601DateTimeDurationStr("PT");

foreach my $tp (
        ['P00Y08M02DT0H15M.507S', 'P00Y08M02DT00H15M00.507000S'],
        ['P00Y08M02DT0H15M,507S', 'P00Y08M02DT00H15M00.507000S'],
        ['P00Y08M03DT0H15M,507S', 'P00Y08M03DT00H15M00.507000S'],
        ['PT01S', 'P00Y00M00DT00H00M01S'],
    ) {
    my $t = $tp->[0];
    my $ret = $tp->[1] || $t;
    ok is_ISO8601DateTimeDurationStr($t), $t . ' is an ISO8601DateTimeDurationStr';
    ok !is_ISO8601DateDurationStr($t), $t . ' is not an ISO8601DateDurationStr';
    my $dt = to_Duration($t);
    ok $dt, 'Appears to coerce to DateTime::Duration';
    isa_ok $dt, 'DateTime::Duration';
    is to_ISO8601DateTimeDurationStr($dt), $ret, $t . ' round trips';
}

ok !is_ISO8601TimeDurationStr('P00Y08M02DT0H15M.507S'), 'has date elements, and so not a time';

# Date durations

ok !is_ISO8601DateDurationStr("P");

foreach my $tp (
        ['P02Y08M02D'],
        ['P02D', 'P00Y00M02D'],
    ) {
    my $t = $tp->[0];
    my $ret = $tp->[1] || $t;
    ok !is_ISO8601TimeDurationStr($t), $t . ' is no an ISO8601TimeDurationStr';
    ok is_ISO8601DateTimeDurationStr($t), $t . ' not is an ISO8601DateTimeDurationStr';
    ok is_ISO8601DateDurationStr($t), $t . ' is an ISO8601DateDurationStr';
    my $dt = to_Duration($t);
    ok $dt, 'Appears to coerce to DateTime::Duration';
    isa_ok $dt, 'DateTime::Duration';
    is to_ISO8601DateDurationStr($dt), $ret, $t . ' round trips';
}

done_testing;
