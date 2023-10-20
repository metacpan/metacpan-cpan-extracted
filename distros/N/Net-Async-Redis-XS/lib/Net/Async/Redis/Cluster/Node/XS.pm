package Net::Async::Redis::Cluster::Node::XS;

use strict;
use warnings;

our $VERSION = '0.012'; # VERSION

use parent qw(Net::Async::Redis::Cluster::Node);

=head1 NAME

Net::Async::Redis::Cluster::Node::XS - like L<Net::Async::Redis::Cluster::Node> but faster

=head1 DESCRIPTION

This is a wrapper around L<Net::Async::Redis::Cluster::Node> for using the XS versions
of the protocol handling.

API and behaviour should be identical to L<Net::Async::Redis::Cluster::Node>, see there
for instructions.

=cut

use Net::Async::Redis::XS;
use Future::AsyncAwait;

async sub establish_primary_connection {
    my ($self) = @_;

    $self->add_child(
        my $redis = Net::Async::Redis::XS->new(
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

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2022. Licensed under the same terms as Perl itself.

