use strict;
use warnings;
use Test::More;
use Parse::DaemontoolsStatus;

my %tests = (
    '/service/some_app: up (pid 10053) 10 seconds' => +{
        service => '/service/some_app',
        status  => 'up',
        pid     => 10053,
        seconds => 10,
        info    => '',
    },
    '/service/some_app: up (pid 10053) 10 seconds, want down' => +{
        service => '/service/some_app',
        status  => 'up',
        pid     => 10053,
        seconds => 10,
        info    => 'want down',
    },
    '/service/some_app: up (pid 10053) 10 seconds, normally down' => +{
        service => '/service/some_app',
        status  => 'up',
        pid     => 10053,
        seconds => 10,
        info    => 'normally down',
    },
    '/service/some_app: up (pid 10053) 10 seconds, normally down, want down' => +{
        service => '/service/some_app',
        status  => 'up',
        pid     => 10053,
        seconds => 10,
        info    => 'normally down, want down',
    },
    '/service/some_app: down 10 seconds, normally up' => +{
        service => '/service/some_app',
        status  => 'down',
        pid     => undef,
        seconds => 10,
        info    => 'normally up',
    },
    '/service/some_app: down 10 seconds' => +{
        service => '/service/some_app',
        status  => 'down',
        pid     => undef,
        seconds => 10,
        info    => '',
    },
    '/service/some_app: supervise not running' => +{
        service => '/service/some_app',
        status  => 'supervise not running',
        pid     => undef,
        seconds => 0,
        info    => '',
    },
);

for my $service (keys %tests) {
    subtest $service => sub {
        is_deeply +Parse::DaemontoolsStatus::parse($service), $tests{$service}, 
    };
}

done_testing;

