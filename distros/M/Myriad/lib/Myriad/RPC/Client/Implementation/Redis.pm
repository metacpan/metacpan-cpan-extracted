package Myriad::RPC::Client::Implementation::Redis;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

use Myriad::Class extends => qw(IO::Async::Notifier);

use Myriad::Util::UUID;
use Myriad::RPC::Implementation::Redis qw(stream_name_from_service);
use Myriad::RPC::Message;

use constant DEFAULT_RPC_TIMEOUT_SECONDS => 30;

has $redis;
has $subscription;
has $pending_requests;
has $whoami;
has $current_id;
has $started;

BUILD {
    $pending_requests = {};
    $whoami = Myriad::Util::UUID::uuid();
    $current_id = 0;
}

method configure (%args) {
    $redis = delete $args{redis} if $args{redis};
}

method is_started() {
    return defined $started ? $started : Myriad::Exception::InternalError->new(message => '->start was not called')->throw;
}

async method start() {
    $started = $self->loop->new_future(label => 'rpc_client_subscription');
    my $sub = await $redis->subscribe($whoami);
    $subscription = $sub->events->map('payload')->map(sub{
        try {
            my $payload = $_;
            $log->tracef('Received RPC response as %s', $payload);

            my $message = Myriad::RPC::Message::from_json($payload);

            if(my $pending = delete $pending_requests->{$message->message_id}) {
                return $pending->done($message);
            }
            $log->tracef('No pending future for message %s', $message->message_id);
        } catch ($e) {
            $log->warnf('failed to parse rpc response due %s', $e);
        }
    })->completed;

    $started->done('started');

    await $subscription;
}

async method call_rpc($service, $method, %args) {
    $service = stream_name_from_service($service);
    my $pending = $self->loop->new_future(label => "rpc::request::${service}::${method}");

    my $message_id = $self->next_id;
    my $timeout = delete $args{timeout} || DEFAULT_RPC_TIMEOUT_SECONDS;
    my $deadline = time + $timeout;

    my $request = Myriad::RPC::Message->new(
        rpc        => $method,
        who        => $whoami,
        deadline   => $deadline,
        message_id => $message_id,
        args       => \%args,
    );

    try {
        await $self->is_started();
        await $redis->xadd($service => '*', $request->as_hash->%*);
        $log->tracef('Sent RPC request %s', $request->as_hash);
        $pending_requests->{$message_id} = $pending;

        # The subscription loop will parse the message for us
        my $message = await Future->wait_any($self->loop->timeout_future(after => $timeout), $pending);

        return $message->response;
    } catch ($e) {
        $log->tracef('RPC request failed due: %s', $e);
        if ($e =~ /Timeout/) {
            $e  = Myriad::Exception::RPC::Timeout->new(reason => 'deadline is due');
        } else {
            $e = Myriad::Exception::InternalError->new(reason => $e) unless blessed $e && $e->isa('Myriad::Exception');
        }
        $pending->fail($e);
        delete $pending_requests->{$message_id};
        $e->throw();
    }
}

async method stop {
    $subscription->done();
}

method next_id {
    return $current_id++;
}

1;

