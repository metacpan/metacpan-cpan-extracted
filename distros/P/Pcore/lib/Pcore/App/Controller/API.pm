package Pcore::App::Controller::API;

use Pcore -role, -result, -const;
use Pcore::Util::Data qw[from_json to_json from_cbor to_cbor from_uri_query];
use Pcore::WebSocket;

with qw[Pcore::App::Controller];

const our $WS_MAX_MESSAGE_SIZE => 1_024 * 1_024 * 100;    # 100 Mb
const our $WS_PONG_INTERVAL    => 50;
const our $WS_COMPRESSION      => 0;

const our $TRANS_TYPE_RPC       => 'rpc';
const our $TRANS_TYPE_EXCEPTION => 'exception';

sub run ( $self, $req ) {
    if ( $req->{path_tail} ) {
        $req->(404)->finish;

        return;
    }

    # WebSocket API request
    if ( $req->is_websocket_connect_request ) {
        Pcore::WebSocket->accept_ws(
            'pcore', $req,
            sub ( $ws, $req, $accept, $reject ) {

                # authenticate request
                $req->authenticate(
                    sub ( $auth ) {

                        # token authenticated successfully, store token in websocket connection object
                        $ws->{auth} = $auth;

                        # accept websocket connection
                        $accept->(
                            {   max_message_size => $WS_MAX_MESSAGE_SIZE,
                                pong_interval    => $WS_PONG_INTERVAL,
                                compression      => $WS_COMPRESSION,
                                on_disconnect    => sub ( $ws, $status ) {
                                    return;
                                },
                                on_rpc_call => sub ( $ws, $req, $trans ) {
                                    $ws->{auth}->api_call_arrayref( $trans->{method}, $trans->{data}, $req );

                                    return;
                                }
                            },
                            headers        => undef,
                            before_connect => undef,
                            on_connect     => undef,
                        );

                        return;
                    }
                );

                return;
            },
        );
    }

    # HTTP API request
    else {
        my $env = $req->{env};

        my $msg;

        my $CBOR = 0;

        # decode API request
        if ( !$env->{CONTENT_TYPE} || $env->{CONTENT_TYPE} =~ m[\bapplication/json\b]smi ) {
            $msg = eval { from_json $req->body };

            # content decode error
            if ($@) {
                $req->( [ 400, q[Error decoding JSON request body] ] )->finish;

                return;
            }
        }

        elsif ( $env->{CONTENT_TYPE} =~ m[\bapplication/cbor\b]smi ) {
            $msg = eval { from_cbor $req->body };

            # content decode error
            if ($@) {
                $req->( [ 400, q[Error decoding JSON request body] ] )->finish;

                return;
            }

            $CBOR = 1;
        }

        # invalid content type
        else {
            $req->(415)->finish;

            return;
        }

        # authenticate request
        $req->authenticate(
            sub ( $auth ) {

                # this is app connection, disabled
                if ( $auth->{is_app} ) {
                    $req->( [ 403, q[App must connect via WebSocket interface] ] )->finish;
                }
                else {
                    $self->_http_api_router(
                        $auth, $msg,
                        sub ($res) {
                            if ($CBOR) {

                                # write HTTP response
                                $req->( 200, [ 'Content-Type' => 'application/cbor' ], to_cbor $res )->finish;
                            }
                            else {

                                # write HTTP response
                                $req->( 200, [ 'Content-Type' => 'application/json' ], to_json $res)->finish;
                            }

                            # free HTTP request object
                            undef $req;

                            return;
                        }
                    );
                }

                return;
            }
        );
    }

    return;
}

sub _http_api_router ( $self, $auth, $data, $cb ) {
    $data = [$data] if ref $data ne 'ARRAY';

    my $response;

    my $cv = AE::cv sub {
        $cb->($response);

        return;
    };

    $cv->begin;

    for my $trans ( $data->@* ) {

        # TODO required only for compatibility with old clients, can be removed
        $trans->{type} ||= $TRANS_TYPE_RPC;

        # check message type, only rpc calls are enabled here
        if ( $trans->{type} ne $TRANS_TYPE_RPC ) {
            push $response->@*,
              { tid     => $trans->{tid},
                type    => $TRANS_TYPE_EXCEPTION,
                message => {
                    status => 400,
                    reason => 'Invalid API request type',
                },
              };

            next;
        }

        # method is not specified, this is callback, not supported in API server
        if ( !$trans->{method} ) {
            push $response->@*,
              { tid     => $trans->{tid},
                type    => $TRANS_TYPE_EXCEPTION,
                message => {
                    status => 400,
                    reason => 'Method is required',
                },
              };

            next;
        }

        $cv->begin;

        # combine method with action
        if ( my $action = delete $trans->{action} ) {
            $trans->{method} = q[/] . ( $action =~ s[[.]][/]smgr ) . "/$trans->{method}";
        }

        $auth->api_call_arrayref(
            $trans->{method},
            $trans->{data},
            sub ($res) {
                if ( $res->is_success ) {
                    push $response->@*,
                      { type   => $TRANS_TYPE_RPC,
                        tid    => $trans->{tid},
                        result => $res,
                      };
                }
                else {
                    push $response->@*,
                      { type    => $TRANS_TYPE_EXCEPTION,
                        tid     => $trans->{tid},
                        message => $res,
                      };
                }

                $cv->end;

                return;
            }
        );
    }

    $cv->end;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Controller::API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
