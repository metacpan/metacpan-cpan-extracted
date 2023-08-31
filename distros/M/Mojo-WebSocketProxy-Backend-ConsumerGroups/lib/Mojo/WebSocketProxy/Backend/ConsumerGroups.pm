package Mojo::WebSocketProxy::Backend::ConsumerGroups;

# ABSTRACT: Class for communication with backend by sending messaging through redis streams.

use strict;
use warnings;

use Log::Any qw($log);
use Mojo::Redis2;
use IO::Async::Loop::Mojo;
use Data::UUID;
use JSON::MaybeUTF8 qw(encode_json_utf8 decode_json_utf8);
use Syntax::Keyword::Try;
use curry::weak;
use MojoX::JSON::RPC::Client;

use parent qw(Mojo::WebSocketProxy::Backend);

no indirect;

our $VERSION = '0.04';

__PACKAGE__->register_type('consumer_groups');

use constant RESPONSE_TIMEOUT             => $ENV{RPC_QUEUE_RESPONSE_TIMEOUT} // 30;
use constant DEFAULT_CATEGORY_NAME        => 'general';
use constant REQUIRED_RESPONSE_PARAMETERS => qw(message_id response);


sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}


sub loop {
    my $self = shift;
    return $self->{loop} //= do {
        local $ENV{IO_ASYNC_LOOP} = 'IO::Async::Loop::Mojo';
        IO::Async::Loop->new;
    };
}


sub pending_requests {
    return shift->{pending_requests} //= {};
}


sub redis {
    my $self = shift;
    return $self->{redis} //= Mojo::Redis2->new(
        url      => $self->{redis_uri},
        encoding => undef,
    );
}


sub timeout {
    return shift->{timeout} //= RESPONSE_TIMEOUT;
}


sub category_timeout_config {
    return shift->{category_timeout_config} //= {};
}


sub queue_separation_enabled {
    return shift->{queue_separation_enabled} //= 0;
}


sub whoami {
    my $self = shift;
    return $self->{whoami} if $self->{whoami};

    $self->{whoami} = Data::UUID->new->create_str();

    return $self->{whoami};
}


sub call_rpc {
    my ($self, $c, $req_storage) = @_;

    my $rpc_response_cb               = $self->get_rpc_response_cb($c, $req_storage);
    my $before_get_rpc_response_hooks = delete($req_storage->{before_get_rpc_response}) || [];
    my $after_got_rpc_response_hooks  = delete($req_storage->{after_got_rpc_response})  || [];
    my $before_call_hooks             = delete($req_storage->{before_call})             || [];
    my $rpc_failure_cb                = delete($req_storage->{rpc_failure_cb});
    # stream category which message should be assigned to
    $req_storage->{category} = $self->queue_separation_enabled && $req_storage->{category} ? $req_storage->{category} : DEFAULT_CATEGORY_NAME;

    foreach my $hook ($before_call_hooks->@*) { $hook->($c, $req_storage) }

    my $category_timeout = $self->_rpc_category_timeout($req_storage->{category});

    my $block_response = delete($req_storage->{block_response});
    my ($msg_type, $request_data) = $self->_prepare_request_data($c, $req_storage, $category_timeout);
    $self->request($request_data, $req_storage->{category}, $category_timeout)->then(
        sub {
            my ($message) = @_;

            foreach my $hook ($before_get_rpc_response_hooks->@*) { $hook->($c, $req_storage) }

            return Future->done unless $c && $c->tx;

            my $result = MojoX::JSON::RPC::Client::ReturnObject->new(rpc_response => $message->{response});

            foreach my $hook ($after_got_rpc_response_hooks->@*) { $hook->($c, $req_storage, $result) }

            my $api_response;
            if ($result->is_error) {
                $rpc_failure_cb->(
                    $c, $result,
                    $req_storage,
                    {
                        code    => $result->error_code,
                        message => $result->error_message,
                        type    => 'CallError',
                    }) if $rpc_failure_cb;

                return Future->done if $block_response;
                $api_response = $c->wsp_error($msg_type, 'CallError', 'Sorry, an error occurred while processing your request.');
                $c->send({json => $api_response}, $req_storage);
                return Future->done;
            }

            $api_response = $rpc_response_cb->($result->result);
            return Future->done if $block_response || !$api_response;
            $c->send({json => $api_response}, $req_storage);

            return Future->done;
        }
    )->catch(
        sub {
            my $error = shift;
            my $api_response;

            return Future->done unless $c && $c->tx;

            my $err_type = $error eq 'Timeout' ? $error : "RedisError";
            $rpc_failure_cb->(
                $c, undef,
                $req_storage,
                {
                    code    => $err_type,
                    message => $error,
                    type    => $err_type,
                }) if $rpc_failure_cb;

            $api_response = $c->wsp_error($msg_type, 'WrongResponse', 'Sorry, an error occurred while processing your request.');

            return Future->done if $block_response || !$api_response;

            $c->send({json => $api_response}, $req_storage);
        })->retain;

    return;
}


