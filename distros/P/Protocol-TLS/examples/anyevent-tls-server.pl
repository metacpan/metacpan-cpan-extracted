use strict;
use warnings;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Protocol::TLS::Server;

# openssl s_client -connect 127.0.0.1:4443 -cipher NULL-SHA -debug

my $cv = AE::cv;

my $server = Protocol::TLS::Server->new(
    version   => 'TLSv12',
    cert_file => 't/test.crt',
    key_file  => 't/test.key',
);

tcp_server undef, 4443, sub {
    my ( $fh, $host, $port ) = @_ or do {
        warn "Client error \n";
        $cv->send;
        return;
    };

    print "Connected $host:$port\n";

    my $con = $server->new_connection(
        on_handshake_finish => sub {
            my ($tls) = @_;
        },
        on_data => sub {
            my ( $tls, $data ) = @_;
            $tls->send($data);
            $tls->close;
        }
    );

    my $h;
    $h = AnyEvent::Handle->new(
        fh       => $fh,
        on_error => sub {
            $_[0]->destroy;
            warn "connection error\n";
            $cv->send;
        },
        on_eof => sub {
            $h->destroy;
            print "that's all folks\n";
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
$cv->recv;
