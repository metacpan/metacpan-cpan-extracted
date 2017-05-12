
use strict;
use warnings;

use Test::More tests => 41;
use Test::Exception;
use DateTime;

{

    package Test::MooseX::Types::DateTime::W3C;
    use Moose;
    use MooseX::Types::DateTime::W3C qw( DateTimeW3C );

    has 'dt' => (
        is => 'rw',
        isa => DateTimeW3C,
        coerce => 1,
    );
}

my $o;

lives_ok {
    $o = Test::MooseX::Types::DateTime::W3C->new();
} 'test object created';

my @tests = (
    'YYYY' => [
        {
            from => DateTime->new(year => 1997)->epoch,
            expected => '1997-01-01T00:00:00Z',
        },
        {
            from => DateTime->new(year => 1997),
            expected => '1997-01-01T00:00:00',
        },
        {
            from => DateTime->new(year => 1997, time_zone => '+0130'),
            expected => '1997-01-01T00:00:00+01:30',
        },
    ],
    'YYYY-MM' => [
        {
            from => DateTime->new(year => 1997, month => 7)->epoch,
            expected => '1997-07-01T00:00:00Z',
        },
        {
            from => DateTime->new(year => 1997, month => 7),
            expected => '1997-07-01T00:00:00',
        },
        {
            from => DateTime->new(year => 1997, month => 7, time_zone => '-0145'),
            expected => '1997-07-01T00:00:00-01:45',
        },
    ],
    'YYYY-MM-DD' => [
        {
            from => DateTime->new(year => 1997, month => 7, day => 16)->epoch,
            expected => '1997-07-16T00:00:00Z',
        },
        {
            from => DateTime->new(year => 1997, month => 7, day => 16,
                time_zone => 'UTC'),
            expected => '1997-07-16T00:00:00Z',
        },
        {
            from => DateTime->new(year => 1997, month => 7, day => 16,
                time_zone => '-0145'),
            expected => '1997-07-16T00:00:00-01:45',
        },
    ],
    'YYYY-MM-DDThh:mmTZD' => [
        {
            from => DateTime->new(
                year => 1997, month => 7, day => 16,
                hour => 19, minute => 20,
                time_zone => 'UTC'
            )->epoch,
            expected => '1997-07-16T19:20:00Z',
        },
        {
            from => DateTime->new(
                year => 1997, month => 7, day => 16,
                hour => 19, minute => 20,
                time_zone => 'UTC'
            ),
            expected => '1997-07-16T19:20:00Z',
        },
        {
            from => DateTime->new(
                year => 1997, month => 7, day => 16,
                hour => 19, minute => 20,
                time_zone => '+0130'
            ),
            expected => '1997-07-16T19:20:00+01:30',
        },
        {
            from => DateTime->new(
                year => 1997, month => 7, day => 16,
                hour => 19, minute => 20,
                time_zone => '-0145'
            ),
            expected => '1997-07-16T19:20:00-01:45',
        }
    ],
    'YYYY-MM-DDThh:mm:ssTZD' => [
        {
            from => DateTime->new(
                year => 1997, month => 7, day => 16,
                hour => 19, minute => 20, second => 30,
                time_zone => 'UTC'
            )->epoch,
            expected => '1997-07-16T19:20:30Z',
        },
        {
            from => DateTime->new(
                year => 1997, month => 7, day => 16,
                hour => 19, minute => 20, second => 30,
                time_zone => 'UTC'
            ),
            expected => '1997-07-16T19:20:30Z',
        },
        {
            from => DateTime->new(
                year => 1997, month => 7, day => 16,
                hour => 19, minute => 20, second => 30,
                time_zone => '+0130'
            ),
            expected => '1997-07-16T19:20:30+01:30',
        },
        {
            from => DateTime->new(
                year => 1997, month => 7, day => 16,
                hour => 19, minute => 20, second => 30,
                time_zone => '-0145'
            ),
            expected => '1997-07-16T19:20:30-01:45',
        }
    ],
    'YYYY-MM-DDThh:mm:ss.sTZD' => [
        {
            from => DateTime->new(
                year => 1997, month => 7, day => 16,
                hour => 19, minute => 20, second => 30,
                nanosecond => 123,
                time_zone => 'UTC'
            ),
            expected => '1997-07-16T19:20:30.123Z',
        },
        {
            from => DateTime->new(
                year => 1997, month => 7, day => 16,
                hour => 19, minute => 20, second => 30,
                nanosecond => 123456,
                time_zone => '+0130'
            ),
            expected => '1997-07-16T19:20:30.123456+01:30',
        },
        {
            from => DateTime->new(
                year => 1997, month => 7, day => 16,
                hour => 19, minute => 20, second => 30,
                nanosecond => 123456789,
                time_zone => '-0145'
            ),
            expected => '1997-07-16T19:20:30.123456789-01:45',
        }
    ],
);
for (my $i = 0; $i < @tests; $i += 2 ) {
    my ($format, $values) = @tests[ $i, $i+1 ];

    for my $val ( @$values ) {
        lives_ok {
            $o->dt( $val->{from} );
        } "format accepted: $format";
        is $o->dt, $val->{expected}, "...with value: $val->{from}";
    }
}

