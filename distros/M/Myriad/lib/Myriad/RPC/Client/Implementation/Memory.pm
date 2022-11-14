package Myriad::RPC::Client::Implementation::Memory;

use Myriad::Class extends => qw(IO::Async::Notifier);

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::RPC::Client::Implementation::Memory

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Myriad::Util::UUID;
use Myriad::RPC::Message;

has $transport;
has $whoami;
has $current_id;
has $subscription;
has $pending_requests;
has $started;

BUILD {
    $whoami = Myriad::Util::UUID::uuid();
    $current_id = 0;
    $pending_requests = {};
}

method configure (%args) {
    $transport = delete $args{transport} if $args{transport};
}

method is_started() {
    return defined $started ? $started : Myriad::Exception::InternalError->new(message => '->start was not called')->throw;
}

async method start {
    $started = $self->loop->new_future(label => 'rpc_client_subscription');
    my $sub = await $transport->subscribe($whoami);
    $subscription = $sub->each(sub {
        try {
            my $payload = $_;
            my $message = Myriad::RPC::Message::from_json($payload);
            if(my $pending = delete $pending_requests->{$message->message_id}) {
                return $pending->done($message);
            }
        } catch ($e) {
            $log->warnf('failed to parse rpc response due %s', $e);
        }
    })->completed();

    $started->done('started');

    await $subscription;
}

async method stop {
    $subscription->done();
}

async method call_rpc ($service, $method, %args) {
    my $pending = $self->loop->new_future(label => "rpc_request::${service}::{$method}");

    my $deadline = time + 5;
    my $message_id = $current_id++;

    my $request = Myriad::RPC::Message->new(
        rpc        => $method,
        who        => $whoami,
        deadline   => $deadline,
        message_id => $message_id,
        args       => \%args,
    );

    $pending_requests->{$message_id} = $pending;
    await $self->is_started();
    await $transport->add_to_stream("service.$service.rpc/$method", $request->as_hash->%*);

    try {
        my $message = await Future->wait_any(
            $self->loop->timeout_future(at => $deadline),
            $pending
        );
        return $message->response->{response};
    } catch ($e) {
        if ($e =~ /Timeout/) {
            $e  = Myriad::Exception::RPC::Timeout->new(reason => 'deadline is due');
        } else {
            $e = Myriad::Exception::InternalError->new(reason => $e) unless blessed $e && $e->does('Myriad::Exception');
        }
        $pending->fail($e);
        delete $pending_requests->{$message_id};
        $e->throw();
    }
}

method _add_to_loop ($loop) {
    $self->start->retain();
    $self->next::method($loop);
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

