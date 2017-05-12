use strict;
use Test::More;
use Plack::Builder;
use Plack::Middleware::Cached;

use lib 't/';
require 'mock-cache';

my $counter = 1;
my $app = sub {
    my $env = shift;
    $env->{counter} = $counter;
    [ 200, [], [ $env->{REQUEST_URI}.($counter++) ] ];
};

run_test( builder {
    enable 'Cached', cache => Mock::Cache->new;
    $app;
} );

my $capp = builder {
    enable 'Cached',
        cache => Mock::Cache->new,
        key => [qw(REQUEST_URI HTTP_COOKIE)];
    $app
};

$counter = 1;
run_test( $capp );

my $res = $capp->( { REQUEST_URI => 'foo', HTTP_COOKIE => 'doz=baz' } );
is_deeply( $res, [200,[],['foo3']], 'call with cookies: foo (new)' );
$res = $capp->( { REQUEST_URI => 'foo', HTTP_COOKIE => 'doz=baz' } );
is_deeply( $res, [200,[],['foo3']], 'call with cookies: foo (cached)' );

sub run_test {
    my $app = shift;

    my $res = $app->( { REQUEST_URI => 'foo' } );
    is_deeply( $res, [200,[],['foo1']], 'first call: foo' );

    $res = $app->( { REQUEST_URI => 'bar' } );
    is_deeply( $res, [200,[],['bar2']], 'second call: bar' );

    $res = $app->( { REQUEST_URI => 'foo' } );
    is_deeply( $res, [200,[],['foo1']], 'third call: foo (cached)' );
}

$capp = builder {
    enable 'Cached', cache => Mock::Cache->new, key => 'dummy';
    sub { [200,[],[shift->{REQUEST_URI}]] };
};

$res = $capp->( { REQUEST_URI => 'doz', dummy => 123 } );
is_deeply( $res, [200,[],['doz']], 'scalar key' );
$res = $capp->( { REQUEST_URI => 'baz', dummy => 123 } );
is_deeply( $res, [200,[],['doz']], 'scalar key' );
$res = $capp->( { REQUEST_URI => 'baz', dummy => 456 } );
is_deeply( $res, [200,[],['baz']], 'scalar key' );


my $cache = Mock::Cache->new;
$counter = 1;
$capp = builder {
    enable 'Cached',
        cache => $cache,
        set => sub {
            my ($response, $env) = @_;
            return if ($response->[2]->[0] =~ /^notme/);
            return ($response, expires_in => '20 min');
        },
        env => [qw(counter)]; # env => 'counter';
    $app;
};

# pass additional options from set to the cache
my $env = { REQUEST_URI => 'foo', counter => 7 };
$res = $capp->( { REQUEST_URI => 'foo' } );
$res = $capp->( $env );
is_deeply( $res, [200,[],['foo1']], 'first' );
is_deeply( $cache->{options}, [ expires_in => '20 min' ], 'set' );
is( $env->{counter}, 1, 'cache env' );

# do not cache if set returns undef
$counter = 2;
$env = { REQUEST_URI => 'notme', counter => 42 };
$res = $capp->( $env );
is( $env->{counter}, 2, 'counter not cached' );

$res = $capp->( { REQUEST_URI => 'notme', counter => 2 } );
is_deeply( $res, [200,[],['notme3']], 'skip cache' );

done_testing;
