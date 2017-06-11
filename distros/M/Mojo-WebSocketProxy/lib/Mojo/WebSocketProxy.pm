package Mojo::WebSocketProxy;

use strict;
use warnings;

our $VERSION = '0.06';

1;

__END__

=head1 NAME

Mojo::WebSocketProxy - WebSocket proxy for JSON-RPC 2.0 server

=head1 SYNOPSYS

    # lib/your-application.pm

    use parent 'Mojolicious';

    sub startup {
        my $self = shift;
        $self->plugin(
            'web_socket_proxy' => {
                actions => [
                    ['json_key', {some_param => 'some_value'}]
                ],
                base_path => '/api',
                url => 'http://rpc-host.com:8080/',
            }
        );
   }

Or to manually call RPC server:

    # lib/your-application.pm

    use parent 'Mojolicious';

    sub startup {
        my $self = shift;
        $self->plugin(
            'web_socket_proxy' => {
                actions => [
                    [
                        'json_key',
                        {
                            instead_of_forward => sub {
                                shift->call_rpc({
                                    args => $args,
                                    method => $rpc_method, # it'll call 'http://rpc-host.com:8080/rpc_method'
                                    rpc_response_cb => sub {...}
                                });
                            }
                        }
                    ]
                ],
                base_path => '/api',
                url => 'http://rpc-host.com:8080/',
            }
        );
   }

=head1 DESCRIPTION

Using this module you can forward WebSocket-JSON requests to RPC server.

For every message it creates separate hash ref storage, which is available from hooks as $req_storage.
Request storage have RPC call parameters in $req_storage->{call_params}.
It copies message args to $req_storage->{call_params}->{args}.
You can use Mojolicious stash to store data between messages in one connection.

=head1 Proxy responses

The plugin sends websocket messages to clietn with RPC response data.
If RPC reponse looks like this:

    {status => 1}

It returns simple response like this:

    {$msg_type => 1, msg_type => $msg_type}

If RPC returns something like this:

    {
        response_data => [..],
        status        => 1,
    }

Plugin returns common response like this:

    {
        $msg_type => $rpc_response,
        msg_type  => $msg_type,
    }

You can customize ws porxy response using 'response' hook.

=head1 Plugin parameters

The plugin understands the following parameters.

=head2 actions

A pointer to array of action details, which contain stash_params,
request-response callbacks, other call parameters.

    $self->plugin(
        'web_socket_proxy' => {
            actions => [
                ['action1_json_key', {details_key1 => details_value1}],
                ['action2_json_key']
            ]
        });

=head2 before_forward

    before_forward => [sub { my ($c, $req_storage) = @_; ... }, sub {...}]

Global hooks which will run after request is dispatched and before to start preparing RPC call.
It'll run every hook or until any hook returns some non-empty result.
If returns any hash ref then that value will be JSON encoded and send to client,
without forward action to RPC. To call RPC every hook should return empty or undefined value.
It's good place to some validation or subscribe actions.

=head2 after_forward

    after_forward => [sub { my ($c, $result, $req_storage) = @_; ... }, sub {...}]

Global hooks which will run after every forwarded RPC call done.
Or even forward action isn't running.
It can view or modify result value from 'before_forward' hook.
It'll run every hook or until any hook returns some non-empty result.
If returns any hash ref then that value will be JSON encoded and send to client.

=head2 after_dispatch

    after_dispatch => [sub { my $c = shift; ... }, sub {...}]

Global hooks which will run at the end of request handling.

=head2 before_get_rpc_response (global)

    before_get_rpc_response => [sub { my ($c, $req_storage) = @_; ... }, sub {...}]

Global hooks which will run when asynchronous RPC call is answered.

=head2 after_got_rpc_response (global)

    after_got_rpc_response => [sub { my ($c, $req_storage) = @_; ... }, sub {...}]

Global hooks which will run after checked that response exists.

=head2 before_send_api_response (global)

    before_send_api_response => [sub { my ($c, $req_storage, $api_response) = @_; ... }, sub {...}]

Global hooks which will run immediately before send API response.

=head2 after_sent_api_response (global)

    before_send_api_response => [sub { my ($c, $req_storage) = @_; ... }, sub {...}]

Global hooks which will run immediately after sent API response.

=head2 base_path

API url for make route.

=head2 stream_timeout

See L<Mojo::IOLoop::Stream/"timeout">

=head2 max_connections

See L<Mojo::IOLoop/"max_connections">

=head2 max_response_size

Returns error if RPC response size is over value.

=head2 opened_connection

Callback for doing something once after connection is opened

=head2 finish_connection

Callback for doing something every time when connection is closed.

=head2 url

RPC host url - store url string or function to set url dynamically for manually RPC calls.
When using forwarded call then url storing in request storage.
You can store url in every action options, or make it at before_forward hook.

=head1 Actions options

=head2 stash_params

    stash_params => [qw/ stash_key1 stash_key2 /]

Will send specified parameters from Mojolicious $c->stash.
You can store RPC response data to Mojolicious stash returning data like this:

    rpc_response => {
        stast => {..} # data to store in Mojolicious stash
        response_key1 => response_value1, # response to API client
        response_key2 => response_value2
    }

=head2 success

    success => sub { my ($c, $rpc_response) = @_; ... }

Hook which will run if RPC returns success value.

=head2 error

    error => sub { my ($c, $rpc_response) = @_; ... }

Hook which will run if RPC returns value with error key, e.g.

    { result => { error => { code => 'some_error' } } }

=head2 response

    response => sub { my ($c, $rpc_response) = @_; ... }

Hook which will run every time when success or error callbacks is running.
It good place to modify API response format.

=head1 SEE ALSO

L<Mojolicious::Plugin::WebSocketProxy>,
L<Mojo::WebSocketProxy>
L<Mojo::WebSocketProxy::CallingEngine>,
L<Mojo::WebSocketProxy::Dispatcher>,
L<Mojo::WebSocketProxy::Config>
L<Mojo::WebSocketProxy::Parser>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 binary.com

=cut
