package Net::Async::Redis::Cluster;

use strict;
use warnings;

use utf8;

use parent qw(
    Net::Async::Redis::Commands
    IO::Async::Notifier
);

our $VERSION = '2.007'; # VERSION

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
use Syntax::Keyword::Try;
use Future::AsyncAwait;
use List::BinarySearch::XS qw(binsearch);
use List::UtilsBy qw(nsort_by);
use List::Util qw(first);
use Digest::CRC qw(crc);

use Log::Any qw($log);

use Net::Async::Redis;
use Net::Async::Redis::Cluster::Node;

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
                host => $args{host},
                port => $args{port},
            )
        );
        await $redis->connect;
        await $self->apply_slots_from_instance($redis);
    } finally {
        $redis->remove_from_parent if $redis;
    }
}

=head2 hash_slot_for_key

Calculates the CRC16 hash slot for the given key.

Note that keys are expected as bytestrings, if you have a Unicode string
you'd likely want to convert to UTF-8 first.

=cut

sub hash_slot_for_key {
    my ($self, $key) = @_;
    # Extract out the first non-zero-length substring between the first {} character pair,
    # if any...
    my ($hash_string) = $key =~ /^[^\{]*\{([^\}]+)\}/;
    # ... and if we don't have any matching substrings, we just use the full key
    $hash_string //= $key;
    # see Digest::CRC docs and the XMODEM protocol for more details, but essentially:
    # input, width=16, init=0, xor constant for output = 0, reflect output = 0, polynomial = 0x1021,
    # reflect input = 0, continuation = 0
    return crc($hash_string, 16, 0, 0, 0, 0x1021, 0, 0) & (MAX_SLOTS - 1);
}

=head2 replace_nodes

Swap the existing node configuration out for a new arrayref of nodes.

=cut

sub replace_nodes {
    my ($self, $nodes) = @_;
    delete $self->{slot_cache};
    $_->remove_from_parent for splice $self->{nodes}->@*;
    $self->add_child($_) for $nodes->@*;
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

sub register_moved_slot {
    my ($self, $slot, $host_port) = @_;
    my $node = $self->node_by_host_port(split /:/, $host_port);
    $self->slot_cache->[$slot & (MAX_SLOTS - 1)] = $node;
    return $node;
}

async sub apply_slots_from_instance {
    my ($self, $redis) = @_;
    my ($slots) = await $redis->cluster_slots;
    $log->tracef('Have %d slots', 0 + @$slots);

    my @nodes;
    for my $slot_data (nsort_by { $_->[0] } $slots->@*) {
        my $node = Net::Async::Redis::Cluster::Node->from_arrayref($slot_data);
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

async sub execute_command {
    my ($self, @cmd) = @_;
    $log->tracef('Will execute %s on cluster', join(' ', @cmd));
    my $k;
    if($cmd[0] eq 'XREADGROUP') {
        my ($idx) = grep { $cmd[$_] eq 'STREAMS' } 0..$#cmd;
        $k = $cmd[$idx + 1];
    } else {
        my $key_idx;
        for my $idx (0..3) {
            my $check = join ' ', @cmd[0..$idx];
            last if $key_idx = $Net::Async::Redis::Commands::KEY_FINDER{$check};
        }
        die 'no index found for ' . join(' ', @cmd) unless defined $key_idx;
        $k = $cmd[$key_idx];
    }
    my $slot = $self->hash_slot_for_key($k);
    $log->tracef('Look up hash slot for %s - %d', $k, $slot);
    my $redis = await $self->connection_for_slot($slot);
    return await $redis->execute_command(@cmd);
}

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> plus contributors as mentioned in
L<Net::Async::Redis/CONTRIBUTORS>.

=head1 LICENSE

Copyright Tom Molesworth and others 2015-2020.
Licensed under the same terms as Perl itself.

