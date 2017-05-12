package Shuvgey::Server;
use strict;
use warnings;
use Net::SSLeay;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::TLS;
use Protocol::HTTP2;
use Protocol::HTTP2::Constants qw(const_name :settings);
use Protocol::HTTP2::Server;
use Data::Dumper;
use URI::Escape qw(uri_unescape);
use Carp;
use Sys::Hostname;
use Scalar::Util qw(blessed);
require Shuvgey;

use constant {
    TRUE  => !undef,
    FALSE => !!undef,

    STOP => exists $ENV{SHUVGEY_DEBUG},

    # Old h2 tls ident for compatibility
    H2_14 => "h2-14",

    # Log levels
    DEBUG     => 0,
    INFO      => 1,
    NOTICE    => 2,
    WARNING   => 3,
    ERROR     => 4,
    CRITICAL  => 5,
    ALERT     => 6,
    EMERGENCY => 7,
};

my $start_time = 0;
my $hostname   = hostname;

sub talk($$) {
    if ( shift() >= $ENV{SHUVGEY_DEBUG} ) {
        my $message = shift;
        chomp($message);
        my $now = AnyEvent->now;
        if ( $now - $start_time < 60 ) {
            $message =~ s/\n/\n           /g;
            printf "[%05.3f] %s\n", $now - $start_time, $message;
        }
        else {
            my @t = ( localtime() )[ 5, 4, 3, 2, 1, 0 ];
            $t[0] += 1900;
            $t[1]++;
            $message =~ s/\n/\n                      /g;
            printf "[%4d-%02d-%02d %02d:%02d:%02d] %s\n", @t, $message;
            $start_time = $now;
        }
    }
}

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub run {
    my ( $self, $app ) = @_;

    STOP and talk DEBUG, Dumper($self);

    my ( $host, $port );
    if ( $self->{listen} ) {
        ( $self->{host}, $self->{port} ) = split /:/,
          shift @{ $self->{listen} };
    }

    $host = $self->{host} || undef;
    $port = $self->{port} || undef;

    if ( !exists $self->{no_tls} ) {
        STOP and talk INFO, "tls\n";
        if ( exists $self->{upgrade} ) {
            $self->{no_tls} = TRUE;
        }
        elsif (!exists $self->{tls_crt}
            || !-r $self->{tls_crt}
            || !exists $self->{tls_key}
            || !-r $self->{tls_key} )
        {
            croak "Can't read tls_crt or tls_key files\n"
              . "Use --no_tls option to start Shuvgey without tls";
        }
    }

    $self->{exit} = AnyEvent->condvar;

    $self->run_tcp_server( $app, $host, $port );

    my $w;
    $w = AnyEvent->signal(
        signal => "TERM",
        cb     => sub {
            undef $w;
            $self->finish("Received SIGTERM");
        }
    );

    my $recv = $self->{exit}->recv;
    STOP and talk INFO, $recv;
}

sub run_tcp_server {
    my ( $self, $app, $host, $port ) = @_;

    tcp_server $host, $port, sub {

        my ( $fh, $peer_host, $peer_port ) = @_;
        my $tls;

        STOP and talk INFO, "Accept connection from $peer_host:$peer_port";

        if ( !exists $self->{no_tls} ) {
            $tls = $self->create_tls or return;
        }

        my $handle;
        $handle = AnyEvent::Handle->new(
            fh       => $fh,
            autocork => 1,
            $tls
            ? (
                tls         => "accept",
                tls_ctx     => $tls,
                on_starttls => sub {
                    my ( $handle, $success, $error_message ) = @_;
                    if ( !$success ) {
                        STOP and talk ERROR, $error_message;
                    }
                    else {
                        my $proto =
                          Net::SSLeay::P_next_proto_negotiated( $handle->{tls} )
                          || '';
                        STOP
                          and talk INFO, "Client negotiated protocol: $proto";
                        if (   $proto ne Protocol::HTTP2::ident_tls
                            && $proto ne H2_14 )
                        {
                            STOP and talk ERROR, "$proto not supported";
                            $handle->push_write( $self->error_505 );
                            $handle->push_shutdown;
                        }
                        else {
                            STOP and talk INFO, "tls started ok";
                            STOP
                              and talk INFO, "cipher: "
                              . Net::SSLeay::get_cipher( $handle->{tls} );
                            $self->start_server( $handle, $app, $host, $port,
                                $peer_host, $peer_port );
                        }
                    }
                },
                on_stoptls => sub {
                    my ($handle) = @_;
                    STOP and talk INFO, "tls stoped: <$!>";
                },
              )
            : (),
            on_error => sub {
                $_[0]->destroy;
                STOP and talk ERROR, "connection error";
            },
            on_eof => sub {
                $handle->destroy;
            }
        );
        $self->start_server( $handle, $app, $host, $port, $peer_host,
            $peer_port )
          unless $tls;
      },

      # Bound to host:port
      sub {
        ( undef, $host, $port ) = @_;
        STOP and talk NOTICE, "Ready to serve request\n";

        # For Plack::Runner
        $self->{server_ready}->(
            {
                host            => $host,
                port            => $port,
                server_software => 'Shuvgey',
            }
        ) if $self->{server_ready};
        return TRUE;
      };

    return TRUE;
}

