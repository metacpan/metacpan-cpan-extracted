package Myriad::Transport::Redis;

use Myriad::Class extends => qw(IO::Async::Notifier);

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=pod

We expect to expose:

=over 4

=item * stream handling functionality, including claiming/pending

=item * get/set and observables

=item * sorted sets

=item * hyperloglog existence

=item * simple queues via lists

=item * pub/sub

=back

This module is responsible for namespacing, connection handling and clustering.
It should also cover retry for stateless calls.

=cut

use Class::Method::Modifiers qw(:all);
use Sub::Util qw(subname);

use Myriad::Redis::Pending;

use Net::Async::Redis;
use Net::Async::Redis::Cluster;

use List::Util qw(pairmap);

use Myriad::Exception::Builder category => 'transport_redis';

declare_exception 'NoSuchStream' => (
    message => 'There is no such stream, is the other service running?',
);

has $use_cluster;
has $redis_uri;
has $redis;
has $redis_pool;
has $waiting_redis_pool;
has $pending_redis_count = 0;
has $wait_time;
has $batch_count = 50;
has $max_pool_count;
has $clientside_cache_size = 0;
has $prefix;
has $ryu;

BUILD {
    $redis_pool = [];
    $waiting_redis_pool = [];
}

method configure (%args) {
    if(exists $args{redis_uri}) {
        my $uri = delete $args{redis_uri};
        $redis_uri = ref($uri) ? $uri : URI->new($uri);
    }
    if(exists $args{cluster}) {
        $use_cluster = delete $args{cluster};
    }
    $max_pool_count = exists $args{max_pool_count} ? delete $args{max_pool_count} : 10;
    $prefix //= exists $args{prefix} ? delete $args{prefix} : 'myriad';
    $clientside_cache_size = delete $args{client_side_cache_size} if exists $args{client_side_cache_size};
    $wait_time = exists $args{wait_time} ? delete $args{wait_time} : 15_000;
    # limit minimum wait time to 100ms
    $wait_time = 100 if $wait_time < 100;
    return $self->next::method(%args);
}

method ryu { $ryu }

=head2 wait_time

Time to wait for items, in milliseconds.

=cut

method wait_time () { $wait_time }

=head2 batch_count

Number of items to allow per batch (pending / readgroup calls).

=cut

method batch_count () { $batch_count }

async method start {
    $redis = await $self->redis;
    return;
}


=head2 apply_prefix

=cut

method apply_prefix($key) {
    $key =~ /^$prefix\./ ? $key : "$prefix.$key";
}

=head2 remove_prefix

=cut

method remove_prefix($key) {
    $key =~ s/^\Q$prefix\E\.//;
    return $key;
}

=head2 oldest_processed_id

Check the last id that has been processed
by B<all> the consumer groups in the given stream.

=cut

async method oldest_processed_id($stream) {
    $stream = $self->apply_prefix($stream);
    my ($groups) = await $redis->xinfo(GROUPS => $stream);
    my $oldest;

    for my $group ($groups->@*) {
        # Use snake_case instead of kebab-case so that we can map cleanly to Perl conventions
        my %info = pairmap {
            (
                ($a =~ tr/-/_/r),
                $b
            )
        } @$group;
        $log->tracef('Group info: %s', \%info);

        my $group_name = $info{name};

        $log->tracef('Pending check where oldest was %s and last delivered %s', $oldest, $info{last_delivered_id});
        $oldest //= $info{last_delivered_id};
        $oldest = $info{last_delivered_id} if $info{last_delivered_id} and $self->compare_id($oldest, $info{last_delivered_id}) > 0;

        # Pending list might have items older than "last_delivered_id"
        # If the get deleted we can't claim them back and they are lost forever.
        my ($pending_info) = await $redis->xpending($stream, $group_name);
        my ($count, $first_id, $last_id, $consumers) = $pending_info->@*;
        $log->tracef('Pending info %s', $pending_info);
        $log->tracef('Pending from %s', $first_id);
        $log->tracef('Pending check where oldest was %s and first %s', $oldest, $first_id);
        $oldest //= $first_id;
        $oldest = $first_id if defined($first_id) and $self->compare_id($oldest, $first_id) > 0;
    }

    return $oldest;
}

