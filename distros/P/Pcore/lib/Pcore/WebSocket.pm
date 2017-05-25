package Pcore::WebSocket;

use Pcore -result;
use Pcore::Util::Scalar qw[refaddr];
use Pcore::Util::Data qw[to_b64];
use Pcore::Util::List qw[pairs];
use Pcore::WebSocket::Handle;
use Pcore::AE::Handle2 qw[:TLS_CTX];

our $HANDLE = {};

sub accept_ws ( $self, $protocol, $req, $on_accept ) {

    # this is websocket connect request
    if ( $req->is_websocket_connect_request ) {
        my $env = $req->{env};

        # websocket version is not specified or not supported
        return $req->return_xxx( [ 400, q[Unsupported WebSocket version] ] ) if !$env->{HTTP_SEC_WEBSOCKET_VERSION} || $env->{HTTP_SEC_WEBSOCKET_VERSION} ne $Pcore::WebSocket::Handle::WEBSOCKET_VERSION;

        # websocket key is not specified
        return $req->return_xxx( [ 400, q[WebSocket SEC_WEBSOCKET_KEY header is required] ] ) if !$env->{HTTP_SEC_WEBSOCKET_KEY};

        # check websocket protocol
        if ($protocol) {
            if ( !$env->{HTTP_SEC_WEBSOCKET_PROTOCOL} || $env->{HTTP_SEC_WEBSOCKET_PROTOCOL} !~ /\b$protocol\b/smi ) {
                return $req->return_xxx( [ 400, q[Unsupported WebSocket protocol] ] );
            }
        }
        elsif ( $env->{HTTP_SEC_WEBSOCKET_PROTOCOL} ) {
            return $req->return_xxx( [ 400, q[Unsupported WebSocket protocol] ] );
        }

        # load wesocket protocol class
        my $implementation = $protocol || 'raw';

        eval { require "Pcore/WebSocket/Protocol/$implementation.pm" };    ## no critic qw[Modules::RequireBarewordIncludes]

        if ($@) {
            return $req->return_xxx( [ 400, q[Unsupported WebSocket protocol] ] );
        }

        # create empty websocket object
        my $ws = bless {}, "Pcore::WebSocket::Protocol::$implementation";

        my $accept = sub ( $cfg, @ ) {
            my %args = (
                headers        => undef,                                   # Maybe[ArrayRef]
                before_connect => undef,                                   # Maybe[HashRef]
                on_connect     => undef,                                   # Maybe[CodeRef]
                @_[ 1 .. $#_ ],
            );

            $ws->@{ keys $cfg->%* } = values $cfg->%*;

            my $compression = 0;

            # check and set extensions
            if ( $env->{HTTP_SEC_WEBSOCKET_EXTENSIONS} ) {

                # set permessage_deflate, only if enabled locally
                $compression = 1 if $ws->compression && $env->{HTTP_SEC_WEBSOCKET_EXTENSIONS} =~ /\bpermessage-deflate\b/smi;
            }

            # create response headers
            my @headers = (    #
                'Sec-WebSocket-Accept' => $ws->get_challenge( $env->{HTTP_SEC_WEBSOCKET_KEY} ),
                ( $protocol    ? ( 'Sec-WebSocket-Protocol'   => $protocol )            : () ),
                ( $compression ? ( 'Sec-WebSocket-Extensions' => 'permessage-deflate' ) : () ),
            );

            # add user headers
            push @headers, $args{headers}->@* if $args{headers};

            # add protocol headers
            if ( my $protocol_headers = $ws->before_connect_server( $env, $args{before_connect} ) ) {
                push @headers, $protocol_headers->@*;
            }

            # accept websocket connection
            $ws->{h} = $req->accept_websocket( \@headers );

            # store ws handle
            $HANDLE->{ refaddr $ws} = $ws;

            # call protocol on_connected
            $ws->on_connect;

            $ws->on_connect_server;

            # call on_connect callback, if defined
            $args{on_connect}->($ws) if $args{on_connect};

            return;
        };

        my $reject = sub ( $status = 400, $headers = undef ) {
            $req->( $status, $headers )->finish;

            return;
        };

        $on_accept->( $ws, $req, $accept, $reject );

        return;
    }

    # this is NOT websocket connect request
    else {
        $req->return_xxx( [ 400, q[Not a WebSocket connect request] ] );
    }

    return;
}

sub connect_ws ( $self, $protocol, $uri, @ ) {
    my %args = (
        connect_timeout => 30,
        tls_ctx         => $TLS_CTX_HIGH,
        bind_ip         => undef,

        max_message_size => 0,
        compression      => 0,        # use permessage_deflate compression
        headers          => undef,    # Maybe[ArrayRef]
        before_connect   => undef,    # Maybe[HashRef]
        on_error         => undef,
        on_connect       => undef,    # mandatory
        on_disconnect    => undef,    # passed to websocket constructor
        @_[ 3 .. $#_ ],
    );

    # load protocol implementation
    my $implementation = $protocol || 'raw';

    eval { require "Pcore/WebSocket/Protocol/$implementation.pm" };    ## no critic qw[Modules::RequireBarewordIncludes]

    my $class = "Pcore::WebSocket::Protocol::$implementation";

    my $on_error = sub ( $status ) {
        if ( $args{on_error} ) {
            $args{on_error}->($status);
        }
        else {
            die qq[WebSocket connect error: $status];
        }

        return;
    };

    if ($@) {
        $on_error->( result [ 400, 'WebSocket protocol is not supported' ] );

        return;
    }

    my $connect;

    if ( $uri =~ m[\Awss?://unix:(.+)?/]sm ) {
        $connect = [ 'unix/', $1 ];

        $uri = Pcore->uri($uri) if !ref $uri;
    }
    elsif ( $uri =~ m[\A(wss?)://[*]:(.+)]sm ) {
        $uri = P->uri("$1://127.0.0.1:$2");

        $connect = $uri;
    }
    else {
        $uri = Pcore->uri($uri) if !ref $uri;

        $connect = $uri;
    }

    Pcore::AE::Handle2->new(
        $args{handle_params}->%*,
        persistent       => 0,
        connect          => $connect,
        connect_timeout  => $args{connect_timeout},
        tls_ctx          => $args{tls_ctx},
        bind_ip          => $args{bind_ip},
        on_connect_error => sub ( $h, $reason ) {
            $on_error->( result [ 595, $reason ] );

            return;
        },
        on_error => sub ( $h, $fatal, $reason ) {
            $on_error->( result [ 596, $reason ] );

            return;
        },
        on_connect => sub ( $h, $host, $port, $retry ) {

            # start TLS, only if TLS is required and TLS is not established yet
            $h->starttls('connect') if $uri->is_secure && !exists $h->{tls};

            # generate websocket key
            my $sec_websocket_key = to_b64 rand 100_000, q[];

            my $request_path = $uri->path->to_uri . ( $uri->query ? q[?] . $uri->query : q[] );

            my @headers = (    #
                "GET $request_path HTTP/1.1",
                'Host:' . $uri->host,
                "User-Agent:Pcore-HTTP/$Pcore::VERSION",
                'Upgrade:websocket',
                'Connection:upgrade',
                "Sec-WebSocket-Version:$Pcore::WebSocket::Handle::WEBSOCKET_VERSION",
                "Sec-WebSocket-Key:$sec_websocket_key",
                ( $protocol          ? "Sec-WebSocket-Protocol:$protocol"            : () ),
                ( $args{compression} ? 'Sec-WebSocket-Extensions:permessage-deflate' : () ),
            );

            # add user headers
            push @headers, map {"$_->[0]:$_->[1]"} pairs $args{headers}->@* if $args{headers};

            my $ws = bless {
                max_message_size => $args{max_message_size},
                on_disconnect    => $args{on_disconnect},
                _send_masked     => 1,                         # client always send masked frames
            }, $class;

            # add protocol headers
            if ( $args{before_connect} ) {
                if ( my $protocol_headers = $ws->before_connect_client( $args{before_connect} ) ) {
                    push @headers, $protocol_headers->@*;
                }
            }

            $h->push_write( join( $CRLF, @headers ) . $CRLF . $CRLF );

            $h->read_http_res_headers(
                headers => 1,
                sub ( $h1, $headers, $error_reason ) {
                    my $res;

                    my $res_headers;

                    if ($error_reason) {

                        # headers parsing error
                        $res = result [ 596, $error_reason ];
                    }
                    else {
                        $res_headers = $headers->{headers};

                        # check response status
                        if ( $headers->{status} != 101 ) {
                            $res = result [ $headers->{status}, $headers->{reason} ];
                        }

                        # check response connection headers
                        elsif ( !$res_headers->{CONNECTION} || !$res_headers->{UPGRADE} || $res_headers->{CONNECTION} !~ /\bupgrade\b/smi || $res_headers->{UPGRADE} !~ /\bwebsocket\b/smi ) {
                            $res = result [ 596, q[WebSocket handshake error] ];
                        }

                        # check SEC_WEBSOCKET_ACCEPT
                        elsif ( !$res_headers->{SEC_WEBSOCKET_ACCEPT} || $res_headers->{SEC_WEBSOCKET_ACCEPT} ne Pcore::WebSocket::Handle->get_challenge($sec_websocket_key) ) {
                            $res = result [ 596, q[Invalid SEC_WEBSOCKET_ACCEPT header] ];
                        }

                        # check protocol
                        else {
                            if ( $res_headers->{SEC_WEBSOCKET_PROTOCOL} ) {
                                if ( !$protocol || $res_headers->{SEC_WEBSOCKET_PROTOCOL} !~ /\b$protocol\b/smi ) {
                                    $res = result [ 596, qq[WebSocket server returned unsupported protocol "$res_headers->{SEC_WEBSOCKET_PROTOCOL}"] ];
                                }
                            }
                            elsif ($protocol) {
                                $res = result [ 596, q[WebSocket server returned no protocol] ];
                            }
                        }
                    }

                    if ( defined $res ) {
                        $on_error->($res);
                    }
                    else {
                        my $compression = 0;

                        # check and set extensions
                        if ( $res_headers->{SEC_WEBSOCKET_EXTENSIONS} ) {
                            $compression = 1 if $args{compression} && $res_headers->{SEC_WEBSOCKET_EXTENSIONS} =~ /\bpermessage-deflate\b/smi;
                        }

                        $ws->@{qw[h compression]} = ( $h, $compression );

                        # call protocol on_connect
                        $ws->on_connect;

                        $ws->on_connect_client($res_headers);

                        delete( $args{on_connect} )->( $ws, $res_headers );
                    }

                    return;
                }
            );

            return;
        },
    );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 37, 135              | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 116                  | Subroutines::ProhibitExcessComplexity - Subroutine "connect_ws" with high complexity score (37)                |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebSocket

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
