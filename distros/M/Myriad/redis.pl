#!/usr/bin/env perl 
use strict;
use warnings;

use Future::AsyncAwait;
use Syntax::Keyword::Try;
use Net::Async::Redis;
use IO::Async::Loop;
use List::Util qw(pairmap);

use Log::Any qw($log);
use Log::Any::Adapter qw(Stderr), log_level => 'info';

my $loop = IO::Async::Loop->new;
$loop->add(
    my $redis = Net::Async::Redis->new
);

sub compare_id {
    my ($x, $y) = @_;
    # Handle either side being zero/undef/empty
    return 1 if $y && !$x;
    return -1 if $x && !$y;
    return 0 unless $x && $y;
    # Do they match?
    return 0 if $x eq $y;
    my @first = split /-/, $x, 2;
    my @second = split /-/, $y, 2;
    return $first[0] <=> $second[0]
        || $first[1] <=> $second[1];
}
#$log->infof('Compare: %d', compare_id('1-1', '1-1'));
#$log->infof('Compare: %d', compare_id('1-1', '1-2'));
#$log->infof('Compare: %d', compare_id('1-2', '1-1'));
#$log->infof('Compare: %d', compare_id('1584009780790-3', '0-0'));
#exit 0;

(async sub {
    await $redis->connect;
    my $stream = 'example_stream';
    try {
        # Populate a few items
        for my $xx (1..100) {
            my ($id) = await $redis->xadd($stream, '*', example_key => 'example value');
        }

        # Make sure we have our group - but it's fine if it exists already
        try {
            my ($id) = await $redis->xgroup(
                CREATE => $stream, 'first_group', '$'
            );
        } catch ($e) {
            $log->warnf('Group creation flagged failure: %s', $e);
        }

        # Check any pending items from last execution
        {
            my ($pending) = await $redis->xpending(
                $stream, 'first_group',
                '-', '+', 50,
                'first_client'
            );
            for my $item ($pending->@*) {
                my ($id, $consumer, $age, $delivery_count) = $item->@*;
                $log->infof('Claiming pending message %s from %s, age %s, %d prior deliveries', $id, $consumer, $age, $delivery_count);
                my $claim = await $redis->xclaim($stream, 'first_group', 'first_client', 10, $id);
                $log->infof('Claim is %s', $claim);
                await $redis->xack($stream, 'first_group', $id);
            }
        }

        # Iteration loop
        my ($id) = await $redis->xreadgroup(
            GROUP => 'first_group', 'first_client',
            COUNT => 500,
            STREAMS => $stream, '>'
        );
        $log->infof('Read group %s', $id);
        for my $delivery ($id->@*) {
            my ($stream, $data) = $delivery->@*;
            for my $item ($data->@*) {
                my ($id, $args) = $item->@*;
                $log->infof('Item from stream %s is ID %s and args %s', $stream, $id, $args);
                await $redis->xack($stream, 'first_group', $id);
            }
        }

        # Check on our status - can we clean up any old queue items?
        my %info;
        {
            my ($v) = await $redis->xinfo(
                STREAM => $stream
            );
            %info = pairmap {
                (
                    ($a =~ tr/-/_/r),
                    $b
                )
            } @$v;
            $log->infof('Currently %d groups, %d total length', $info{groups}, $info{length});
            $log->infof('Full info %s', \%info);
        }

        # Track how far back our active stream list goes - anything older than this is fair game
        my $oldest;
        {
            my ($v) = await $redis->xinfo(GROUPS => $stream);
            for my $group (@$v) {
                my %info = pairmap { $a =~ tr/-/_/; ($a, $b) } @$group;
                $log->infof('Group info: %s', \%info);
                my $group_name = $info{name};
                {
                    my ($v) = await $redis->xinfo(CONSUMERS => $stream, $group_name);
                    for my $consumer (@$v) {
                        my %info = pairmap { $a =~ tr/-/_/; ($a, $b) } @$consumer;
                        $log->infof('Consumer info: %s', \%info);
                    }
                }
                $log->infof('Pending check where oldest was %s and last delivered %s', $oldest, $info{last_delivered_id});
                $oldest //= $info{last_delivered_id};
                $oldest = $info{last_delivered_id} if $info{last_delivered_id} and compare_id($oldest, $info{last_delivered_id}) > 0;
                {
                    my ($v) = await $redis->xpending($stream, $group_name);
                    my ($count, $first_id, $last_id, $consumers) = @$v;
                    $log->infof('Pending info %s', $v);
                    $log->infof('Pending from %s', $first_id);
                    $log->infof('Pending check where oldest was %s and first %s', $oldest, $first_id);
                    $oldest //= $first_id;
                    $oldest = $first_id if defined($first_id) and compare_id($oldest, $first_id) > 0;
                }
            }
        }
        $log->infof('Earliest ID to care about: %s', $oldest);

        if($oldest and $oldest ne '0-0' and compare_id($oldest, $info{first_entry}[0]) > 0) {
            # At this point we know we have some older items that can go. We'll need to finesse
            # the direction to search: for now, take the naïve but workable assumption that we
            # have an even distribution of values. This means we go forwards from the start if
            # $oldest is closer to the first_delivery_id, or backwards from the end if it's
            # nearer to the end. We can use the timestamp (first half) rather than the full ID
            # for this comparison, and if we get it wrong we'll still end up with the right
            # count, it'll just be a bit less efficient.
            my $direction = do {
                no warnings 'numeric';
                ($oldest - $info{first_entry}[0]) > ($info{last_entry}[0] - $oldest)
                ? 'xrevrange'
                : 'xrange'
            };
            my $limit = 200;
            my $endpoint = $direction eq 'xrevrange' ? '+' : '-';
            my $total = 0;
            while(1) {
                my ($v) = await $redis->$direction($stream, ($direction eq 'xrange' ? ($endpoint, $oldest) : ($endpoint, $oldest)), COUNT => $limit);
                $log->infof('%s returns %d/%d items between %s and %s', uc($direction), 0 + @$v, $limit, $endpoint, $oldest);
                $total += 0 + @$v;
                last unless 0 + @$v >= $limit;
                # Overlapping ranges, so the next ID will be included twice
                --$total;
                $endpoint = $v->[-1][0];
            }
            $total = $info{length} - $total if $direction eq 'xrange';

            $log->infof('Would trim to %d items', $total);
            my ($before) = await $redis->memory_usage($stream);
            # my ($trim) = await $redis->xtrim($stream, MAXLEN => '~', $total);
            my ($trim) = await $redis->xtrim($stream, MAXLEN => $total);
            my ($after) = await $redis->memory_usage($stream);
            $log->infof('Size changed from %d to %d after trim which removed %d items', $before, $after, $trim);
        } else {
            $log->infof('No point in trimming: oldest is %s and this compares to %s', $oldest, $info{first_entry}[0]);
        }
    } catch ($e) {
        $log->errorf('Unable to get info about stream %s - %s', $stream, $e);
    }

})->()->get;

