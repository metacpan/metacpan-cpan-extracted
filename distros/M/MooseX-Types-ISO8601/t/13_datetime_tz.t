use strict;
use warnings;

use MooseX::Types::DateTime;
use MooseX::Types::ISO8601 qw/
    ISO8601DateTimeTZStr
    ISO8601StrictDateTimeTZStr
/;

use Test::More;
use Test::Deep;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
    note "String with offset into datetime";
    my $datetime = MooseX::Types::DateTime::to_DateTime('2011-02-01T00:05:06+01:30');
    cmp_deeply(
        $datetime,
        all(
            isa('DateTime'),
            methods(
                offset => 3600+1800,
                datetime => "2011-02-01T00:05:06",
                nanosecond => 0,
            ),
        ),
    );

    note "DateTime into string";
    is(to_ISO8601DateTimeTZStr($datetime), "2011-02-01T00:05:06+01:30");
}

{
    note "String with offset into datetime, with precision";
    my $datetime = MooseX::Types::DateTime::to_DateTime('2011-02-03T01:05:06.000000001+01:30');
    cmp_deeply(
        $datetime,
        all(
            isa('DateTime'),
            methods(
                offset => 3600+1800,
                datetime => "2011-02-03T01:05:06",
                nanosecond => '000000001',
            ),
        ),
    );

    # XXX - currently we don't generate nanosecond offsets for compatibility.
    note "DateTime into string";
    is(to_ISO8601DateTimeTZStr($datetime), "2011-02-03T01:05:06+01:30");
}

{
    ok(is_ISO8601DateTimeTZStr('2013-02-21T02:00:00Z'),
        'String with Z for zero UTC offset');
    ok(is_ISO8601StrictDateTimeTZStr('2013-02-21T02:00:00Z'),
        'String with Z for zero UTC offset with DateTime check');

    ok(!is_ISO8601DateTimeTZStr('2013-02-21T02:00:00'),
        'String without Z');
    ok(!is_ISO8601StrictDateTimeTZStr('2013-02-21T02:00:00'),
        'String without Z');
}

{
    # it doesn't look like we can validate bad timezones, as it's just an arbitrary hour offset?
    ok(is_ISO8601DateTimeTZStr('2013-02-31T02:00:00+01:00'), 'bad datetime validates against our regexp');
    ok(!is_ISO8601StrictDateTimeTZStr('2013-02-31T03:00:00+01:00'), 'bad datetime is caught by strict type');
    ok(is_ISO8601StrictDateTimeTZStr('2013-02-01T04:00:00+01:00'), 'good datetime passes strict type');
    is(to_ISO8601StrictDateTimeTZStr('2013-02-01T05:00:00+01:00'), '2013-02-01T05:00:00+01:00');
}

done_testing;
