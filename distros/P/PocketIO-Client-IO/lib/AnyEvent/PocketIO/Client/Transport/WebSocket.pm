package AnyEvent::PocketIO::Client::Transport::WebSocket;

use strict;
use warnings;
use Carp ();
use AnyEvent;
use AnyEvent::Handle;
use Protocol::WebSocket::Frame;
use Protocol::WebSocket::Handshake::Client;

use base 'AnyEvent::PocketIO::Client';

our $VERSION = '0.01';

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub id { 'websocket'; }


sub open {
    my ( $self, $client, $fh, $host, $port, $sid, $cb ) = @_;

    my $hs = Protocol::WebSocket::Handshake::Client->new(url =>
                  "ws://$host:$port/socket.io/1/websocket/$sid");
    my $frame  = Protocol::WebSocket::Frame->new( version => $hs->version );

    $client->handle->write( $hs->to_string => sub {
        my ( $handle ) = shift;
        my $conn = $client->conn;

        my $close_cb = sub { $handle->close; };

        $handle->on_eof( $close_cb );
        $handle->on_error( $close_cb );

        $handle->on_heartbeat( sub {
            $conn->send_heartbeat;
            $client->on('heartbeat')->();
        } );

        $handle->on_read( sub {
            unless ( $client->is_opened ) {
                $client->opened;
                $client->_run_open_cb( $cb ) if $cb;
            }

            unless ($hs->is_done) {
                $hs->parse( $_[1] ); 
                return;
            }
            $frame->append( $_[1] );

            while ( my $message = $frame->next_bytes ) {
                $conn->parse_message( $message );
            }
        } );

        $conn->on(
            close => sub {
                $handle->close;
                $client->on('close')->();
            }
        );

        $conn->on(
            write => sub {
                my $bytes = $self->_build_frame(
                    buffer => $_[1], version => $hs->version,
                );
                $handle->write( $bytes );
            },
        );

        $conn->socket->on('message' => sub {
            $client->on('message')->( $conn->socket, $_[1] );
        });

    });

}

sub _build_frame {
    my $self = shift;
    return Protocol::WebSocket::Frame->new( @_ )->to_bytes;
}

1;

