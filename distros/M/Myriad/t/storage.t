use strict;
use warnings;

BEGIN {
    # Enforce deferred operation for in-process Perl module
    $ENV{MYRIAD_RANDOM_DELAY} = 0.001;
}
use Future;
use Future::AsyncAwait;
use Test::More;
use Test::MemoryGrowth;
use Myriad::Storage::Implementation::Memory;

use IO::Async::Test;
use IO::Async::Loop;

my $loop = IO::Async::Loop->new;
my $redis;
testing_loop( $loop );

my @classes = (['Myriad::Storage::Implementation::Memory', []]);

if ($ENV{MYRIAD_TRANSPORT} and $ENV{MYRIAD_TRANSPORT} ne 'memory') {
    require Myriad::Transport::Redis;
    require Myriad::Storage::Implementation::Redis;
    $loop->add(
        $redis = Myriad::Transport::Redis->new(redis_uri => $ENV{MYRIAD_TRANSPORT}, cluster => $ENV{MYRIAD_TRANSPORT_CLUSTER})
    );
    $redis->start()->get();
    push @classes, ['Myriad::Storage::Implementation::Redis', [redis => $redis]];

}

for my $class (@classes) {
    subtest $class->[0] => sub {
        my $storage = new_ok($class->[0], $class->[1]);
        # Implementation::Memory is a Net::Async::Notifier
        # while Implementation::Redis is not
        # worth checking an unifyig that. but for now
        $loop->add($storage) if $class->[0] eq 'Myriad::Storage::Implementation::Memory';

        # Hash
        (async sub {
            await $storage->set(some_key => 'value');
            is(await $storage->get('some_key'), 'value', 'can read our value back');
            await $storage->hash_set(some_hash => key => 'hash value');
            is(await $storage->hash_get('some_hash', 'key'), 'hash value', 'can read our hash value back');
            is(await $storage->hash_add('some_hash', 'numeric', 3), 3, 'can increment a hash value');
            is(await $storage->hash_add('some_hash', 'numeric', 2), 5, 'can increment a hash value again');
            is(await $storage->hash_get('some_hash', 'key'), 'hash value', 'can read our original hash value back');
        })->()->get;

        # OrderedSet
        (async sub {
            await $storage->orderedset_add('sortedset_key', 1, 'one');
            await $storage->orderedset_add('sortedset_key', 2, 'two');
            await $storage->orderedset_add('sortedset_key', 3, 'three');
            await $storage->orderedset_add('sortedset_key', 4, 'four');
            is(await $storage->orderedset_member_count('sortedset_key', 2 => 4), 3, 'correct initial bounded scored orderedset count');
            is(await $storage->orderedset_remove_member('sortedset_key', 'three'), 1, 'able to remove a member  from an orderedset');
            is_deeply(await $storage->orderedset_members('sortedset_key', '-inf', 4, 1), ['one', 1, 'two', 2, 'four', 4], 'able to retrieve members');
            is(await $storage->orderedset_remove_byscore('sortedset_key', 0, 2), 2, 'able to remove byscore for a sortedset');
            is(await $storage->orderedset_member_count('sortedset_key', '-inf', '+inf'), 1, 'correct unbounded scored orderedset count');
            is_deeply(await $storage->orderedset_members('sortedset_key', '-inf', '+inf'), ['four'], 'able to retrieve members without scores');
        })->()->get;

        done_testing;
    };
}

done_testing;