=head2 compare_id

Given two IDs, compare them as if doing a C<< <=> >> numeric
comparison.

=cut

method compare_id($x, $y) {
    $x //= '0-0';
    $y //= '0-0';
    # Do they match?
    return 0 if $x eq $y;
    my @first = split /-/, $x, 2;
    my @second = split /-/, $y, 2;

    return $first[0] <=> $second[0]
        || $first[1] <=> $second[1];
}

=head2 next_id

Given a stream ID, returns the next ID after it.
This is managed by the simple expedient of incrementing
the right-hand part of the identifier.

=cut

method next_id($id) {
    my ($left, $right) = split /-/, $id, 2;
    ++$right;
    $left . '-' . $right
}

method _add_to_loop(@) {
    $self->add_child(
        $ryu = Ryu::Async->new
    )
}

method source (@args) {
    $self->ryu->source(@args)
}

=head2 iterate

Deal with incoming requests via a stream.

Returns a L<Ryu::Source> which emits L<Myriad::Redis::Pending> items.

=cut

async method read_from_stream (%args) {
    my $stream = $self->apply_prefix($args{stream});
    my $group = $args{group};
    my $client = $args{client};

    my ($delivery) = await $self->xreadgroup(
        BLOCK   => $self->wait_time,
        GROUP   => $group, $client,
        COUNT   => $self->batch_count,
        STREAMS => ($stream, '>'),
    );

    $log->tracef('Read group: %s as `%s` from [%s]: %s', $group, $client, $stream, $delivery);

    # We are strictly reading for one stream
    my $batch = $delivery->[0];
    if ($batch) {
        my  ($stream, $data) = $batch->@*;
        return map {
            my ($id, $args) = $_->@*;
            +{
                stream => $self->remove_prefix($stream),
                id     => $id,
                data   => $args,
            }
        } $data->@*;
    }

    return ();
}

async method stream_info ($stream) {
    my $v = await $redis->xinfo(
        STREAM => $self->apply_prefix($stream)
    );

    my %info = pairmap {
        (
            ($a =~ tr/-/_/r),
            $b
        )
    } @$v;
    $log->tracef('Currently %d groups, %d total length', $info{groups}, $info{length});
    $log->tracef('Full info %s', \%info);
    return \%info;
}

=head2 cleanup

Clear up old entries from a stream when it grows too large.

=cut

async method cleanup (%args) {
    my $stream = $self->apply_prefix($args{stream});
    # Check on our status - can we clean up any old queue items?
    my ($info) = await $self->stream_info($stream);
    return unless $info->{length} > $args{limit};

    # Track how far back our active stream list goes - anything older than this is fair game
    my $oldest = await $self->oldest_processed_id($stream);
    $log->tracef('Attempting to clean up [%s] Size: %d | Earliest ID to care about: %s', $stream, $info->{length}, $oldest);
    if ($oldest and $oldest ne '0-0' and $self->compare_id($oldest, $info->{first_entry}[0]) > 0) {
        # At this point we know we have some older items that can go. We'll need to finesse
        # the direction to search: for now, take the naïve but workable assumption that we
        # have an even distribution of values. This means we go forwards from the start if
        # $oldest is closer to the first_delivery_id, or backwards from the end if it's
        # nearer to the end. We can use the timestamp (first half) rather than the full ID
        # for this comparison. If we get this wrong, we'll still end up with the right
        # count - it'll just be a bit less efficient.
        # This could likely be enhanced by taking a binary search (setting count to 1), although for the common case
        # of consistent/predictable stream population, having a few points that can be used for a good derivative
        # estimate means we could apply Newton-Raphson, Runge-Kutta or similar methods to converge faster.
        my $direction = do {
            no warnings 'numeric';
            ($oldest - $info->{first_entry}[0]) > ($info->{last_entry}[0] - $oldest)
                ? 'xrevrange'
                : 'xrange'
        };
        my $limit = 200;

        my $endpoint = $direction eq 'xrevrange' ? '+' : '-';
        my $total = 0;
        while (1) {
            # XRANGE / XREVRANGE conveniently have switched start/end parameters, so we don't need to swap $endpoint
            # and $oldest depending on type here.
            my ($v) = await $redis->$direction($stream, $endpoint, $oldest, COUNT => $limit);
            $log->tracef('%s returns %d/%d items between %s and %s', uc($direction), 0 + @$v, $limit, $endpoint, $oldest);
            $total += 0 + @$v;
            last unless 0 + @$v >= $limit;
            # Overlapping ranges, so the next ID will be included twice
            --$total;
            $endpoint = $v->[-1][0];
        }
        $total = $info->{length} - $total if $direction eq 'xrange';

#        my ($before) = await $redis->memory_usage($stream);
        my ($trim) = await $redis->xtrim($stream, MAXLEN => $total);
#        my ($after) = await $redis->memory_usage($stream);
        $log->tracef('Trimmed %d items from stream: %s', $total, $stream);
    }
    else {
        $log->tracef('No point in trimming (%s) where: oldest is %s and this compares to %s', $stream, $oldest, $info->{first_entry}[0]);
    }
}

