use strict;
use warnings;

use MooseX::Types::DateTime;
use DateTime::Format::ISO8601;
use MooseX::Types::ISO8601 qw/
    ISO8601DateStr
    ISO8601TimeStr
    ISO8601DateTimeStr

    ISO8601StrictDateStr
    ISO8601StrictTimeStr
    ISO8601StrictDateTimeStr
/;

# TODO: instead of relying on Moose attributes, just call ->check,
# ->assert_coerce etc on the type object directly (see
# Moose::Meta::TypeConstraint for the available API).

{
    package My::DateClass;
    use Moose;
    use MooseX::Types::ISO8601 qw/
        ISO8601DateStr
        ISO8601TimeStr
        ISO8601DateTimeStr
    /;
    use namespace::autoclean;

    foreach my $type (
        [date => ISO8601DateStr],
        [time => ISO8601TimeStr],
        [datetime => ISO8601DateTimeStr],
    ) {
        has $type->[0] => (
            isa => $type->[1], is => 'ro', required => 1, coerce => 1,
        );
    }
}

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use DateTime;

foreach my $tz ('', 'Z')
{
    is(exception {
        my $i = My::DateClass->new(
            date => '2009-01-01',
            time => '12:34:29' . $tz,
            datetime => '2009-01-01T12:34:29' . $tz,
        );
        is( $i->date, '2009-01-01', 'Date unmangled' );
        is( $i->time, '12:34:29' . $tz, 'Time unmangled' );
        is( $i->datetime, '2009-01-01T12:34:29' . $tz, 'Datetime unmangled' );
    },
    undef, 'Date class instance');
}

is(exception {
    my $date = DateTime->now;
    my $i = My::DateClass->new(
        map { $_ => $date } qw/date time datetime/
    );
    ok !ref($_) for map { $i->$_ } qw/date time datetime/;
    like( $i->date, qr/\d{4}-\d{2}-\d{2}/, 'Date mangled' );
    like( $i->time, qr/\d{2}:\d{2}Z/, 'Time mangled' );
    like( $i->datetime, qr/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/, 'Datetime mangled' );
},
undef, 'Date class instance with coercion');

foreach my $tz ('', 'Z')
{
    my $datetime = MooseX::Types::DateTime::to_DateTime('2011-01-04T18:14:15.1234' . $tz);
    isa_ok($datetime, 'DateTime');
    is($datetime->year, 2011);
    is($datetime->month, 1);
    is($datetime->day, 4);
    is($datetime->hour, 18);
    is($datetime->minute, 14);
    is($datetime->second, 15);
    is($datetime->nanosecond, 123400000);
    is($datetime->time_zone->name, 'UTC', 'Z -> UTC');

    my $date = MooseX::Types::DateTime::to_DateTime('2011-01-04');
    isa_ok($date, 'DateTime');
    is($date->year, 2011);
    is($date->month, 1);
    is($date->day, 4);
    is($date->time_zone->name, 'floating', 'no time zome -> floating');

# Cannot work as DateTime requires a year
#    my $time = MooseX::Types::DateTime::to_DateTime('18:14:15.1234Z');
#    isa_ok($time, 'DateTime');
#    is($time->hour, 18);
#    is($time->minute, 14);
#    is($time->second, 12);
#    is($time->nanosecond, 123400000);

}

{
    foreach my $date (qw( 2012-01-12 20120112 )) {
        foreach my $time ( '17:05:00', '17:05:00.0001', '17:05:00,0001', '170500', '170500,0001', '170500.0001' ) {
            foreach my $zone (qw( +0000 +00:00 +00 Z )) {
                ok is_ISO8601DateTimeStr( to_ISO8601DateTimeStr($date.'T'.$time.$zone) ), 'coercing '.$date.'T'.$time.$zone;
            }
        }
    }

    foreach my $date (qw( 2012-01-12 20120112 )) {
        ok is_ISO8601DateStr( to_ISO8601DateStr($date) ), $date.'does not coerce';
    }

    foreach my $time ( '17:05:00', '17:05:00.0001', '17:05:00,0001', '170500', '170500,0001', '170500.0001' ) {
        foreach my $zone (qw( +0000 +00:00 +00 Z )) {
            ok is_ISO8601TimeStr( to_ISO8601TimeStr($time.$zone) ), 'coercing '.$time.$zone;
        }
    }
}

{
    my $datetime = DateTime->new(
        year => 2011,
        month => 1,
        day => 1,
        hour => 0,
        minute => 0,
        second => 0,
        time_zone => 'Asia/Taipei'
    );
    like(exception { to_ISO8601DateTimeStr($datetime) }, qr/cannot coerce non-UTC time/);

    $datetime->set_time_zone('UTC');
    is(exception { to_ISO8601DateTimeStr($datetime) }, undef);
}

{
    local $TODO = "UTC offsets are not yet supported";
    ok is_ISO8601DateTimeStr('2011-12-19T15:03:56+01:00');
    ok is_ISO8601DateTimeStr('2011-12-19T15:03:56-01:00');
    ok is_ISO8601DateTimeStr('2011-12-19T15:03:56+01:30');
    ok is_ISO8601DateTimeStr('2011-12-19T15:03:56-01:30');
    ok is_ISO8601DateTimeStr('2011-12-19T15:03:56+01');
    ok is_ISO8601DateTimeStr('2011-12-19T15:03:56-01');

    ok is_ISO8601DateTimeStr('15:03:56+01:00');
    ok is_ISO8601DateTimeStr('15:03:56-01:00');
    ok is_ISO8601DateTimeStr('15:03:56+01:30');
    ok is_ISO8601DateTimeStr('15:03:56-01:30');
    ok is_ISO8601DateTimeStr('15:03:56+01');
    ok is_ISO8601DateTimeStr('15:03:56-01');
}

{
    is(to_ISO8601DateTimeStr(5), '1970-01-01T00:00:05Z');
    is_ISO8601DateTimeStr(to_ISO8601DateTimeStr(time));
}

# strict types
{
    ok(is_ISO8601DateStr('2013-02-31'), 'bad date validates against our regexp');
    ok(!is_ISO8601StrictDateStr('2013-02-31'), 'bad date is caught by strict type');
    ok(is_ISO8601StrictDateStr('2013-02-01'), 'good date passes strict type');
    is(to_ISO8601StrictDateStr(DateTime::Format::ISO8601->parse_datetime('2013-02-01')), '2013-02-01');

    ok(is_ISO8601TimeStr('25:00:00'), 'bad time validates against our regexp');
    ok(!is_ISO8601StrictTimeStr('25:00:00'), 'bad time is caught by strict type');
    ok(is_ISO8601StrictTimeStr('23:00:00'), 'good time passes strict type');
    # this isn't what we started with, but good enough...
    is(to_ISO8601StrictTimeStr(DateTime::Format::ISO8601->parse_datetime('23:00:00')), '23:00:00Z');

    ok(is_ISO8601DateTimeStr('2013-02-31T00:00:00'), 'bad datetime validates against our regexp');
    ok(!is_ISO8601StrictDateTimeStr('2013-02-31T00:00:00'), 'bad datetime is caught by strict type');
    ok(is_ISO8601StrictDateTimeStr('2013-02-01T00:00:00'), 'good datetime passes strict type');
    is(to_ISO8601StrictDateTimeStr(DateTime::Format::ISO8601->parse_datetime('2013-02-01T00:00:00')), '2013-02-01T00:00:00Z');
}

done_testing;
