use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TLSTest;
use Test::TCP;
use AnyEvent::Socket;
use AnyEvent::Handle;

BEGIN {
    use_ok 'Protocol::TLS::Client';
    use_ok 'Protocol::TLS::Server';
}

sub tls_srv {
    my (%h) = @_;

    my $cv = AE::cv;
    my $server = $h{server} || Protocol::TLS::Server->new(
        version   => 'TLSv12',
        cert_file => 't/test.crt',
        key_file  => 't/test.key',
    );

    tcp_server '127.0.0.1', $h{port}, sub {
        my ( $fh, $host, $port ) = @_ or do {
            $h{cb_error} ? $h{cb_error}->($!) : ();
            $cv->send;
            return;
        };

        my $con = $server->new_connection(
            $h{on_handshake_finish}
            ? ( on_handshake_finish => $h{on_handshake_finish} )
            : (),
            $h{on_data} ? ( on_data => $h{on_data} ) : (),
        );

        my $h;
        $h = AnyEvent::Handle->new(
            fh       => $fh,
            on_error => sub {
                $h{cb_error} ? $h{cb_error}->("Connection error") : ();
                $cv->send;
            },
            on_eof => sub {
                $h->destroy;
                $h{cb_ok} ? $h{cb_ok}->() : ();
            },
        );
        $h->on_read(
            sub {
                my $handle = shift;
                $con->feed( $handle->{rbuf} );
                $handle->{rbuf} = '';
                while ( my $record = $con->next_record ) {
                    $handle->push_write($record);
                }

                # Terminate connection if all done
                $handle->push_shutdown if $con->shutdown;
                ();
            }
        );
        ();
    };
    ok $cv->recv, "server exit status";
}

sub tls_clt {
    my (%h)    = @_;
    my $cv     = AE::cv;
    my $client = $h{client}
      || Protocol::TLS::Client->new( version => 'TLSv12' );

    tcp_connect '127.0.0.1', $h{port}, sub {
        my $fh = shift or do {
            $h{cb_error} ? $h{cb_error}->($!) : ();
            $cv->send;
            return;
        };
        my $h;
        $h = AnyEvent::Handle->new(
            fh       => $fh,
            on_error => sub {
                $_[0]->destroy;
                $h{cb_error} ? $h{cb_error}->("Connection error") : ();
                $cv->send;
            },
            on_eof => sub {
                $h->destroy;
                $h{cb_ok} ? $h{cb_ok}->() : ();
                $cv->send(1);
            },
        );

        my $con = $client->new_connection(
            $h{'hostname'} ? $h{hostname} : 'example.com',
            $h{on_handshake_finish}
            ? ( on_handshake_finish => $h{on_handshake_finish} )
            : (),
            $h{on_data} ? ( on_data => $h{on_data} ) : (),
        );

        while ( my $record = $con->next_record ) {
            $h->push_write($record);
        }

        $h->on_read(
            sub {
                my $handle = shift;
                $con->feed( $handle->{rbuf} );
                $handle->{rbuf} = '';
                while ( my $record = $con->next_record ) {
                    $handle->push_write($record);
                }

                # Terminate connection if all done
                $handle->push_shutdown if $con->shutdown;
                ();
            }
        );
        ();
    };
    ok $cv->recv, "client exit status";
}

subtest 'simple' => sub {
    test_tcp(
        client => sub {
            tls_clt(
                port                => shift,
                on_handshake_finish => sub {
                    my ($tls) = @_;
                    $tls->send("test data\n");
                },
                on_data => sub {
                    my ( $tls, $data ) = @_;
                    is $data, "test data\n", "check tls echo service";
                },
            );
        },
        server => sub {
            tls_srv(
                port    => shift,
                on_data => sub {
                    my ( $tls, $data ) = @_;
                    $tls->send($data);
                    $tls->close;
                },
            );
        }
    );
};

subtest 'session resuming' => sub {
    test_tcp(
        client => sub {
            my $port = shift;

            my $client = Protocol::TLS::Client->new( version => 'TLSv12' );
            my $sid = undef;

            for my $i ( 1 .. 2 ) {
                tls_clt(
                    client              => $client,
                    port                => $port,
                    on_handshake_finish => sub {
                        my ($tls) = @_;
                        if ( $i == 1 ) {
                            $sid = $tls->{session_id};
                            note "sid: " . bin2hex($sid) . "\n";
                        }
                        else {
                            is $tls->{session_id}, $sid, "session resumed";
                        }
                        $tls->send("test data\n");
                    },
                    on_data => sub {
                        my ( $tls, $data ) = @_;
                        is $data, "test data\n", "check tls echo service";
                        $tls->close;
                    },
                );
            }
        },
        server => sub {
            tls_srv(
                port    => shift,
                on_data => sub {
                    my ( $tls, $data ) = @_;
                    $tls->send($data);
                },
            );
        }
    );

};

done_testing;
