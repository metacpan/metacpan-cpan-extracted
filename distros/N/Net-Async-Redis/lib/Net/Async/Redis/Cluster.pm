package Net::Async::Redis::Cluster;

use Object::Pad;
class Net::Async::Redis::Cluster :isa(IO::Async::Notifier);

use strict;
use warnings;
use experimental qw(signatures);

use utf8;

use parent qw(Net::Async::Redis::Commands);

our $VERSION = '6.000'; # VERSION

=encoding utf8

=head1 NAME

Net::Async::Redis::Cluster - support for cluster routing

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::Redis::Cluster;
 my $loop = IO::Async::Loop->new;
 $loop->add(
  my $cluster = Net::Async::Redis::Cluster->new(
  )
 );
 await $cluster->bootstrap(
  host => 'redis.local',
 );
 print "Key: " . await $cluster->get('some_key');

=head1 DESCRIPTION

Provides access to a Redis cluster.

Usage is similar to L<Net::Async::Redis> with the addition of a L</bootstrap>
step to find the initial client nodes:

 $loop->add(
  my $cluster = Net::Async::Redis::Cluster->new(
  )
 );
 await $cluster->bootstrap(
  host => 'redis.local',
 );
 print "Key: " . await $cluster->get('some_key');

Note that this adds some overhead to lookups, so you may be better served
by options such as the L<https://github.com/twitter/twemproxy|twemproxy>
proxy routing dæmon, or a service mesh such as L<https://istio.io/|istio>.

=cut

no indirect;
use Class::Method::Modifiers;
use Syntax::Keyword::Try;
use Syntax::Keyword::Dynamically;
use Future::AsyncAwait;
use Future::Utils qw(fmap_void fmap_concat);
use List::BinarySearch::XS qw(binsearch);
use List::UtilsBy qw(nsort_by);
use List::Util qw(first);
use Scalar::Util qw(reftype);
use Digest::CRC qw(crc);
use Cache::LRU;

use Log::Any qw($log);

use Net::Async::Redis;
use Net::Async::Redis::Cluster::Node;
use Net::Async::Redis::Cluster::Multi;

use overload
    '""' => sub { 'NaRedis::Cluster[]' },
    bool => sub { 1 },
    fallback => 1;

use constant MAX_SLOTS => 16384;

BEGIN {
    # It's unlikely that MAX_SLOTS would ever need
    # to change, but it's also important that if we do change it,
    # our bitwise-AND still makes sense in context, i.e. this
    # must always be a power of 2.
    die 'invalid MAX_SLOTS' unless 1 == unpack(
        "b*" => pack(
            N1 => MAX_SLOTS
        )
    ) =~ tr/1/1/;
}

our @CONFIG_KEYS = qw(
    auth
    pipeline_depth
    stream_read_len
    stream_write_len
    on_disconnect
    client_name
    opentracing
    protocol
    hashrefs
    client_side_cache_size
);

# Sometimes we really want a key to be on a specific node. We can achieve this by maintaining
# a mapping from all known slots to a sample key which would resolve to that slot - this can
# then be applied in a `{slot}` entry in the full key to ensure that the value will end up
# in the desired slot. To map to specific nodes, you'd combine this with the ->cluster_getslots
# information, can use any slot in the range covered by that server.
our @SLOT_MAP;

sub key_for_slot {
    my ($slot) = @_;
    populate_slot_map() unless @SLOT_MAP;
    return $SLOT_MAP[$slot];
}

sub populate_slot_map {
    return if @SLOT_MAP;

    my $pending = MAX_SLOTS;
    my $data = '0';

    my @map;
    ITEM:
    while($pending) {
        my $slot = crc($data, 16, 0, 0, 0, 0x1021, 0, 0) & (MAX_SLOTS - 1);
        unless(defined $map[$slot]) {
            $map[$slot] = $data;
            --$pending;
        }
        ++$data;
    }
    return;
}

=head1 METHODS

=head2 bootstrap

Connects to a Redis server and attempts to discover the cluster node configuration.

Usage:

 try {
  await $cluster->bootstrap(
   host => 'redis-primary.local',
   port => 6379,
  );
 } catch {
  $log->errorf('Unable to bootstrap the Redis cluster: %s', $@);
 }

