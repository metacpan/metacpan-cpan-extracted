package Myriad::RPC::Implementation::Redis;

use Myriad::Class extends => qw(IO::Async::Notifier);

our $VERSION = '0.006'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::RPC::Implementation::Redis - microservice RPC Redis implementation.

=head1 DESCRIPTION

=cut

use Role::Tiny::With;

use Future::Utils qw(fmap0);
use Sys::Hostname qw(hostname);
use Scalar::Util qw(blessed);

use Myriad::Exception::InternalError;
use Myriad::RPC::Message;

use constant RPC_SUFFIX => 'rpc';
use constant RPC_PREFIX => 'service';

use Exporter qw(import export_to_level);

with 'Myriad::Role::RPC';

our @EXPORT_OK = qw(stream_name_from_service);

has $redis;
method redis { $redis }

has $group_name;
method group_name { $group_name }

has $whoami;
method whoami { $whoami }

has $rpc_list;
method rpc_list { $rpc_list }

has $running;

sub stream_name_from_service ($service, $method) {
    return RPC_PREFIX . ".$service.". RPC_SUFFIX . "/$method"
}

method configure (%args) {
    $redis = delete $args{redis} if exists $args{redis};
    $whoami = hostname();
    $group_name = 'processors';
    $rpc_list //= [];

    $self->next::method(%args);
}

async method start () {
    $self->listen;
    await $running;
}

method create_from_sink (%args) {
    my $sink   = $args{sink} // die 'need a sink';
    my $method = $args{method} // die 'need a method name';
    my $service = $args{service} // die 'need a service name';

    push $rpc_list->@*, {
        stream => stream_name_from_service($service, $method),
        sink   => $sink,
        group  => 0
    };
}

async method stop () {
    $running->done unless $running->is_ready;
}

async method create_group ($rpc) {
    unless ($rpc->{group}) {
        await $self->redis->create_group($rpc->{stream}, $self->group_name);
        $rpc->{group} = 1;
    }
}

async method listen () {
    return $running //= (async sub {
        while (1) {
            await &fmap_void($self->$curry::curry(async method ($rpc) {
                await $self->create_group($rpc);

                my @items = await $self->redis->read_from_stream(
                    stream => $rpc->{stream},
                    group => $self->group_name,
                    client => $self->whoami
                );

                for my $item (@items) {
                    push $item->{data}->@*, ('transport_id', $item->{id});
                    try {
                        my $message = Myriad::RPC::Message::from_hash($item->{data}->@*);
                        $rpc->{sink}->emit($message);
                    } catch ($error) {
                        $log->tracef("error while parsing the incoming messages: %s", $error->message);
                        await $self->drop($rpc->{stream}, $_->{id});
                    }
                }
            }), foreach => [$self->rpc_list->@*], concurrent => 8);
            await $self->loop->delay_future(after => 0.001);
        }
    })->();
}

async method reply ($service, $message) {
    my $stream = stream_name_from_service($service, $message->rpc);
    try {
        await $self->redis->publish($message->who, $message->as_json);
        await $self->redis->ack($stream, $self->group_name, $message->transport_id);
    } catch ($e) {
        $log->warnf("Failed to reply to client due: %s", $e);
        return;
    }
}

async method reply_success ($service, $message, $response) {
    $message->response = { response => $response };
    await $self->reply($service, $message);
}

async method reply_error ($service, $message, $error) {
    $message->response = { error => { category => $error->category, message => $error->message, reason => $error->reason } };
    await $self->reply($service, $message);
}

async method drop ($stream, $id) {
    $log->tracef("Going to drop message: %s", $id);
    await $self->redis->ack($stream, $self->group_name, $id);
}

async method has_pending_requests ($service) {
    my $stream = stream_name_from_service($service);
    my $stream_info = await $self->redis->pending_messages_info($stream, $self->group_name);
    if($stream_info->[0]) {
        for my $consumer ($stream_info->[3]->@*) {
            return $consumer->[1] if $consumer->[0] eq $self->whoami;
        }
    }

    return 0;
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

