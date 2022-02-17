package Net::Async::Redis::Cluster::Node;

use strict;
use warnings;

our $VERSION = '3.020'; # VERSION

use parent qw(IO::Async::Notifier);

use Scalar::Util qw(refaddr);
use Future::AsyncAwait;

use overload
    '""' => sub { 'NaRedis::Cluster::Node[id=' . shift->id . ']' },
    '0+' => sub { refaddr(shift) },
    bool => sub { 1 },
    fallback => 1;

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(start end primary replicas), @Net::Async::Redis::Cluster::CONFIG_KEYS) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    Scalar::Util::weaken($self->{cluster} = delete $args{cluster}) if exists $args{cluster};
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

sub start { shift->{start} }
sub end { shift->{end} }
sub primary { shift->{primary} }
sub replicas { shift->{replicas} }
sub replica_list { shift->{replicas}->@* }
sub replica_count { 0 + shift->{replicas}->@* }
sub id { $_[0]->{primary}[2] // $_[0]->host_port }
sub host_port { join ':', @{$_[0]->{primary}}[0, 1] }
sub cluster { shift->{cluster} }

sub primary_connection {
    my ($self) = @_;
    return $self->{primary_connection} ||= $self->establish_primary_connection;
}

async sub establish_primary_connection {
    my ($self) = @_;

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

1;

=head1 AUTHOR

Tom Molesworth C<< <TEAM@cpan.org> >> plus contributors as mentioned in
L<Net::Async::Redis/CONTRIBUTORS>.

=head1 LICENSE

Copyright Tom Molesworth 2015-2022. Licensed under the same terms as Perl itself.