=cut

async sub bootstrap {
    my ($self, %args) = @_;
    my $redis;
    try {
        $self->add_child(
            $redis = Net::Async::Redis->new(
                $self->node_config,
                host => $args{host},
                port => $args{port},
            )
        );
        await $redis->connect;
        await $self->apply_slots_from_instance(
            $redis,
            host => $args{host},
            port => $args{port}
        );
    } finally {
        $redis->remove_from_parent if $redis;
    }
}

=head2 clientside_cache_events

Provides combined stream of clientside-cache events from all known Redis primary nodes.

=cut

sub clientside_cache_events {
    my ($self) = @_;
    $self->{clientside_cache_events} ||= do {
        $self->ryu->source;
    };
}

=head2 watch_keyspace

L<Net::Async::Redis/watch_keyspace> support for gathering notifications
from all known nodes.

=cut

async sub watch_keyspace {
    my ($self, $pattern) = @_;
    my @sub = await fmap_concat {
        $_->primary_connection->then(sub {
            shift->watch_keyspace($pattern);
        });
    } foreach => [$self->{nodes}->@*], concurrent => 4;

    my $combined = Net::Async::Redis::Subscription->new(
        redis   => $self,
        channel => $pattern
    );

    $combined->events->emit_from(@sub);
    return $combined;
}

=head2 client_setname

Apply client name to all nodes.

Note that this only updates the current nodes, it will not
apply to new nodes. Use the L<Net::Async::Redis/client_name>
constructor/L</configure> parameter to apply to all nodes.

=cut

async sub client_setname {
    my ($self, $name) = @_;
    await fmap_concat {
        $_->primary_connection->then(sub {
            shift->client_setname($name);
        });
    } foreach => [$self->{nodes}->@*], concurrent => 4;
    return 'OK';
}

=head2 multi

A C<MULTI> transaction on a Redis cluster works slightly differently from
single-node setups.

=over 4

=item * issue C<MULTI> on all nodes

=item * execute the commands, distributing across nodes as usual

=item * issue C<EXEC> or C<DISCARD> as appropriate

=back

Note that the coderef is called only once, even if there are multiple nodes involved.

Currently, there's no optimisation for limiting C<MULTI> to the nodes
participating in the transaction.

=cut

async method multi ($code) {
    die 'Need a coderef' unless $code and reftype($code) eq 'CODE';

    # Start a transaction on all primary nodes
    my $cmd = Net::Async::Redis::Commands->can('multi');
    my $node_count = 0 + $self->{nodes}->@*;
    my %multi_for_node = await fmap_concat(async sub ($node) {
        my $redis = await $node->primary_connection;
        my $multi = Net::Async::Redis::Multi->new(
            redis => $redis,
        );
        await $redis->$cmd;
        $node->id => $multi
    }, foreach => [$self->{nodes}->@*], concurrent => $node_count);

    # At this point we know all nodes are safely in MULTI mode,
    # so we can start sending requests
    my $multi = Net::Async::Redis::Cluster::Multi->new(
        redis => $self,
        multi => \%multi_for_node,
    );
    $multi->$code;

    await fmap_void(sub {
        shift->exec(sub { })
    }, foreach => [ values %multi_for_node ], concurrent => $node_count);

    return;
}

async sub discard {
    my ($self, @args) = @_;
    my $cmd = Net::Async::Redis::Commands->can('discard');
    await fmap_concat(sub {
        my ($node) = @_;
        $node->primary_connection->then(sub {
            dynamically $self->{_is_multi} = 1;
            shift->$cmd
        });
    }, foreach => [$self->{nodes}->@*], concurrent => 4);
    (shift @{$self->{pending_multi}})->done;
    return;
}

async method exec (@args) {
    $log->tracef('Calling ->exec, with multi = %s and queue %s', '' . $self->{_is_multi}, '' . $self->{multi_queue});
    my (@res) = await fmap_concat(async sub {
        my ($node) = @_;
        my $conn = await $node->primary_connection;
        $log->tracef('Per node ->exec, with multi = %s and queue %s', '' . $self->{_is_multi}, '' . $self->{multi_queue});
        return await $conn->exec;
    }, foreach => [$self->{nodes}->@*], concurrent => 4);
    return [ map { $_->@* } grep { $_ } @res ];
};