=head2 pending

Check for any pending items, claiming them for reprocessing as required.

Takes the following named parameters:

=over 4

=item * C<stream> - the stream name

=item * C<group> - which consumer group to check

=item * C<client> - the name of the client to check

=back

Returns the pending items in this stream.

=cut

async method pending (%args) {
    my $src = $self->source;
    my $stream = $self->apply_prefix($args{stream});
    my $group = $args{group};
    my $client = $args{client};
    my @res = ();

    my $instance = await $self->borrow_instance_from_pool;
    try {
        my ($pending) = await $instance->xpending(
            $stream,
            $group,
            '-', '+',
            $self->batch_count,
            $client,
        );
        @res = await &fmap_concat($self->$curry::weak(
            async method ($item) {
                my ($id, $consumer, $age, $delivery_count) = $item->@*;
                $log->tracef('Claiming pending message %s from %s, age %s, %d prior deliveries', $id, $consumer, $age, $delivery_count);
                my $claim = await $redis->xclaim($stream, $group, $client, 10, $id);
                $log->tracef('Claim is %s', $claim);
                my $args = $claim->[0]->[1];

                return {stream => $self->remove_prefix($stream), id => $id, data => $args ? $args : []};
            }),
            foreach => $pending,
            concurrent => scalar @$pending
        );

        } catch ($e) {
            $log->warnf('Could not read pending messages on stream: %s | error: %s', $stream, $e);
        }
        $self->return_instance_to_pool($instance) if $instance;
        undef $instance;

        return @res;
}

=head2 create_stream

Creates a Redis stream.
Note that there is no straight way to do that in Redis
without creating a group or adding an event.
To overcome this it will create a group with MKSTREAM option
Then destroy that init consumer group.

=over 4

=item * C<stream> - name of the stream we want to create.

=back

=cut

async method create_stream ($stream) {
    await $self->create_group($stream, 'INIT', '$', 1);
    await $self->remove_group($stream, 'INIT');
    $log->tracef('created a Redis stream: %s', $stream);
}

=head2 create_group

Create a Redis consumer group if it does NOT exist.

It'll also send the MKSTREAM option to create the stream if it doesn't exist.

=over 4

=item * C<stream> - The name of the stream we want to attach the group to.

=item * C<group> - The group name.

=item * C<start_from> - The id of the message that is going to be considered the start of the stream for this group's point of view
by default it's C<$> which means the last message.

=back

=cut

