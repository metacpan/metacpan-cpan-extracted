package Net::Async::Redis::Cluster::Node;
use Object::Pad;
class Net::Async::Redis::Cluster::Node :isa(IO::Async::Notifier);

our $VERSION = '6.005'; # VERSION

use Net::Async::Redis::Cluster::Replica;
use Scalar::Util qw(refaddr blessed);
use Future::AsyncAwait;
use Log::Any qw($log);

use overload
    '""' => method { 'NaRedis::Cluster::Node[id=' . $self->id . ']' },
    '0+' => method { refaddr($self) },
    bool => method { 1 },
    fallback => 1;

field $start:reader;
field $end:reader;
field $primary:reader;
field $replicas:reader;
field $cluster:reader;

method configure (%args) {
    $start = delete $args{start} if exists $args{start};
    $end = delete $args{end} if exists $args{end};
    $primary = delete $args{primary} if exists $args{primary};
    if(exists $args{replicas}) {
        $replicas = [
            map {
                blessed($_) && $_->isa('Net::Async::Redis::Cluster::Replica')
                ? $_
                # Upgrade plain arrayref from Redis into a proper object
                : Net::Async::Redis::Cluster::Replica->new(
                    host => $_->[0],
                    port => $_->[1],
                    id   => $_->[2]
                )
            } (delete $args{replicas})->@*
        ];
    }
    Scalar::Util::weaken($cluster = delete $args{cluster}) if exists $args{cluster};
    for my $k (@Net::Async::Redis::Cluster::CONFIG_KEYS) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    return $self->next::method(%args);
}

sub from_arrayref {
    my ($class, $arrayref, %args) = @_;
    my ($start, $end, $primary, @replicas) = $arrayref->@*;
    die 'invalid start' if $start > $end or $start < 0 or $start >= 16384;
    die 'invalid end' if $end >= 16384;
    die 'no primary found' unless $primary;
    die 'invalid primary' unless $primary->[0] ne "" && $primary->[1] > 0;
    return $class->new(
        start    => $start,
        end      => $end,
        primary  => $primary,
        replicas => \@replicas,
        %args
    )
}

method replica_list { $replicas->@* }
method replica_count { 0 + $replicas->@* }
method id { $primary->[2] // $self->host_port }
method host_port { join ':', $primary->@[0, 1] }

method primary_connection ($conn = undef) {
    return $self->{primary_connection} = $conn if $conn;
    return $self->{primary_connection} ||= $self->establish_primary_connection;
}

async method establish_primary_connection {
    $self->add_child(
        my $redis = Net::Async::Redis->new(
            $self->Net::Async::Redis::Cluster::node_config,
            host => $self->primary->[0],
            port => $self->primary->[1],
        )
    );
    $self->{primary_connection} = $redis;
    await $redis->connected;
    await $self->cluster->node_connection_established($self, $redis);
    return $redis;
}

method replica_connection ($conn = undef) {
    return $self->{replica_connection} = $conn if $conn;
    return $self->{replica_connection} ||= $self->establish_replica_connection;
}

async method establish_replica_connection {
    my ($replica) = $self->replicas->[rand $self->replica_count] or die 'no replicas found';
    $log->tracef(
        'Will use replica [%s] on %s:%d for primary [%s]',
        $replica->id,
        $replica->host,
        $replica->port,
        $self->id
    );
    $self->add_child(
        my $redis = Net::Async::Redis->new(
            $self->Net::Async::Redis::Cluster::node_config,
            host => $replica->host,
            port => $replica->port,
        )
    );
    $self->{replica_connection} = $redis;
    await $redis->connected;
    # Replica queries are only allowed in "readonly" mode.
    # https://redis.io/docs/latest/commands/readonly/
    await $redis->readonly;
    # We don't forward clientside cache events here, because that would
    # lead to duplicates when both primary and replica are connected.
    return $redis;
}

1;
__END__

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> plus contributors as mentioned in
L<Net::Async::Redis/CONTRIBUTORS>.

=head1 LICENSE

Copyright Tom Molesworth 2015-2024. Licensed under the same terms as Perl itself.