sub start_server {
    my ( $self, $handle, $app, $host, $port, $peer_host, $peer_port ) = @_;
    my $server;

    $server = Protocol::HTTP2::Server->new(
        exists $self->{upgrade} ? ( upgrade => 1 ) : (),
        settings        => { &SETTINGS_MAX_CONCURRENT_STREAMS => 100, },
        on_change_state => sub {
            my ( $stream_id, $previous_state, $current_state ) = @_;
        },
        on_error => sub {
            my $error = shift;
            STOP and talk
              ERROR,
              sprintf "Error occured: %s\n",
              const_name( "errors", $error );
        },
        on_request => sub {
            my ( $stream_id, $headers, $data ) = @_;

            my $env =
              $self->psgi_env( $host, $port, $peer_host, $peer_port,
                $headers, $data );

            my $response = eval { $app->($env) }
              || $self->internal_error($@);

            # TODO: support for CODE
            if ( ref $response ne 'ARRAY' ) {
                $response =
                  $self->internal_error("PSGI CODE response not supported yet");
            }

            my $body;

            if ( ref $response->[2] eq 'ARRAY' ) {
                $body = join '', @{ $response->[2] };
            }
            elsif (
                ref $response->[2] eq 'GLOB'
                or ( blessed( $response->[2] )
                    && $response->[2]->can('getline') )
              )
            {
                local $/ = \4096;
                $body = '';
                while ( defined( my $chunk = $response->[2]->getline ) ) {
                    $body .= $chunk;
                }
            }
            else {
                STOP and talk INFO, Dumper $response->[2];
                $response =
                  $self->internal_error( "body ref type "
                      . ( ref $response->[2] )
                      . " not supported yet" );
            }

            my @h = ();
            while ( @{ $response->[1] } ) {
                my ( $h, $v ) = splice @{ $response->[1] }, 0, 2;
                STOP and talk INFO, $h . " = " . $v;
                push @h, $h, $v unless lc($h) eq 'server';
            }
            push @h, "Server", "Shuvgey/" . $Shuvgey::VERSION;

            $server->response(
                stream_id => $stream_id,
                ':status' => $response->[0],
                headers   => \@h,
                data      => $body,
            );
        },
    );

    # First send settings to peer
    while ( my $frame = $server->next_frame ) {
        $handle->push_write($frame);
    }

    $handle->on_read(
        sub {
            my $handle = shift;

            $server->feed( $handle->{rbuf} );

            $handle->{rbuf} = undef;
            while ( my $frame = $server->next_frame ) {
                $handle->push_write($frame);
            }
            $handle->push_shutdown if $server->shutdown;
        }
    );
    ();
}

