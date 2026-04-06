use v5.26;
use strict;
use warnings;
use Test::More;
use Modern::OpenAPI::Generator::CLI;

sub r {
    my ($argv) = @_;
    return [ Modern::OpenAPI::Generator::CLI::_resolve_feature_flags($argv) ];
}

is_deeply( r( [qw(--name X --client)] ), [ 1, 0, 0 ], '--client only' );

is_deeply( r( [qw(--name X --client --server)] ), [ 1, 1, 0 ], '--client --server without ui' );

is_deeply(
    r( [qw(--name X --client --server --ui)] ),
    [ 1, 1, 1 ],
    '--client --server --ui'
);

is_deeply(
    r( [qw(--name X --client --server --no-ui)] ),
    [ 1, 1, 0 ],
    '--client --server --no-ui'
);

is_deeply( r( [qw(--name X --no-ui)] ), [ 1, 1, 0 ], '--no-ui only' );

is_deeply(
    r( [qw(--name X --no-server --no-ui)] ),
    [ 1, 0, 0 ],
    '--no-server --no-ui'
);

is_deeply( r( [qw(--name X)] ), [ 1, 1, 1 ], 'no feature flags => all on' );

is_deeply( r( [qw(--name X --no-client)] ), [ 0, 1, 1 ], '--no-client only' );

done_testing;
