use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use Test::Exception;
use Plack::Middleware::Throttle::Lite::Backend::Redis;

my $redis = eval { Redis->new(server => '127.0.0.1:6379', debug => 0) };
my $detected = $redis && ref($redis) eq 'Redis' && $redis->ping eq 'PONG';

diag 'Redis-server detected at 127.0.0.1:6379' if $detected;

can_ok 'Plack::Middleware::Throttle::Lite::Backend::Redis', qw(
    redis
    reqs_done
    increment
    rdb
);

# simple application
my $app = sub { [ 200, [ 'Content-Type' => 'text/html' ], [ '<html><body>OK</body></html>' ] ] };

# throttling enabled
my $appx = sub {
    my ($instance) = @_;
    builder {
        enable 'Throttle::Lite', backend => [ 'Redis' => {instance => $instance, reconnect => 1} ];
        $app
    }
};

#
# TCP/IP
#
my @instance_inet = (
    ''                          => '127.0.0.1:6379',
    'tcp:example.com:11230'     => 'example.com:11230',
    'tcp:redis.example.org'     => 'redis.example.org:6379',
    'redis-db.example.com'      => 'redis-db.example.com:6379',
    'tcp:127.0.0.9'             => '127.0.0.9:6379',
    'tcp:127.0.0.3:5000'        => '127.0.0.3:5000',
    'foo'                       => 'foo:6379',
    'bogus:0'                   => 'bogus:6379',
    'inet:host:1234'            => 'host:1234',
    'inet:127.0.0.1:65000'      => '127.0.0.1:65000',
    'Inet:Bogus'                => 'bogus:6379',
    'TCP:Redis.tld:9999'        => 'redis.tld:9999',
    'bar:-100'                  => 'bar:6379',
    'baz:70000'                 => 'baz:6379',
);

while (my ($instance, $thru) = splice(@instance_inet, 0, 2)) {
    SKIP: {
        skip 'Redis detected', 1 if ($detected || $ENV{TRAVIS_CI_ORG_BUILD}) && $thru =~ m/^127\.0/;
        throws_ok { $appx->($instance) }
            qr|Cannot get redis handle:.*$thru|, 'Unable to connect to redis at [' . $instance . ']';
    }
}

#
# UNIX Sockets
#
my @instance_unix = (
    'unix:/var/foo/redis.sock'  => '/var/foo/redis.sock',
    '/bar/tmp/redis/sock'       => '/bar/tmp/redis/sock',
    'Unix:/var/bogus/baz.sock'  => '/var/bogus/baz.sock',
);

SKIP: {
    skip 'Unix specific test', scalar(@instance_unix) if $^O eq 'MSWin32';

    while (my ($instance, $thru) = splice(@instance_unix, 0, 2)) {
        throws_ok { $appx->($instance) }
            qr|Nonexistent.*$thru|, 'Invalid socket parameter exception for [' . $instance . ']';
    }
}

done_testing();
