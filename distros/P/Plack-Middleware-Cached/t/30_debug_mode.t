use strict;
use Test::More;
use Plack::Builder;
use Plack::Middleware::Cached;

use lib 't/';
require 'mock-cache';

my $counter = 1;
my $app     = sub {
    my $env = shift;
    $env->{counter} = $counter;
    [ 200, [], [ $env->{REQUEST_URI} . ( $counter++ ) ] ];
};

my $debug_header = sub {
    my $app = shift;
    sub {
        my $env = shift;
        my $res = $app->($env);
        Plack::Util::response_cb($res, sub {
            my $res = shift;
            push @{$res->[1]},
                'x-pm-cache-debug' =>
                $env->{'plack.middleware.cached'} ? 'cache' : 'app';
            $res;
        });
    };
};

run_test(
    builder {
        enable 'Cached', cache => Mock::Cache->new;
        $app;
    },
    0
);

# Reset counter and turn on debug_header
$counter = 1;
run_test(
    builder {
        enable $debug_header;
        enable 'Cached',
            cache        => Mock::Cache->new;
        $app;
    },
    1
);

sub run_test {
    my $app        = shift;
    my $debug_mode = shift;

    my $test_headers = [];
    $test_headers = [ 'x-pm-cache-debug' => 'app' ] if $debug_mode;

    my $res = $app->( { REQUEST_URI => 'foo' } );
    is_deeply( $res, [ 200, $test_headers, ['foo1'] ], 'first call: foo' );

    $res = $app->( { REQUEST_URI => 'bar' } );
    is_deeply( $res, [ 200, $test_headers, ['bar2'] ], 'second call: bar' );

    $test_headers = [ 'x-pm-cache-debug' => 'cache' ] if $debug_mode;
    $res = $app->( { REQUEST_URI => 'foo' } );
    is_deeply(
        $res,
        [ 200, $test_headers, ['foo1'] ],
        'third call: foo (cached)'
    );
}

done_testing;
