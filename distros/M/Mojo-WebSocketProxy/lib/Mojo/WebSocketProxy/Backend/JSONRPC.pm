package Mojo::WebSocketProxy::Backend::JSONRPC;

use strict;
use warnings;

use parent qw(Mojo::WebSocketProxy::Backend);

use feature qw(state);

no indirect;

use curry;

use MojoX::JSON::RPC::Client;

our $VERSION = '0.15';    ## VERSION

__PACKAGE__->register_type('jsonrpc');

sub url { return shift->{url} }

my $request_number = 0;

=head2 call_rpc

Description: Makes a remote call to a  process  returning the result to the client in JSON format. 
Before, After and error actions can be specified using call backs.
It takes the following arguments 

=over 4

=item - $c  : L<Mojolicious::Controller>

=item - $req_storage A hashref of attributes stored with the request.  This routine uses some of the,  
following named arguments. 

=over 4 

=item - url, if not specified url set on C<< $self >> object is used. Must be supplied by either method. 

=item - method, The name of the method at the remote end (this is appened to C<< $request_storage->{url} >> )

=item - msg_type, a name for this method if not supplied C<method> is used. 

=item - call_params, a hashref of arguments on top of C<req_storage> to send to remote method. This will be suplemented with C<< $req_storage->{args} >>
added as an C<args> key and be merged with C<< $req_storage->{stash_params} >> with stash_params overwriting any matching 
keys in C<call_params>. 

=item - rpc_response_callback,  If supplied this will be run with C<< Mojolicious::Controller >> instance the rpc_response and C<< $req_storage >>. 
B<Note:> if C<< rpc_response_callback >> is supplied the success and error callbacks are not used. 

=item - before_get_rpc_response,  array ref of subroutines to run before the remote response, is passed C<< $c >> and C<< req_storage >> 

=item - after_get_rpc_response, arrayref of subroutines to run after the remote response,  is passed C<< $c >> and C<< req_storage >> 
called only when there is an actual response from the remote call .  IE if there is communication  error with the call it will 
not be called versus an error message being returned from the call when it will. 

=item - before_call, arrayref of subroutines called before the request to the remote service is made. 

=item -  error,  a subroutine reference that will be called with C<< Mojolicious::Controller >> the rpc_response and C<< $req_storage >> 
if a C<< $response->{error} >>  error was returned from the remote call, and C<< $req_storage->{rpc_response_cb} >> was not passed. 

=item - success, a subroutines reference that will be called if there was no error returned from the remote call and  C<< $req_storage->{rpc_response_cb} >> was not passed. 

=item - rpc_failure_cb, a sub routine reference to call if the remote call fails at a http level. Called with C<< Mojolicious::Controller >> the rpc_response and C<< $req_storage >> 

=back

=back 

Returns undef. 

=cut

sub call_rpc {
    my ($self, $c, $req_storage) = @_;
    state $client = MojoX::JSON::RPC::Client->new;

    my $url = $req_storage->{url} // $self->url;
    die 'No url found' unless $url;

    $url .= $req_storage->{method};

    my $method   = $req_storage->{method};
    my $msg_type = $req_storage->{msg_type} ||= $req_storage->{method};

    $req_storage->{call_params} ||= {};

    my $rpc_response_cb = $self->get_rpc_response_cb($c, $req_storage);

    my $before_get_rpc_response_hook = delete($req_storage->{before_get_rpc_response}) || [];
    my $after_got_rpc_response_hook  = delete($req_storage->{after_got_rpc_response})  || [];
    my $before_call_hook             = delete($req_storage->{before_call})             || [];
    my $rpc_failure_cb               = delete($req_storage->{rpc_failure_cb});
    # If this flag true, then proxy will not send the rpc response to the client back.
    # It is very useful when websocket app itself (not websocket client) want to get information from rpc.

    my $block_response = delete($req_storage->{block_response});

    my $callobj = {
        # enough for short-term uniqueness
        id     => join('_', $$, $request_number++, time, (0 + [])),
        method => $method,
        params => $self->make_call_params($c, $req_storage),
    };

    $_->($c, $req_storage) for @$before_call_hook;

    $client->call(
        $url, $callobj,
        $client->$curry::weak(
            sub {
                my $client = shift;
                my $res    = pop;

                $_->($c, $req_storage) for @$before_get_rpc_response_hook;

                # unconditionally stop any further processing if client is already disconnected
                return unless $c->tx;

                my $api_response;
                if (!$res) {
                    my $tx = $client->tx;
                    $req_storage->{req_url} = $tx->req->url;
                    my $err = $tx->error;
                    $rpc_failure_cb->(
                        $c, $res,
                        $req_storage,
                        {
                            code    => $err->{code},
                            message => $err->{message},
                            type    => 'WrongResponse',
                        }) if $rpc_failure_cb;
                    return if $block_response;
                    $api_response = $c->wsp_error($msg_type, 'WrongResponse', 'Sorry, an error occurred while processing your request.');
                    $c->send({json => $api_response}, $req_storage);
                    return;
                }

                $_->($c, $req_storage, $res) for @$after_got_rpc_response_hook;

                if ($res->is_error) {
                    $rpc_failure_cb->(
                        $c, $res,
                        $req_storage,
                        {
                            code    => $res->error_code,
                            message => $res->error_message,
                            type    => 'CallError',
                        }) if $rpc_failure_cb;
                    return if $block_response;
                    $api_response = $c->wsp_error($msg_type, 'CallError', 'Sorry, an error occurred while processing your request.');
                    $c->send({json => $api_response}, $req_storage);
                    return;
                }

                $api_response = $rpc_response_cb->($res->result);
                return if $block_response || !$api_response;
                $c->send({json => $api_response}, $req_storage);

                return;
            }));
    return;
}

1;

__END__

=head1 NAME

Mojo::WebSocketProxy::Backend

=head1 DESCRIPTION

A subclass of L<Mojo::WebSocketProxy::Backend> which dispatched RPC requests
over JSON-RPC over HTTP/HTTPS.

=head1 METHODS

=head2 url

    $url = $backend->url

Returns the configured default dispatch URL.

=head2 call_rpc

Implements the L<Mojo::WebSocketProxy::Backend/call_rpc> interface.

=head1 SEE ALSO

L<Mojolicious::Plugin::WebSocketProxy>,
L<Mojo::WebSocketProxy>
L<Mojo::WebSocketProxy::Dispatcher>,
L<Mojo::WebSocketProxy::Config>
L<Mojo::WebSocketProxy::Parser>

=cut