sub request {
    my ($self, $request_data, $category_name, $category_timeout) = @_;

    my $complete_future = $self->loop->new_future;

    $self->wait_for_messages();

    my $msg_id = $self->_next_request_id;

    $self->pending_requests->{$msg_id} = $complete_future;
    $complete_future->on_cancel(sub { delete $self->pending_requests->{$msg_id} });

    push @$request_data, ('message_id' => $msg_id);

    my $sent_future = $self->_send_request($request_data, $category_name);
    return Future->wait_any($self->loop->timeout_future(after => $category_timeout), Future->needs_all($complete_future, $sent_future));
}

# We need to provide uniqueness inside every instance of Mojo::WebSocketProxy::Backend::ConsumerGroups,
# Also, the uniqueness of `whoami` will guarantee us that we'll get requests' expected response.
sub _next_request_id {
    my ($self) = @_;

    $self->{request_seq_id} //= 0;

    return ++$self->{request_seq_id};
}

sub _rpc_category_timeout {
    my ($self, $category_name) = @_;

    return $self->category_timeout_config->{$category_name} // $self->timeout;
}

sub _send_request {
    my ($self, $request_data, $category_name) = @_;

    my $f = $self->loop->new_future;
    $self->redis->_execute(
        xadd => XADD => ($category_name, qw(MAXLEN ~ 100000), '*', $request_data->@*),
        sub {
            my ($redis, $err) = @_;

            return $f if $f->is_ready;

            return $f->fail($err) if $err;

            return $f->done();
        });

    return $f;
}


sub wait_for_messages {
    my ($self) = @_;
    $self->{already_waiting} //= $self->redis->subscribe([$self->whoami], $self->redis->curry::weak::on(message => $self->curry::weak::_on_message));

    return;
}

sub _on_message {
    my ($self, $redis, $raw_message) = @_;

    my $message = {};

    try {
        $message = decode_json_utf8($raw_message);
    } catch {
        my $err = $@;

        $log->errorf('An error occurred while decoding published response from worker: %s', $err);
        return;
    }

    if (ref $message ne 'HASH') {
        $log->errorf("Failed to process response: Invalid message type got: %s, want: HASH", ref $message);
        return;
    }

    my (@missing_params) = grep { !exists $message->{$_} } REQUIRED_RESPONSE_PARAMETERS;
    if (@missing_params) {
        $log->errorf("Failed to process response: '%s' are missing, original message content was %s", join(",", @missing_params), $raw_message);
        return;
    }

    my $completion_future = delete $self->pending_requests->{$message->{message_id}};

    return unless $completion_future;

    $completion_future->done($message);

    return;
}