async method create_group ($stream, $group, $start_from = '$', $make_stream = 0) {
    try {
        my @args = ('CREATE', $self->apply_prefix($stream), $group, $start_from);
        push @args, 'MKSTREAM' if $make_stream;
        await $redis->xgroup(@args);
        $log->tracef('Created new consumer group: %s from stream: %s', $group, $stream);
    } catch ($e) {
        if($e =~ /BUSYGROUP/){
            $log->tracef('Already exists consumer group: %s from stream: %s', $group, $stream);
            return;
        } elsif ($e =~ /requires the key to exist/) {
            Myriad::Exception::Transport::Redis::NoSuchStream->throw(
                reason => "no such stream: $stream",
            );
        } else {
            die $e;
        }
    }
}

=head2 remove_group

Delete a Redis consumer group.

=over 4

=item * C<stream> - The name of the stream group belongs to.

=item * C<group> - The consumer group name.

=back

=cut

async method remove_group ($stream, $group) {
    try {
        my @args = ('DESTROY', $self->apply_prefix($stream), $group);
        await $redis->xgroup(@args);
        $log->tracef('Deleted consumergroup: %s from stream: %s', $group, $stream);
    } catch ($e) {
        if ($e =~ /requires the key to exist/) {
            $log->warnf('Trying to remove a consumergroup(%s) from stream: %s that does not exist', $group, $stream);
            Myriad::Exception::Transport::Redis::NoSuchStream->throw(
                reason => "no such stream: $stream",
            );
        } else {
            die $e;
        }
    }
}

=head2 pending_messages_info

Return information about the pending messages for a stream and a consumer group.

This currently just execute C<XPENDING> without any filtering.

=over 4

=item * C<stream> - The name of the stream we want to check.

=item * C<group> - The consumers group name that we want to check.

=back

=cut

async method pending_messages_info($stream, $group) {
    await $redis->xpending($self->apply_prefix($stream), $group);
}

=head2 stream_length

Return the length of a given stream

=cut

async method stream_length ($stream) {
    return await $redis->xlen($self->apply_prefix($stream));
}

=head2 borrow_instance_from_pool

Returns a Redis connection either from a pool of connection or a new one.
With the possibility of waiting to get one, if all connection were busy and we maxed out our limit.

=cut

async method borrow_instance_from_pool {
    $log->tracef('Available Redis pool count: %d', 0 + $redis_pool->@*);
    if (my $available_redis = shift $redis_pool->@*) {
        ++$pending_redis_count;
        return $available_redis;
    } elsif ($pending_redis_count < $max_pool_count) {
        ++$pending_redis_count;
        return await $self->redis;
    }
    push @$waiting_redis_pool, my $f = $self->loop->new_future;
    $log->debugf('All Redis instances are pending, added to waiting list. Current Redis count: %d/%d | Waiting count: %d', $pending_redis_count, $max_pool_count, 0 + $waiting_redis_pool->@*);
    return await $f;
}

=head2 return_instance_to_pool

This puts back a redis connection into Redis pool, so it can be used by other called.
It should be called at the end of every usage, as on_ready.

It should also be possible with a try/finally combination..
but that's currently failing with the $redis_pool slot not being defined.

Takes the following parameters:

=over 4

=item * C<$instance> - Redis connection to be returned.

=back

=cut

method return_instance_to_pool ($instance) {
    if( my $waiting_redis = shift $waiting_redis_pool->@*) {
        $waiting_redis->done($instance)
    } else {
        push $redis_pool->@*, $instance;
        $log->tracef('Returning instance to pool, Redis used/available now %d/%d', $pending_redis_count, 0 + $redis_pool->@*);
        $pending_redis_count--;
    }
    return;
}

=head2 redis

Resolves to a new L<Net::Async::Redis> or L<Net::Async::Redis::Cluster>
instance, depending on the setting of C<$use_cluster>.

=cut

async method redis () {
    my $instance;
    if($use_cluster) {
        $instance = Net::Async::Redis::Cluster->new(
            client_side_cache_size => $clientside_cache_size,
        );
        $self->add_child(
            $instance
        );
        await $instance->bootstrap(
            host => $redis_uri->host,
            port => $redis_uri->port,
        );
    } else {
        $instance = Net::Async::Redis->new(
            host => $redis_uri->host,
            port => $redis_uri->port,
            client_side_cache_size => $clientside_cache_size,
        );
        $self->add_child(
            $instance
        );
        $log->tracef('Added new Redis connection (%s) to pool', $redis_uri->as_string);
        await $instance->connect;
    }
    return $instance;
}