=head1 METHODS - All nodes

These methods operate on all nodes at once, and return
the data in hashref mapping node ID to the response.

=cut

async method bgrewriteaof {
    my @nodes = $self->node_list;
    return {
         await fmap_concat(async sub ($node) {
            my $conn = await $node->primary_connection;
            return (
                $node->id => await $conn->bgrewriteaof
            )
        }, foreach => [ @nodes ], concurrent => 0 + @nodes)
    };
}

async method bgsave {
    my @nodes = $self->node_list;
    return {
         await fmap_concat(async sub ($node) {
            my $conn = await $node->primary_connection;
            return (
                $node->id => await $conn->bgsave
            )
        }, foreach => [ @nodes ], concurrent => 0 + @nodes)
    };
}

async method save {
    my @nodes = $self->node_list;
    return {
         await fmap_concat(async sub ($node) {
            my $conn = await $node->primary_connection;
            return (
                $node->id => await $conn->save
            )
        }, foreach => [ @nodes ], concurrent => 0 + @nodes)
    };
}

async method role {
    my @nodes = $self->node_list;
    return {
         await fmap_concat(async sub ($node) {
            my $conn = await $node->primary_connection;
            return (
                $node->id => await $conn->role
            )
        }, foreach => [ @nodes ], concurrent => 0 + @nodes)
    };
}

async method shutdown {
    my @nodes = $self->node_list;
    return {
         await fmap_concat(async sub ($node) {
            my $conn = await $node->primary_connection;
            return (
                $node->id => await $conn->shutdown
            )
        }, foreach => [ @nodes ], concurrent => 0 + @nodes)
    };
}

async method info (@args) {
    my @nodes = $self->node_list;
    return {
         await fmap_concat(async sub ($node) {
            my $conn = await $node->primary_connection;
            return (
                $node->id => await $conn->info(@args)
            )
        }, foreach => [ @nodes ], concurrent => 0 + @nodes)
    };
}

async method time (@args) {
    my @nodes = $self->node_list;
    return {
         await fmap_concat(async sub ($node) {
            my $conn = await $node->primary_connection;
            return (
                $node->id => await $conn->time(@args)
            )
        }, foreach => [ @nodes ], concurrent => 0 + @nodes)
    };
}

async method slowlog_reset (@args) {
    my @nodes = $self->node_list;
    return {
         await fmap_concat(async sub ($node) {
            my $conn = await $node->primary_connection;
            return (
                $node->id => await $conn->slowlog_reset(@args)
            )
        }, foreach => [ @nodes ], concurrent => 0 + @nodes)
    };
}

async method slowlog_len (@args) {
    my @nodes = $self->node_list;
    return {
         await fmap_concat(async sub ($node) {
            my $conn = await $node->primary_connection;
            return (
                $node->id => await $conn->slowlog_len(@args)
            )
        }, foreach => [ @nodes ], concurrent => 0 + @nodes)
    };
}

async method slowlog_get (@args) {
    my @nodes = $self->node_list;
    return {
         await fmap_concat(async sub ($node) {
            my $conn = await $node->primary_connection;
            return (
                $node->id => await $conn->slowlog_get(@args)
            )
        }, foreach => [ @nodes ], concurrent => 0 + @nodes)
    };
}

=head1 METHODS - Any node

These methods operate pick a random node to operate on,
returning the data as if this was a regular L<Net::Async::Redis>
instance.

=cut


=head1 METHODS - Internal

=cut

async sub node_connection_established {
    my ($self, $node, $redis) = @_;
    $self->clientside_cache_events->emit_from($redis->clientside_cache_events) if $redis->is_client_side_cache_enabled;
    return;
}

sub future {
    my ($self) = @_;
    return $self->loop->new_future(@_);
}

sub node_config {
    my ($self) = @_;
    return %{$self}{grep exists $self->{$_}, @CONFIG_KEYS};
}

