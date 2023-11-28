package Net::Async::Redis::Cluster::XS;

use Object::Pad;
class Net::Async::Redis::Cluster::XS :isa(Net::Async::Redis::Cluster);

use strict;
use warnings;

our $VERSION = '1.000'; # VERSION

=head1 NAME

Net::Async::Redis::Cluster::XS - like L<Net::Async::Redis::Cluster> but faster

=head1 DESCRIPTION

This is a wrapper around L<Net::Async::Redis::Cluster> with faster protocol parsing.

API and behaviour should be identical to L<Net::Async::Redis::Cluster>, see there for instructions.

=cut

use Syntax::Keyword::Try;
use Net::Async::Redis::XS;
use Net::Async::Redis::Cluster::Node::XS;
use Future::AsyncAwait;

async method bootstrap (%args) {
    my $redis;
    try {
        $self->add_child(
            $redis = Net::Async::Redis::XS->new(
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

method instantiate_node ($slot_data) {
    return Net::Async::Redis::Cluster::Node::XS->from_arrayref(
        $slot_data,
        cluster => $self,
        $self->node_config
    )
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2022. Licensed under the same terms as Perl itself.

