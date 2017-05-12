use strict;
use Test::More;
use Test::Exception;

use_ok('Net::Kestrel');

SKIP: {
    skip "set TEST_NET_KESTREL_HOST to test Net::Kestrel on a live Kestrel instance", 1 unless $ENV{TEST_NET_KESTREL_HOST};
    my $host = $ENV{TEST_NET_KESTREL_HOST};
    my $port = $ENV{TEST_NET_KESTREL_PORT} || 2222;

    my $kes = Net::Kestrel->new(host => $host, port => $port);

    my $queue = 'test-net-kestrel';

    ## Flush the queue so our test starts from a known point
    $kes->flush($queue);

    $kes->put($queue, 'foo');
    $kes->put($queue, 'bar');

    cmp_ok($kes->peek($queue), 'eq', 'foo', 'peek');

    cmp_ok($kes->get($queue), 'eq', 'foo', 'get');
    ok($kes->confirm($queue, 1), 'confirm returned true');

    dies_ok { $kes->confirm($queue, 1) } 'confirm dies with no transaction open';

    cmp_ok($kes->get($queue), 'eq', 'bar', 'get');

    ok($kes->confirm($queue, 1), 'confirm returned true');

    ok(!defined($kes->get($queue)), 'undef as queue is empty');
}

done_testing();