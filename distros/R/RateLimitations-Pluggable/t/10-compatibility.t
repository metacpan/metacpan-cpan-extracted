use strict;
use warnings;
use Test::More;

use Test::FailWarnings;

my $current_time = 0;

BEGIN {
    no warnings qw(redefine);
    *CORE::GLOBAL::time = sub() { $current_time; };
}

use RateLimitations::Pluggable;

subtest "simple within_rate_limits" => sub {
    my $storage = {};
    $current_time = 1476355931;

    my $rl = RateLimitations::Pluggable->new({
            limits => {
                sample_service => {
                    60   => 2,
                    3600 => 5,
                }
            },
            getter => sub {
                my ($service, $consumer) = @_;
                return $storage->{$service}->{$consumer};
            },
            setter => sub {
                my ($service, $consumer, $hits) = @_;
                $storage->{$service}->{$consumer} = $hits;
            },
        });
    ok $rl->within_rate_limits('sample_service', 'client_1'), "1st attempt successful";
    ok $rl->within_rate_limits('sample_service', 'client_1'), "2st attempt successful";
    ok !$rl->within_rate_limits('sample_service', 'client_1'), "3rd attempt failed";
    for (1 .. 10) {
        ok !$rl->within_rate_limits('sample_service', 'client_1'), "additional attempt $_ failed";
    }
    ok $rl->within_rate_limits('sample_service', 'client_2'), "no interferrance with other consumer";
    ok $rl->within_rate_limits('sample_service', 'client_2'), "no interferrance with other consumer (2nd)";
    ok !$rl->within_rate_limits('sample_service', 'client_2'), "other consumer can also hit limit (3rd attempt)";

    subtest "after 60 seconds" => sub {
        $current_time += 60;
        ok !$rl->within_rate_limits('sample_service', 'client_1'), "hourly limit hit";
        ok !$rl->within_rate_limits('sample_service', 'client_1'), "hourly limit hit";
        ok !$rl->within_rate_limits('sample_service', 'client_1'), "hourly limit hit";
        ok $rl->within_rate_limits('sample_service', 'client_2'), "client2 still can consume service";
        ok $rl->within_rate_limits('sample_service', 'client_2'), "client2 still can consume service(2nd)";
        ok !$rl->within_rate_limits('sample_service', 'client_2'), "client2 hits hourly limit too";
    };

    subtest "after 1 hour" => sub {
        $current_time += 3600;
        ok $rl->within_rate_limits('sample_service', 'client_1'), "1st attempt successful";
        ok $rl->within_rate_limits('sample_service', 'client_1'), "2st attempt successful";
        ok !$rl->within_rate_limits('sample_service', 'client_1'), "3rd attempt failed";
        ok $rl->within_rate_limits('sample_service', 'client_2'), "no interferrance with other consumer";
        ok $rl->within_rate_limits('sample_service', 'client_2'), "no interferrance with other consumer (2nd)";
        ok !$rl->within_rate_limits('sample_service', 'client_2'), "other consumer can also hit limit (3rd attempt)";
    };

    subtest "no infite storage consumption" => sub {
        for (0 .. 4000) {
            $rl->within_rate_limits('sample_service', 'client_1');
        }
        is scalar(@{$storage->{sample_service}->{client_1}}), 3600, "no inifininte storage consumtion for client_1 hits";
        }

};

done_testing;
