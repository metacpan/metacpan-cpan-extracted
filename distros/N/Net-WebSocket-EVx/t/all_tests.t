use strict;
use warnings;
use utf8;
use blib;
use IO::Socket::INET;
use Test::More tests => 3;
use Net::WebSocket::EVx;
use Net::EmptyPort 'empty_port';

BEGIN { use_ok('Net::WebSocket::EVx') };

my $server_sock = IO::Socket::INET->new(
    Listen => 5,
    LocalAddr => '127.0.0.1',
    LocalPort => my $port = empty_port,
    Proto => 'tcp',
    # Blocking => 0,
) or die 'Failed to bind server!';

my (@server, @client, $server, $connected_client_socket, $fragmented_rcv_state);

EV::once $server_sock, EV::READ, 10, sub {
    $connected_client_socket = $server_sock->accept();
    $connected_client_socket->blocking(0);
    $server = Net::WebSocket::EVx->new({
        fh => $connected_client_socket,
        on_frame_recv_start => sub {},
        on_frame_recv_chunk	=> sub {},
        on_frame_recv_end   => sub {},
        on_msg_recv         => sub {
            my ($rsv,$opcode,$msg, $status_code) = @_;
            if(($msg eq 'first test message test test Юникод') and $opcode == 1){
                pass("Send and receive text meassge");
                call_next_test();
            }
            if(($msg eq 'DataChunkDataChunk2') and $opcode == 2){
                pass("Fragmented binary message received");
                call_next_test();
            }
        },
        on_close => sub {},
    });
};

my $client_sock = IO::Socket::INET->new(
    PeerAddr => '127.0.0.1',
    PeerPort => $port,
    Proto => 'tcp',
    Blocking => 0,
) or die 'Failed to client connect!';

my $client = Net::WebSocket::EVx->new({
    type => 'client',
    fh => $client_sock,
    on_frame_recv_start => sub {},
    on_frame_recv_chunk	=> sub {},
    on_frame_recv_end   => sub {},
    on_msg_recv => sub { my ($rsv,$opcode,$msg, $status_code) = @_ },
    on_close => sub {},
    buffering => 0,
});

{   ;
    my $state = 0;
    my $starter;
    sub fragment_gen {
        if ($state == 0) { $state++; return 'DataChunk' }
        elsif ($state == 1) {
            $starter = EV::once undef, 0, 0.8 , sub {
                $state++;
                $client->start_write;
            };
            $client->stop_write;
            return '';
        } elsif ($state == 2) {
            return ('DataChunk2', WS_FRAGMENTED_EOF);
        }
    }
}

my @async_tests;
sub call_next_test { ( (shift @async_tests) or sub { exit 0 } )->() }

@async_tests = (
    sub { $client->queue_msg('first test message test test Юникод', 1) },
    sub { $client->queue_fragmented(\&fragment_gen, 2) },
);

call_next_test;

EV::run;