sub _prepare_request_data {
    my ($self, $c, $req_storage, $req_timeout) = @_;

    $req_storage->{call_params} ||= {};

    my $method   = $req_storage->{method};
    my $msg_type = $req_storage->{msg_type} ||= $req_storage->{method};

    my $params = $self->make_call_params($c, $req_storage);
    $params->{correlation_id} = $c->stash('correlation_id');
    my $stash_params = $req_storage->{stash_params};

    my $request_data = [
        rpc      => $method,
        who      => $self->whoami,
        deadline => time + $req_timeout,

        $params       ? (args  => encode_json_utf8($params))       : (),
        $stash_params ? (stash => encode_json_utf8($stash_params)) : (),
    ];

    return $msg_type, $request_data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::WebSocketProxy::Backend::ConsumerGroups - Class for communication with backend by sending messaging through redis streams.

=head1 VERSION

version 0.04

=head1 DESCRIPTION

Class for communication with backend by sending messaging through redis streams.

=over 4

=item * C<Redis streams> is used as channel for sending request to backend servers.

=item * C<Redis subscriptions> is used as channel for receiving responses from backend servers.

=back

=head1 NAME

Mojo::WebSocketProxy::Backend::ConsumerGroup

=head1 METHODS

=head2 new

Creates object instance of the class

=over 4

=item * C<redis_uri> - URI for Redis connection. Ignored if the C<redis> argument is also given.

=item * C<redis> - Redis client object (must be compatible with L<Mojo::Redis2>). This argument will override the C<redis_uri> argument.

=item * C<timeout> - Request timeout, in seconds. If not set, uses the environment variable C<RPC_QUEUE_RESPONSE_TIMEOUT>, or defaults to 30

=item * C<queue_separation_enabled> - Boolean to specify if messages should be assigned to different queus based on their C<category> or only C<general> queue.

=item * C<category_timeout_config> - A hash containing the timeout value for each request category.

    { general => 5, other => 120 }

=back

=head2 loop

=head2 pending_requests

Returns C<hashref> which is used as a storage for keeping requests which were sent.
Stucture of the hash should be like:

=over 4

=item * C<key> - request id, which we'll get from redis after successful adding request to the stream

=item * C<value> - future object, which will be done in case of getting response, of cancelled in case of timeout

=back

=head2 redis

=head2 timeout

=head2 category_timeout_config

Hash containing the timeout value for each rpc call category.

    { general => 5, other => 120 }

=head2 queue_separation_enabled

Boolean specifying if category separation should be enabled.

=head2 whoami

Return unique ID of Redis which will be used by backend server to send response.
Id is persistent for the object.

=head2 call_rpc

Makes a remote call to a process  returning the result to the client in JSON format.
Before, After and error actions can be specified using call backs.
It takes the following arguments

=over 4

=item * C<$c>  : L<Mojolicious::Controller>

=item * C<$req_storage> A hashref of attributes stored with the request.  This routine uses some of the following named arguments:

=over 4

=item * C<method> The name of the method at the remote end.

=item * C<msg_type> a name for this method; if not supplied C<method> is used.

=item * C<call_params> a hashref of arguments on top of C<req_storage> to send to remote method. This will be suplemented with C<< $req_storage->{args} >>
added as an C<args> key and be merged with C<< $req_storage->{stash_params} >> with stash_params overwriting any matching
keys in C<call_params>.

=item * C<rpc_response_callback>  If supplied this will be run with args: C<< Mojolicious::Controller >> instance, the rpc_response and C<< $req_storage >>.
B<Note:> if C<< rpc_response_callback >> is supplied the success and error callbacks are not used.

=item * C<before_get_rpc_response>  arrayref of subroutines to be run before the remote response is received, with args: C<< $c >> and C<< req_storage >>

=item * C<after_get_rpc_response> arrayref of subroutines to be run after the remote response is received; called with args: C<< $c >> and C<< req_storage >>
called only when there is an response from the remote call.

=item * C<before_call> arrayref of subroutines called before the request to the remote service is made.

=item * C<rpc_failure_cb> a subroutine reference to call if the remote call fails. Called with C<< Mojolicious::Controller >>, the rpc_response and C<< $req_storage >>

=item * C<category> - if supplied, the message will be assigned to the Redis channel with the corresponding name. The I<< general >> channel will be used by default if either C<< $msg_type >> is not provided or C<queue_separation_enabled> is 0.

=back

=back

Returns undef.

=head2 request

Sends request to backend service. The method accepts following arguments:

=over 4

=item * C<request_data> - an C<arrayref> containing data for the item which is going to be put into redis stream.

=item * C<$category_name> - this will be passed to C<_send_request> to specify which redis category this message belongs to.

=item * C<category_timeout> - timeout value for this specific call (differs based on category)

=back

Returns future.
Which will be marked as done in case getting response from backend server.
And it'll be marked as failed in case of request timeout or in case of error putting request to redis stream.

=head2 wait_for_messages

By using redis subscription, we subscribe on channel for receiving responses from backend server.
We'll use uniq id generated by L<whoami> as subscription channel.
Subscription will be done only once within first request to backend server.

=head1 SEE ALSO

L<Mojolicious::Plugin::WebSocketProxy>,
L<Mojo::WebSocketProxy>
L<Mojo::WebSocketProxy::Backend>,
L<Mojo::WebSocketProxy::Dispatcher>,
L<Mojo::WebSocketProxy::Config>
L<Mojo::WebSocketProxy::Parser>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 deriv.com

=head1 AUTHOR

DERIV <DERIV@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Deriv Services Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