async method xreadgroup (@args) {
    my $instance = await $self->borrow_instance_from_pool;
    my ($batch) =  await $instance->xreadgroup(@args)->on_ready(sub {
        $self->return_instance_to_pool($instance);
    });
    return ($batch);
}

async method xadd ($stream, @args) {
    return await $redis->xadd($self->apply_prefix($stream), @args);
}

=head2 ack

Acknowledge a message from a Redis stream.

=over 4

=item * C<stream> - The stream name.

=item * C<group> - The group name.

=item * C<message_id> - The id of the message we want to acknowledge.

=back

=cut

async method ack ($stream, $group, $message_id) {
    await $redis->xack($self->apply_prefix($stream), $group, $message_id);
}

=head2 publish

Publish a message through a Redis channel (pub/sub system)

=over 4

=item * C<channel> - The channel name.

=item * C<message> - The message we want to publish (string).

=back

=cut

async method publish ($channel, $message) {
    await $redis->publish($self->apply_prefix($channel), "$message");
}

=head2 subscribe

Subscribe to a redis channel.

=cut

async method subscribe ($channel) {
    my $instance = await $self->borrow_instance_from_pool;
    await $instance->subscribe($self->apply_prefix($channel))->on_ready(sub {
        $self->return_instance_to_pool($instance);
    });
}

async method get($key) {
    await $redis->get($self->apply_prefix($key));
}

async method set ($key, $v) {
    await $redis->set($self->apply_prefix($key), $v);
}

async method getset($key, $v) {
    await $redis->set($self->apply_prefix($key), $v);
}

async method incr ($key) {
    await $redis->incr($self->apply_prefix($key));
}

async method rpush($key, @v) {
    await $redis->rpush($self->apply_prefix($key), @v);
}

async method lpush($key, @v) {
    await $redis->lpush($self->apply_prefix($key), @v);
}

async method rpop($key) {
    await $redis->rpop($self->apply_prefix($key));
}

async method lpop($key) {
    await $redis->lpop($self->apply_prefix($key));
}

async method hset ($k, $hash_key, $v) {
    await $redis->hset($k, $self->apply_prefix($hash_key), $v);
}

async method hget($k, $hash_key) {
    await $redis->hget($k, $self->apply_prefix($hash_key));
}

async method hincrby($k, $hash_key, $v) {
    await $redis->hincrby($k, $self->apply_prefix($hash_key), $v);
}

async method zadd ($key, @v) {
    await $redis->zadd($self->apply_prefix($key), @v);
}

async method zrem ($k, $m) {
    await $redis->zrem($self->apply_prefix($k), $m);
}

async method zremrangebyscore ($k, $min, $max) {
    await $redis->zremrangebyscore($self->apply_prefix($k), $min => $max);
}

async method zcount ($k, $min, $max) {
    await $redis->zcount($self->apply_prefix($k), $min, $max);
}

async method zrange ($k, @v) {
    await $redis->zrange($self->apply_prefix($k), @v);
}

async method watch_keyspace($pattern) {
    my $sub;
    if ($clientside_cache_size) {
        # Net::Async::Redis will handl the connection in this case
        $sub = $redis->clientside_cache_events->map(sub {
            $_ =~ s/$prefix\.//;
            return $_;
        });
    } else {
        # Keyspace notification is a psubscribe
        my $instance = await $self->borrow_instance_from_pool;
        $sub = await $instance->watch_keyspace($self->apply_prefix($pattern));

        $sub = $sub->events->map(sub {
            $_->{channel} =~ s/__key.*:$prefix\.//;
            return $_->{channel};
        });

        $sub->on_ready(sub {
            $self->return_instance_to_pool($instance);
        });
    }

    return $sub;
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