sub create_tls {
    my $self = shift;
    my $tls;

    eval {
        $tls = AnyEvent::TLS->new(
            method    => "TLSv1_2",
            cert_file => $self->{tls_crt},
            key_file  => $self->{tls_key},
        );

        # ECDH curve ( Net-SSLeay >= 1.56, openssl >= 1.0.0 )
        if ( exists &Net::SSLeay::CTX_set_tmp_ecdh ) {
            my $curve = Net::SSLeay::OBJ_txt2nid('prime256v1');
            my $ecdh  = Net::SSLeay::EC_KEY_new_by_curve_name($curve);
            Net::SSLeay::CTX_set_tmp_ecdh( $tls->ctx, $ecdh );
            Net::SSLeay::EC_KEY_free($ecdh);
        }

        # ALPN (Net-SSLeay > 1.55, openssl >= 1.0.2)
        if ( exists &Net::SSLeay::CTX_set_alpn_select_cb ) {
            Net::SSLeay::CTX_set_alpn_select_cb( $tls->ctx,
                [ Protocol::HTTP2::ident_tls, H2_14 ] );
        }

        # NPN  (Net-SSLeay > 1.45, openssl >= 1.0.1)
        elsif ( exists &Net::SSLeay::CTX_set_next_protos_advertised_cb ) {
            Net::SSLeay::CTX_set_next_protos_advertised_cb( $tls->ctx,
                [ Protocol::HTTP2::ident_tls, H2_14 ] );
        }
        else {
            die "ALPN and NPN are not supported\n";
        }
    };

    $self->finish("Some problem with TLS: $@\n") if $@;
    return $tls;
}

sub finish {
    shift->{exit}->send(shift);
}

sub psgi_env {
    my ( $self, $host, $port, $peer_host, $peer_port, $headers, $data ) = @_;

    my $input;
    open $input, '<', \$data if defined $data;

    my $env = {
        'psgi.version'      => [ 1, 1 ],
        'psgi.input'        => $input,
        'psgi.errors'       => *STDERR,
        'psgi.multithread'  => FALSE,
        'psgi.multiprocess' => FALSE,
        'psgi.run_once'     => FALSE,
        'psgi.nonblocking'  => TRUE,
        'psgi.streaming'    => FALSE,
        'SCRIPT_NAME'       => '',
        'SERVER_NAME' => $host eq '0.0.0.0' ? $hostname : $host,
        'SERVER_PORT' => $port,

        'SERVER_PROTOCOL' => "HTTP/2",

        # This not in PSGI spec. Why not?
        'REMOTE_HOST' => $peer_host,
        'REMOTE_ADDR' => $peer_host,
        'REMOTE_PORT' => $peer_port,
    };

    for my $i ( 0 .. @$headers / 2 - 1 ) {
        my ( $h, $v ) = ( $headers->[ $i * 2 ], $headers->[ $i * 2 + 1 ] );
        if ( $h eq ':method' ) {
            $env->{REQUEST_METHOD} = $v;
        }
        elsif ( $h eq ':scheme' ) {
            $env->{'psgi.url_scheme'} = $v;
        }
        elsif ( $h eq ':path' ) {
            $env->{REQUEST_URI} = $v;
            my ( $path, $query ) = ( $v =~ /^([^?]*)\??(.*)?$/s );
            $env->{QUERY_STRING} = $query || '';
            $env->{PATH_INFO} = uri_unescape($path);
        }
        elsif ( $h eq ':authority' ) {

            #TODO: what to do with :authority?
        }
        elsif ( $h eq 'content-length' ) {
            $env->{CONTENT_LENGTH} = $v;
        }
        elsif ( $h eq 'content-type' ) {
            $env->{CONTENT_TYPE} = $v;
        }
        else {
            my $header = 'HTTP_' . uc($h);
            if ( exists $env->{$header} ) {
                $env->{$header} .= ', ' . $v;
            }
            else {
                $env->{$header} = $v;
            }
        }
    }
    @$headers = ();
    STOP and talk INFO, Dumper($env);
    return $env;
}

sub internal_error {
    my ( $self, $error ) = @_;

    my $message = "500 - Internal Server Error";
    STOP and talk ERROR, "$message: $error\n";

    return [
        500,
        [
            'Content-Type'   => 'text/plain',
            'Content-Length' => length($message)
        ],
        [$message]
    ];
}

sub error_505 {
    my $error =
      sprintf "Shuvgey supports only HTTP/2 protocol (drafts %s or %s)",
      Protocol::HTTP2::ident_tls, H2_14;
    join "\x0d\x0a",
      "HTTP/1.1 505 HTTP version not supported",
      "Content-Type: text/plain",
      "Content-Length: " . length($error),
      "", $error;
}

1;
