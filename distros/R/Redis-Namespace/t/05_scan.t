use strict;
use version 0.77;
use Test::More;
use Redis;
use Test::RedisServer;

use Redis::Namespace;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );
my $ns = Redis::Namespace->new(redis => $redis, namespace => 'ns');

my $redis_version = version->parse($redis->info->{redis_version});
plan skip_all => 'your redis does not support SCAN command'
    unless $redis_version >= '2.8.0';

is $ns->ping, 'PONG', 'ping pong ok';

sub iterate {
    my ($command, $test) = @_;
    my ($iter, $list) = (0, []);
    while(1) {
        ($iter, $list) = $command->($iter);
        for my $key(@$list) {
            $test->($key);
        }
        last if $iter == 0;
    }
}


subtest 'Empty database' => sub {
    $redis->flushall;
    my ($iter, $list) = $ns->scan(0);
    is $iter => 0, 'iteration finish';
    is scalar @$list => 0, 'empty list';
    $redis->flushall;
};


subtest 'iterate' => sub {
    # add keys for test
    $redis->flushall;
    for my $i(1..10) {
        $redis->set("ns:hoge$i", 'ns');
        $redis->set("other-ns:hoge$i", 'other-ns');
    }

    # iterate keys
    iterate sub {
        $ns->scan($_[0]);
    }, sub {
        is $ns->get($_[0]) => 'ns';
    };

    $redis->flushall;
};


subtest 'scan match' => sub {
    # add keys for test
    $redis->flushall;
    for my $i(1..5) {
        $redis->set("ns:hoge$i", 'hoge');
        $redis->set("ns:fuga$i", 'fuga');
        $redis->set("other-ns:hoge$i", 'other-ns');
    }

    # iterate keys which matches 'hoge*'
    iterate sub {
        $ns->scan($_[0], MATCH => 'hoge*');
    }, sub {
        is $ns->get($_[0]) => 'hoge';
    };

    # iterate keys which matches 'fuga*'
    iterate sub {
        $ns->scan($_[0], MATCH => 'fuga*');
    }, sub {
        is $ns->get($_[0]) => 'fuga';
    };

    $redis->flushall;
};


subtest 'special characters' => sub {
    $redis->flushall;
    my $ns1 = Redis::Namespace->new(redis => $redis, namespace => 'h?llo');
    my $ns2 = Redis::Namespace->new(redis => $redis, namespace => 'h*llo');
    my $ns3 = Redis::Namespace->new(redis => $redis, namespace => 'h[ae]llo');
    my $ns4 = Redis::Namespace->new(redis => $redis, namespace => 'h[^e]llo');
    my $ns5 = Redis::Namespace->new(redis => $redis, namespace => 'h[a-b]llo');

    $redis->mset('hello:foo' => 'a', 'hallo:bar' => 'a', 'hxllo:foobar' => 'a', 'hllo:hoge' => 'a', 'heeeello:fuga' => 'a');

    $ns1->mset(foo => 'a', bar => 'b');
    $ns2->mset(foo => 'a', bar => 'b');
    $ns3->mset(foo => 'a', bar => 'b');
    $ns4->mset(foo => 'a', bar => 'b');
    $ns5->mset(foo => 'a', bar => 'b');

    my $keys = sub {
        my ($ns) = @_;
        my @ret = ();
        iterate sub {
            $ns->scan($_[0], MATCH => '*');
        }, sub {
            push @ret, $_[0];
        };
        return [sort @ret];
    };

    is_deeply $keys->($ns1), ['bar', 'foo'], 'keys h?llo:';
    is_deeply $keys->($ns2), ['bar', 'foo'], 'keys h*llo:';
    is_deeply $keys->($ns3), ['bar', 'foo'], 'keys h[ae]llo:';
    is_deeply $keys->($ns4), ['bar', 'foo'], 'keys h[^e]llo:';
    is_deeply $keys->($ns5), ['bar', 'foo'], 'keys h[a-b]llo:';

    $redis->flushall;
};


subtest 'scan count' => sub {
    # add keys for test
    $redis->flushall;
    for my $i(1..5) {
        $redis->set("ns:hoge$i", 'ns');
        $redis->set("other-ns:hoge$i", 'other-ns');
    }

    # iterate keys
    iterate sub {
        $ns->scan($_[0], COUNT => 1);
    }, sub {
        is $ns->get($_[0]) => 'ns', 'key is in namespace';
    };

    $redis->flushall;
};


subtest 'sscan' => sub {
    # add keys for test
    $redis->flushall;
    for my $i(1..5) {
        ok $redis->sadd("ns:set", "set-$i"), 'sadd';
    }

    # iterate keys
    iterate sub {
        my ($iter, $list) = $ns->sscan('set', $_[0]);
    }, sub {
        ok !$ns->sadd('set', $_[0]), 'set contains item';
    };

    $redis->flushall;
};


subtest 'hscan' => sub {
    $redis->flushall;
    my @hash = (
        hoge => 'fuga',
        homu => 'homu',
        foo  => 'bar',
        fizz => 'buzz',
    );
    ok $redis->hmset('ns:hash', @hash), 'create hash';

    # iterate keys
    my @result;
    iterate sub {
        my ($iter, $list) = $ns->hscan('hash', $_[0]);
    }, sub {
        push @result, @_;
    };
    is_deeply {@result}, {@hash}, 'hscan result';

    $redis->flushall;
};


subtest 'zscan' => sub {
    $redis->flushall;
    my %hash = (
        hoge => 3,
        homu => 1,
        foo  => 4,
        fizz => 2,
    );
    while(my ($key, $score) = each %hash) {
        ok $redis->zadd('ns:zset', $score, $key), 'zadd';
    }

    # iterate keys
    my @result;
    iterate sub {
        my ($iter, $list) = $ns->zscan('zset', $_[0]);
    }, sub {
        push @result, @_;
    };
    is_deeply {@result}, {%hash}, 'zscan result';

    $redis->flushall;
};

done_testing;
