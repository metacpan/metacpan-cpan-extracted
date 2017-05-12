#!perl
use 5.14.1;
use warnings;
use Test::Mock::Time; # require early!
use Digest::SHA1 qw/sha1_hex/;
use Redis::RateLimit;
use Redis;
use Test::Spec;

my $server = $ENV{TEST_REDIS_RATELIMIT_SERVER};
unless ( $server ) {
    plan skip_all => <<'';
Requires a Redis server specified in the environment. E.g.,
TEST_REDIS_RATELIMIT_SERVER=127.0.0.1:6379

}

# Give every test its own key space
sub unique_prefix { 'rl' . sha1_hex($$ . {} . rand) }

describe RateLimit => sub {
    my $redis_client;
    my $ratelimit;

    before each => sub {
        $redis_client = Redis->new(server => $server);
        my $rules = [
            { interval => 1, limit => 10 },
            { interval => 60, limit => 50 },
        ];
        $ratelimit = Redis::RateLimit->new(
            redis  => $redis_client,
            rules  => $rules,
            prefix => unique_prefix(),
        );
    };

    after each => sub { sleep 1 };

    # Increment and response should not be limited.
    my $incr_and_false = sub { !$ratelimit->incr('127.0.0.1', 1) };
    my $incr_and_true  = sub { $ratelimit->incr('127.0.0.1', 1) };

    # Increment N times AND all responses should not be limited.
    my $bump = sub {
        my ( $num, $fn ) = @_;
        my $ok = 1; $ok &&= $fn->() for 1 .. $num;
        fail unless $ok;
        $ok;
    };

    describe incr => sub {
        it 'should not rate limit provided below rule rates' => sub {
            ok $bump->(8, $incr_and_false);
        };

        it 'should not rate limit when continually below limits' => sub {
            my $rules = [
                { interval => 1, limit => 10 },
                { interval => 60, limit => 100 },
            ];
            $ratelimit = Redis::RateLimit->new(
                redis  => $redis_client,
                rules  => $rules,
                prefix => unique_prefix(),
            );
            my $r;
            for ( 1 .. 5 ) {
                $r = $bump->(9, $incr_and_false);
                sleep 1;
            }
            ok $r;
        };

        it 'should rate limit when over 10 req/sec' => sub {
            $bump->(10, $incr_and_false);
            ok $incr_and_true->();
        };

        it 'should rate limit when over 20 req/min' => sub {
            # Do 10 requests
            $bump->(10, $incr_and_false);
            sleep 1;
            # Do another 10
            $bump->(10, $incr_and_false);
            # Do one more request to put us over the top for the 2nd rule
            ok $incr_and_true->();
        };
    };

    describe check => sub {
        it 'should not be limited if the key does not exist' => sub {
            ok $bump->(1, $incr_and_false);
        };

        it 'should return true if it has been limited' => sub {
            $bump->(10, $incr_and_false);
            $bump->(1, $incr_and_true);
            ok $ratelimit->check('127.0.0.1');
        };
    };

    describe violated_rules => sub {
        it 'should return the set of rules a key has violated' => sub {
            $bump->(10, $incr_and_false);
            $bump->(1, $incr_and_true);
            my @violated = $ratelimit->violated_rules('127.0.0.1');
            ok @violated == 1;
            is_deeply $violated[0], { interval => 1, limit => 10 };
        };
    };

    describe whitelist => sub {
        before each => sub {
            $ratelimit->whitelist('127.0.0.1');
        };

        it 'should not be limited ever' => sub {
            $bump->(10, $incr_and_false);
            ok !$ratelimit->incr('127.0.0.1', 10);
        };
    };

    describe blacklist => sub {
        before each => sub {
            $ratelimit->blacklist('127.0.0.1');
        };

        it 'should be limited on the first try' => sub {
            ok $ratelimit->incr('127.0.0.1', 1);
        };
    };

    describe keys => sub {
        it 'returns a list keys' => sub {
            $bump->(10, $incr_and_false);
            my @keys = $ratelimit->keys;
            ok @keys == 1;
            is $keys[0], '127.0.0.1';
        };
    };

    describe limited_keys => sub {
        it 'returns a list of rate limited keys' => sub {
            $bump->(10, $incr_and_false);
            my @limited = $ratelimit->limited_keys(qw/
                127.0.0.3 127.0.0.1 127.0.0.2
            /);
            ok @limited == 1;
            is $limited[0], '127.0.0.1';
        };
    };
};

runtests;
