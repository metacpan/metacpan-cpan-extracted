package Myriad::RPC::Implementation::Memory;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use Sys::Hostname qw(hostname);
use Syntax::Keyword::Try qw( try :experimental(typed) );

use Role::Tiny::With;
with 'Myriad::Role::RPC';

use Myriad::Exception::General;
use Myriad::RPC::Message;

use Myriad::Class extends => qw(IO::Async::Notifier);

=head1 NAME

Myriad::RPC::Implementation::Memory - microservice RPC in-memory implementation.

=head1 DESCRIPTION

=cut

has $transport;

has $group_name;
method group_name { $group_name //= 'processors' }


has $should_shutdown;
has $rpc_methods;
has $services_list;

method configure(%args) {
    $transport = delete $args{transport} if exists $args{transport};

    $self->next::method(%args);
}

=head1 METHODS

=head2 start

Start waiting for new requests to fill in the internal requests queue.

=cut

async method start () {
    $should_shutdown //= $self->loop->new_future(label => 'rpc::memory::shutdown_future')->without_cancel;

    while (1) {
        if ($services_list && $services_list->@*) {
            my $service = shift $services_list->@*;
            push $services_list->@*, $service;

            try {
                 await $transport->create_consumer_group($service, $self->group_name, 0, 1);
            } catch {
                $log->tracef("Group alrady exists");
            }

            my %messages = await $transport->read_from_stream_by_consumer($service, $self->group_name, hostname());
            for my $id (sort keys %messages) {
                my $message;
                try {
                    $messages{$id}->{transport_id} = $id;
                    $message = Myriad::RPC::Message::from_hash($messages{$id}->%*);
                    if (my $sink = $rpc_methods->{$service}->{$message->rpc}) {
                        $sink->emit($message);
                    } else {
                        Myriad::Exception::RPC::MethodNotFound->throw(reason => $message->rpc);
                    }
                } catch ($e isa Myriad::Exception::RPC::BadEncoding) {
                    $log->warnf('Recived a dead message that we cannot parse, going to drop it.');
                    $log->tracef("message was: %s", $messages{$id});
                    await $self->drop($service, $id);
                } catch ($e) {
                    await $self->reply_error($service, $message, $e);
                }
            }
        }
        await Future::wait_any($should_shutdown, $self->loop->delay_future(after => 0.1));
    }
}

=head2 create_from_sink

Register and RPC call and save a reference to its L<Ryu::Sink>.

=cut

method create_from_sink (%args) {
    my $sink   = $args{sink} // die 'need a sink';
    my $method = $args{method} // die 'need a method name';
    my $service = $args{service} // die 'need a service';

    push $services_list->@*, $service unless $rpc_methods->{$service};

    $rpc_methods->{$service}->{$method} = $sink;
}

=head2 stop

Gracefully stop the RPC processing.

=cut

async method stop () {
    $should_shutdown->done() unless $should_shutdown->is_ready;
}

=head2 reply_success

Reply to the requester with a success message.

In this implementation it's done by resolving the L<Future> calling C<done>.

=cut

async method reply_success ($service, $message, $response) {
    $message->response = { response => $response };
    await $transport->publish($message->who, $message->as_json);
    await $transport->ack_message($service, $self->group_name, $message->transport_id);
}

=head2 reply_error

Reply to the requester with a failure message.

In this implementation it's done by resolving the L<Future> calling C<fail>.

=cut

async method reply_error ($service, $message, $error) {
    $message->response = { error => { category => $error->category, message => $error->message, reason => $error->reason } };
    await $transport->publish($message->who, $message->as_json);
    await $transport->ack_message($service, $self->group_name, $message->transport_id);
}

=head2 drop

Drop the request because we can't reply to the requester.

=cut

async method drop ($service, $id) {
    await $transport->ack_message($service, $self->group_name, $id);
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

