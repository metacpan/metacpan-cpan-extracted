package Net::Async::Redis::XS;
# ABSTRACT: faster version of Net::Async::Redis

use strict;
use warnings;

our $VERSION = '0.009';

use parent qw(Net::Async::Redis);

=head1 NAME

Net::Async::Redis::XS - like L<Net::Async::Redis> but faster

=head1 SYNOPSIS

 use feature qw(say);
 use Future::AsyncAwait;
 use IO::Async::Loop;
 use Net::Async::Redis::XS;
 my $loop = IO::Async::Loop->new;
 $loop->add(my $redis = Net::Async::Redis::XS);
 await $redis->connect;
 await $redis->set('some-key', 'some-value');
 say await $redis->get('some-key');

=head1 DESCRIPTION

This is a wrapper around L<Net::Async::Redis> with faster protocol parsing.

It implements the L<Net::Async::Redis::Protocol> protocol code in XS for better performance,
and will eventually be extended to optimise some other slow paths as well in future.

API and behaviour should be identical to L<Net::Async::Redis>, see there for instructions.

=cut

package Net::Async::Redis::Protocol::XS {
    use parent qw(Net::Async::Redis::Protocol);

    sub decode {
        my ($self, $bytes) = @_;
        my @data = Net::Async::Redis::XS::decode_buffer($self, $$bytes);
        $self->item($_) for @data;
    }
}

sub dl_load_flags { 1 }

require DynaLoader;
__PACKAGE__->DynaLoader::bootstrap(__PACKAGE__->VERSION);

sub wire_protocol {
    my ($self) = @_;
    $self->{wire_protocol} ||= do {
        Net::Async::Redis::Protocol::XS->new(
            handler  => $self->curry::weak::on_message,
            pubsub   => $self->curry::weak::handle_pubsub_message,
            error    => $self->curry::weak::on_error_message,
            protocol => $self->{protocol_level} || 'resp3',
        )
    };
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

with contributions from C<< PEVANS@cpan.org >>.

=head1 LICENSE

Copyright Tom Molesworth 2022-2023. Licensed under the same terms as Perl itself.