sub configure {
    my ($self, %args) = @_;
    for (@CONFIG_KEYS) {
        $self->{$_} = delete $args{$_} if exists $args{$_};
    }
    die 'invalid protocol requested: ' . $self->{protocol} if defined $self->{protocol} and not $self->{protocol} =~ /^resp[23]$/;

    die 'hashref support requires RESP3 (Redis version 6+)' if defined $self->{protocol} and $self->{protocol} eq 'resp2' and $self->{hashrefs};
    return $self->next::method(%args);
}

sub _init {
    my ($self) = @_;
    $self->{cache} = Cache::LRU->new(
        size => 10_000
    );
}

=head2 hash_slot_for_key

Calculates the CRC16 hash slot for the given key.

Note that keys are expected as bytestrings, if you have a Unicode string
you'd likely want to convert to UTF-8 first.

=cut

sub hash_slot_for_key {
    my ($self, $key) = @_;
    return $self->{cache}->get($key) // do {
        # Extract out the first non-zero-length substring between the first {} character pair,
        # if any...
        my ($hash_string) = $key =~ /^[^\{]*\{([^\}]+)\}/;
        # ... and if we don't have any matching substrings, we just use the full key
        $hash_string //= $key;
        # see Digest::CRC docs and the XMODEM protocol for more details, but essentially:
        # input, width=16, init=0, xor constant for output = 0, reflect output = 0, polynomial = 0x1021,
        # reflect input = 0, continuation = 0
        my $slot = crc($hash_string, 16, 0, 0, 0, 0x1021, 0, 0) & (MAX_SLOTS - 1);
        $self->{cache}->set($key => $slot);
        $slot;
    };
}

=head2 replace_nodes

Swap the existing node configuration out for a new arrayref of nodes.

=cut

sub replace_nodes {
    my ($self, $nodes) = @_;
    delete $self->{slot_cache};
    $_->remove_from_parent for splice $self->{nodes}->@*;
    $self->add_child($_) for $nodes->@*;
    my $primary_by_hostport = { };
    for my $node ($nodes->@*) {
        if(my $conn = $primary_by_hostport->{$node->host_port}) {
            $node->primary_connection($primary_by_hostport->{$node->host_port});
        } else {
            $primary_by_hostport->{$node->host_port} = $node->primary_connection;
        }
    }
    $self->{nodes} = $nodes;
    $self
}

=head2 node_list

Returns a list of the currently-configured nodes.

=cut

sub node_list { shift->{nodes}->@* }

sub slot_cache {
    my ($self) = @_;
    $self->{slot_cache} //= [ (undef) x MAX_SLOTS ];
}

=head2 node_for_slot

Returns the appropriate L<Net::Async::Redis::Cluster::Node|node> for the given hash key (slot).

=cut

sub node_for_slot {
    my ($self, $slot) = @_;
    return $self->slot_cache->[$slot & (MAX_SLOTS - 1)] //= do {
        my @nodes = $self->{nodes}->@*;
        my $idx = binsearch {
            $a < $b->start
            ? -1
            : $a > $b->end
            ? 1
            :0
        } $slot, @nodes;
        $nodes[$idx]
    };
}

async sub connection_for_slot {
    my ($self, $slot) = @_;
    my $node = $self->node_for_slot($slot) or die 'no node found for slot';
    return await $node->primary_connection;
}

sub node_by_host_port {
    my ($self, $host, $port) = @_;
    my $host_port = join ':', $host, $port;
    my ($node) = first { $host_port eq $_->host_port } $self->{nodes}->@*;
    return $node;
}

=head2 register_moved_slot

When we get MOVED error we will use this
sub to rebuild the slot cache

=cut

