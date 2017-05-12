use strict;
use Test::More;
use Redis;
use Test::RedisServer;
use Test::Deep;
use Test::Fatal;

use Redis::Namespace;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );
my $ns = Redis::Namespace->new(redis => $redis, namespace => 'ns');

sub pipeline_ok {
    my ($desc, @commands) = @_;
    my (@responses, @expected_responses);
    for my $cmd (@commands) {
        my ($method, $args, $expected, $expected_err) = @$cmd;
        push @expected_responses, [$expected, $expected_err];
        $ns->$method(@$args, sub { push @responses, [@_] });
    }
    $ns->wait_all_responses;

    cmp_deeply(\@responses, \@expected_responses, $desc);
}

pipeline_ok 'single-command pipeline', ([set => [foo => 'bar'], 'OK'],);

pipeline_ok 'pipeline with embedded error',
    ([set => [clunk => 'eth'], 'OK'], [oops => [], undef, q[ERR unknown command 'OOPS']], [get => ['clunk'], 'eth'],);

pipeline_ok 'keys in pipelined mode',
    ([keys => ['*'], bag(qw<foo clunk>)], [keys => [], undef, q[ERR wrong number of arguments for 'keys' command]],);

pipeline_ok 'info in pipelined mode',
    (
        [info => [], code(sub { ref $_[0] eq 'HASH' && keys %{ $_[0] } })],
        [ info => [qw<oops oops>],
          undef,
          re(qr{^ERR (?:syntax error|wrong number of arguments for 'info' command)$})
      ],
    );

pipeline_ok 'pipeline with multi-bulk reply',
    ([hmset => [kapow => (a => 1, b => 2, c => 3)], 'OK'], [hmget => [kapow => qw<c b a>], [3, 2, 1]],);

pipeline_ok 'large pipeline',
    (
        (map { [hset => [zzapp => $_ => -$_], 1] } 1 .. 5000),
        [hmget => [zzapp => (1 .. 5000)], [reverse -5000 .. -1]],
        [del => ['zzapp'], 1],
    );

subtest 'synchronous request with pending pipeline' => sub {
    my $clunk;
    is($ns->get('clunk', sub { $clunk = $_[0] }), 1, 'queue a request');
    is($ns->set('kapow', 'zzapp', sub { }), 1, 'queue another request');
    is($ns->get('kapow'), 'zzapp', 'synchronous request has expected return');
    is($clunk,           'eth',   'synchronous request processes pending ones');
};

subtest 'transaction with error and pipeline' => sub {
    my @responses;
    my $s = sub { push @responses, [@_] };
    $ns->multi($s);
    $ns->set(clunk => 'eth', $s);
    $ns->rpush(clunk => 'oops', $s);
    $ns->get('clunk', $s);
    $ns->exec($s);
    $ns->wait_all_responses;

    is(shift(@responses)->[0], 'OK'    , 'multi started' );
    is(shift(@responses)->[0], 'QUEUED', 'queued');
    is(shift(@responses)->[0], 'QUEUED', 'queued');
    is(shift(@responses)->[0], 'QUEUED', 'queued');
    my $resp = shift @responses;
    is ($resp->[0]->[0]->[0], 'OK', 'set');
    is ($resp->[0]->[1]->[0], undef, 'bad rpush value should be undef');
    like ($resp->[0]->[1]->[1],
          qr/(?:ERR|WRONGTYPE) Operation against a key holding the wrong kind of value/,
          'bad rpush should give an error');
    is ($resp->[0]->[2]->[0], 'eth', 'get should work');
};

subtest 'transaction with error and no pipeline' => sub {
    is($ns->multi, 'OK', 'multi');
    is($ns->set('clunk', 'eth'), 'QUEUED', 'transactional SET');
    is($ns->rpush('clunk', 'oops'), 'QUEUED', 'transactional bad RPUSH');
    is($ns->get('clunk'), 'QUEUED', 'transactional GET');
    like(
        exception { $ns->exec },
        qr{\[exec\] (?:WRONGTYPE|ERR) Operation against a key holding the wrong kind of value,},
        'synchronous EXEC dies for intervening error'
    );
};


subtest 'wait_one_response' => sub {
    plan skip_all => 'your Redis.pm does not support wait_one_response' if $Redis::VERSION lt '1.961';
    my $first;
    my $second;

    $ns->get('a', sub { $first++ });
    $ns->get('a', sub { $second++ });
    $ns->get('a', sub { $first++ });
    $ns->get('a', sub { $second++ });

    $ns->wait_one_response();
    is($first,  1,     'after first wait_one_response(), first callback called');
    is($second, undef, '... but not the second one');

    $ns->wait_one_response();
    is($first,  1, 'after second wait_one_response(), first callback was not called again');
    is($second, 1, '... but the second one was called');

    $ns->wait_all_responses();
    is($first,  2, 'after final wait_all_responses(), first callback was called again');
    is($second, 2, '... the second one was also called');

    $ns->wait_one_response();
    is($first,  2, 'after final wait_one_response(), first callback was not called again');
    is($second, 2, '... nor was the second one');
};

done_testing;
