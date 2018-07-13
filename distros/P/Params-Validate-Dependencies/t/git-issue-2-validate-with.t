use strict;
use warnings;

use Params::Validate::Dependencies qw( validate_with all_of one_of );

use Test::More;
use Test::Exception;
END { done_testing(); }

my $spec = { foo => 1, bar => 1, optional => 0 };

# Vanilla call
is_deeply +{
        validate_with(
            params      => [ foo => 'foo', bar => 'bar', extra => 'extra' ],
            spec        => $spec,
            allow_extra => 1,
        ),
    },
    { foo => 'foo', bar => 'bar', extra => 'extra' },
    'Vanilla call';

dies_ok {;
        validate_with(
            params       => [ foo => 'foo', bar => 'bar' ],
            spec         => $spec,
            dependencies => all_of(qw( foo optional )),
        )
    }
    'Dies if dependency is not met';

is_deeply +{
        validate_with(
            params       => [ foo => 'foo', bar => 'bar' ],
            spec         => $spec,
            dependencies => [ one_of('foo'), one_of('bar') ],
        )
    },
    { foo => 'foo', bar => 'bar' },
    'Supports multiple dependencies';

is_deeply +{
        validate_with(
            params => [ foo => 'foo', bar => 'bar' ],
            spec   => $spec,
        )
    },
    { foo => 'foo', bar => 'bar' },
    'Lives without dependencies';

is_deeply +{
        validate_with(
            params       => [ foo => 'foo', bar => 'bar', optional => 1 ],
            spec         => $spec,
            dependencies => all_of(qw( foo optional )),
        )
    },
    { foo => 'foo', bar => 'bar', optional => 1 },
    'Lives when dependency is met';
