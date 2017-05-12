use Test::Most;
use Test::FailWarnings;
use lib 't';

use Cache::RedisDB;
use RedisServer;
use Mojolicious::Plugin::RedisSubscriber;

# setting up test server
my $server = RedisServer->start;
plan(skip_all => "Can't start redis-server") unless $server;

$ENV{REDIS_CACHE_SERVER} = 'localhost:' . $server->{port};

my $redis = Cache::RedisDB->redis;
my $sub   = Mojolicious::Plugin::RedisSubscriber->new;

my %results;

$sub->subscribe(
    foo => sub {
        pass "got foo";
        $results{foo}++;
        $redis->publish(baz => 'boo');
    },
);

my $bar;
$bar = sub {
    pass "got bar";
    $results{bar}++;
    $sub->unsubscribe(bar => $bar);
    eq_or_diff \%results,
        {
        foo => 2,
        bar => 1,
        baz => 2,
        },
        "Got expected number of messages before restarting redis";

    my $timer_cb;
    $timer_cb = sub {
        unless ($redis->publish(foo => 'boo')) {
            Mojo::IOLoop->timer(0.1 => $timer_cb);
            return;
        }
        $redis->publish(baz => 'stop');
    };
    Mojo::IOLoop->timer(0.1 => $timer_cb);
};

my $foo;
$foo = sub {
    pass "got foo2";
    $results{foo}++;
    $sub->unsubscribe(foo => $foo);
    $sub->subscribe(bar => $bar);
    $redis->publish(baz => 'boo');
};

$sub->subscribe(foo => $foo);

$sub->subscribe(
    baz => sub {
        my ($ch, $data) = @_;
        pass "got baz";
        $results{baz}++;
        if ($data eq 'stop') {
            $sub->unsubscribe('baz');
            Mojo::IOLoop->stop;
        } else {
            Mojo::IOLoop->timer(0.2 => sub { $redis->publish(bar => 'boo') });
        }
    },
);

my $publisher;
$publisher = sub {
    my $res = $redis->publish(foo => 'boo');
    if ($res) {
        pass "somebody listening on foo";
    } else {
        Mojo::IOLoop->timer(0.2 => $publisher);
    }
};
Mojo::IOLoop->timer(0.2 => $publisher);

alarm 20;    # don't wait for the protons to decay
Mojo::IOLoop->start;

eq_or_diff \%results,
    {
    foo => 3,
    bar => 1,
    baz => 3,
    },
    "Got expected number of messages after restarting redis";

$server->stop;

done_testing;