async sub register_moved_slot {
    my ($self, $slot, $host_port) = @_;
    my ($host, $port) = split /:/, $host_port;
    my $node = $self->node_by_host_port($host, $port);
    unless($node) {
        $log->tracef("Failed to find node %s:%s in the original node list", $host, $port);
        # Has a replica become a primary? Let's look for a valid node
        await fmap_void(async sub {
            my ($node) = @_;
            try {
                my $valid_connection = await $node->primary_connection;
                die 'Cluster status changed and cannot find a valid information source' unless $valid_connection;
                # We'll let *all* our nodes try to tell us about slots, the operation
                # should be atomic so whichever one(s) succeed are hopefully consistent
                await $self->apply_slots_from_instance(
                    $valid_connection,
                    host => $host,
                    port => $port,
                );
            } catch {
                $log->tracef("Node at %s was invalid", $node->primary);
            }
        }, concurrent => 4, foreach => [ $self->{nodes}->@* ]);
        # Try again else propgate failure
        $node = $self->node_by_host_port($host, $port)
            or die "Slot $slot has been moved to unknown node";
    }
    $self->slot_cache->[$slot & (MAX_SLOTS - 1)] = $node;
    return $node;
}

=head2 apply_slots_from_instance

Connect to a random instance in the cluster
and execute CLUSTER SLOTS to get information
about the slots and their distribution.

=cut

async sub apply_slots_from_instance {
    my ($self, $redis, %args) = @_;
    my ($slots) = await $redis->cluster_slots;
    $log->tracef('Have %d slots', 0 + @$slots);

    my @nodes;
    for my $slot_data (nsort_by { $_->[0] } $slots->@*) {
        for my $primary ($slot_data->[2]) {
            $primary->[0] = $args{host} unless length $primary->[0];
            $primary->[1] = $args{port} unless length $primary->[1];
        }
        my $node = $self->instantiate_node($slot_data);
        $log->tracef(
            'Node %s (%s) handles slots %d-%d and has %d replica(s) - %s',
            $node->id,
            $node->primary,
            $node->start,
            $node->end,
            $node->replica_count,
            $node
        );

        push @nodes, $node;
    }

    $self->replace_nodes(\@nodes);
}

sub instantiate_node {
    my ($self, $slot_data) = @_;
    return Net::Async::Redis::Cluster::Node->from_arrayref(
        $slot_data,
        cluster => $self,
        $self->node_config
    )
}

=head2 execute_command

Lookup the correct node for the key then execute the command on that node,
if there is a mismatch between our slot hashes and Redis's hashes
we will attempt to rebuild the slot hashes and try again

=cut

sub execute_command {
    my ($self, @cmd) = @_;
    $log->tracef('Will execute %s on cluster', join(' ', @cmd));
    return $self->find_node_and_execute_command(@cmd)->retain;
}

async sub find_node_and_execute_command ($self, @cmd) {
    my $node = await $self->find_node(@cmd);
    my $redis = await $node->primary_connection;

    # Some commands have modifiers around them for RESP2/3 transparent support
    my ($command, @args) = @cmd;
    try {
        $command = lc $command;
        return await $redis->$command(@args);
    } catch ($e) {
        die $e unless $e =~ /MOVED/;
        my ($moved, $slot, $host_port) = split ' ', $e;
        await $self->register_moved_slot($slot => $host_port);
        return await $self->execute_command(@cmd);
    }
}

async sub find_node {
    my ($self, @cmd) = @_;
    my @keys = Net::Async::Redis->extract_keys_for_command(\@cmd);
    unless(@keys) {
        return $self->{nodes}[rand($self->{nodes}->@*)];
    }

    my @slots = map { $self->hash_slot_for_key($_) } @keys;
    my %slots = map { $_ => 1 } @slots;
    die 'Multiple slots for command' if keys(%slots) > 1;
    my $slot = $cmd[0] =~ /^p?(?:un)?s?subscribe/i ? 0 : shift(@slots);
    $log->tracef('Look up hash slot for %s - %d', \@keys, $slot);
    return $self->node_for_slot($slot);
}

=head2 ryu

A L<Ryu::Async> instance for source/sink creation.

=cut

sub ryu {
    my ($self) = @_;
    $self->{ryu} ||= do {
        $self->add_child(
            my $ryu = Ryu::Async->new
        );
        $ryu
    }
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> plus contributors as mentioned in
L<Net::Async::Redis/CONTRIBUTORS>.

=head1 LICENSE

Copyright Tom Molesworth and others 2015-2024.
Licensed under the same terms as Perl itself.

