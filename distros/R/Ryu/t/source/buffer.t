use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;

# Ignore failures here
eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->import('TAP');
};

use Ryu;

subtest 'default' => sub {
    my $src = new_ok('Ryu::Source');
    my $buffered = $src->buffer(3);
    my $target = $buffered->merge;
    my $total = 0;
    my $count = $target->count->each(sub { $total = $_ });
    my @received;
    $target->each(sub { push @received, $_ });
    cmp_deeply(\@received, [], 'start with no items');
    $src->emit('x');
    cmp_deeply(\@received, ['x'], 'have one item');
    $target->pause;
    $src->emit('y');
    cmp_deeply(\@received, ['x'], 'still that one item');
    $target->resume;
    cmp_deeply(\@received, ['x', 'y'], 'now have the next item');
    $src->finish;
    is($total, 2, 'have the expected 2 items');
    done_testing;
};

subtest 'high/low watermark' => sub {
    my $src = new_ok('Ryu::Source');
    my $buffered = $src->buffer(
        low  => 2,
        high => 5
    );
    my $target = $buffered->merge;
    my @flow_event;
    $src->flow_control
        ->each(sub { push @flow_event, $_ });
    my @received;
    $target->each(sub { push @received, $_ });

    cmp_deeply(\@received,   [], 'start with no items');
    cmp_deeply(\@flow_event, [], 'and no flow control events');

    $target->pause;
    for (qw(a b c d)) {
        $src->emit($_);
        cmp_deeply([ splice @received, 0 ],   [], 'item does not pass through');
        cmp_deeply(\@flow_event, [],    'still no flow control event');
    }
    $src->emit('e');
    cmp_deeply([ splice @received, 0 ],   [], 'item still not received');
    cmp_deeply(\@flow_event, [0],    'receive flow control event');
    $target->resume;
    cmp_deeply([ splice @received, 0 ],   [qw(a b c d e)], 'items all received');
    cmp_deeply(\@flow_event, [0, 1],    'receive flow control event');
    done_testing;
};

subtest 'completion after drain' => sub {
    my $src = new_ok('Ryu::Source');
    my $buffered = $src->buffer(
        low  => 1,
        high => 2
    );

    # Track all the events we receive
    my $target = $buffered->merge;
    my @received;
    $target->each(sub { push @received, $_ });

    cmp_deeply(\@received,   [], 'start with no items');

    $target->pause;
    for (qw(a b c d)) {
        $src->emit($_);
        cmp_deeply([ splice @received, 0 ],   [], 'item does not pass through');
    }
    ok($buffered->is_paused, 'have enough items to trigger a pause');
    ok(!$buffered->completed->is_ready, 'not yet finished');
    $src->completed->done;
    ok(!$buffered->completed->is_ready, 'still not finished');
    ok(!$target->completed->is_ready, 'and target is still not finished either');
    cmp_deeply([ splice @received, 0 ],   [], 'items still have not passed through');
    $target->resume;
    cmp_deeply([ splice @received, 0 ],   [qw(a b c d)], 'received all items safely after resume');
    is($buffered->completed->state, $src->completed->state, 'future state matches for source and buffered');
    is($target->completed->state, $src->completed->state, 'future state matches for source and target');
    done_testing;
};
done_testing;


