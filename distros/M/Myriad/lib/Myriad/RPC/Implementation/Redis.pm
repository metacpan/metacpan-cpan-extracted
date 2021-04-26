package Myriad::RPC::Implementation::Redis;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use Role::Tiny::With;
with 'Myriad::Role::RPC';

use Myriad::Class extends => qw(IO::Async::Notifier);

use Future::Utils qw(fmap0);

use constant RPC_SUFFIX => '/rpc';
use constant RPC_PREFIX => 'service';
use Exporter qw(import);
our @EXPORT_OK = qw(stream_name_from_service);

=head1 NAME

Myriad::RPC::Implementation::Redis - microservice RPC Redis implementation.

=head1 DESCRIPTION

=cut

use Sys::Hostname qw(hostname);
use Scalar::Util qw(blessed);

use Myriad::Exception::InternalError;
use Myriad::RPC::Message;

has $redis;
method redis { $redis }

has $group_name;
method group_name { $group_name }

has $whoami;
method whoami { $whoami }

has $rpc_methods;
has $streams_list;

has $running;

sub service_name_from_stream ($stream) {
    my $pattern = RPC_PREFIX . '\.(.*)' . RPC_SUFFIX . '$';
    $stream =~ s/$pattern/$1/;
    return $stream;
}

sub stream_name_from_service ($service) {
    return RPC_PREFIX . ".$service" . RPC_SUFFIX;
}

method configure (%args) {
    $redis = delete $args{redis} if exists $args{redis};
    $whoami = hostname();
    $group_name = 'processors';
}

async method start () {
    $self->listen;
    await $running;
}

method create_from_sink (%args) {
    my $sink   = $args{sink} // die 'need a sink';
    my $method = $args{method} // die 'need a method name';
    my $service = $args{service} // die 'need a service name';

    $rpc_methods->{$service}->{$method} = $sink;
    push $streams_list->@*, {name => stream_name_from_service($service), group => 0};
}

async method stop () {
    $running->done unless $running->is_ready;
}

async method create_group ($stream) {
    unless ($stream->{group}) {
        await $self->redis->create_group($stream->{name},$self->group_name);
        $stream->{group} = 1;
    }
}

async method listen () {
    return $running //= (async sub {
        while (1) {
            if ($streams_list && $streams_list->@*) {
                my $stream = shift $streams_list->@*;
                push $streams_list->@*, $stream;

                await $self->create_group($stream);

                my @items = await $self->redis->read_from_stream(
                    stream => $stream->{name},
                    group => $self->group_name,
                    client => $self->whoami
                );

                for my $item (@items) {
                    push $item->{data}->@*, ('transport_id', $item->{id});
                    my $service = service_name_from_stream($item->{stream});
                    try {
                        my $message = Myriad::RPC::Message::from_hash($item->{data}->@*);
                        if (my $sink = $rpc_methods->{$service}->{$message->rpc}) {
                            $sink->emit($message);
                        } else {
                            await $self->reply_error(
                                $service,
                                $message,
                                Myriad::Exception::RPC::MethodNotFound->new(reason => "No such method: " . $message->rpc),
                            );
                        }
                    } catch ($error) {
                        $log->tracef("error while parsing the incoming messages: %s", $error->message);
                        await $self->drop($_->{service}, $_->{id});
                    }
                }
            } else {
                await $self->loop->delay_future(after => 0.001);
            }
        }
    })->();
}

async method reply ($service, $message) {
    my $stream = stream_name_from_service($service);
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

async method drop ($service, $id) {
    $log->tracef("Going to drop message: %s", $id);
    my $stream = stream_name_from_service($service);
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

