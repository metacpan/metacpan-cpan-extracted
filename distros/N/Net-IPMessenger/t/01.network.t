use Test::More;
use lib '../lib';
use Net::IPMessenger;

{
    my $test = generate_sockets();
    {
        my $ipmsg1 = $test->{ipmsg1}->{ipmsg};
        my $ipmsg2 = $test->{ipmsg2}->{ipmsg};
        if ( not $ipmsg1 or not $ipmsg2 ) {
            plan skip_all => 'skip network test. failed to bind local server';
        }
    }

    run_tests($test);
}
done_testing;

sub run_tests {
    my $test   = shift;
    my $ipmsg1 = $test->{ipmsg1}->{ipmsg};
    my $ipmsg2 = $test->{ipmsg2}->{ipmsg};
    ok $ipmsg1, 'check if ipmsg1 is defined';
    ok $ipmsg2, 'check if ipmsg2 is defined';

    # send entry packet
    my $command = $ipmsg1->messagecommand('BR_ENTRY')->set_broadcast;
    ok $ipmsg1->send(
        {
            command  => $command,
            option   => $ipmsg1->my_info,
            peeraddr => '127.0.0.1',
            peerport => $test->{ipmsg2}->{port},
        }
        ),
        'ipmsg1 send BR_ENTRY packet to ipmsg2';
    # recv entry packet and reply answer
    my $recv = $ipmsg2->recv;
    ok $recv, 'ipmsg2 recv packet from ipmsg1';
    $command = $ipmsg2->messagecommand( $recv->command );
    is 'BR_ENTRY', $command->modename,
        'packet is BR_ENTRY';
    ok $command->get_broadcast, 'BR_ENTRY is a broadcast packet';
    # recv answer of entry
    $recv = $ipmsg1->recv;
    ok $recv, 'ipmsg1 recv packet from ipmsg2';
    $command = $ipmsg2->messagecommand( $recv->command );
    is 'ANSENTRY', $command->modename,
        'packet is ANSENTRY';
    # send message
    $command = $ipmsg1->messagecommand('SENDMSG')->set_sendcheck;
    ok $ipmsg1->send(
        {
            command  => $command,
            option   => 'test',
            peeraddr => '127.0.0.1',
            peerport => $test->{ipmsg2}->{port},
        }
        ),
        'ipmsg1 send SENDMSG packet to ipmsg2';
    # recv message packet and reply sealed
    $recv = $ipmsg2->recv;
    ok $recv, 'ipmsg2 recv packet from ipmsg1';
    is 'test', $recv->get_message, 'check if message is what ipmsg1 sent';
    # recv sealed
    $recv = $ipmsg1->recv;
    ok $recv, 'ipmsg1 recv packet from ipmsg2';
    $command = $ipmsg2->messagecommand( $recv->command );
    is 'RECVMSG', $command->modename,
        'packet is RECVMSG';
}

sub generate_sockets {
    my( $ipmsg1, $ipmsg2, $port1, $port2 );

    #return;
    use Sys::Hostname;
    my $host = hostname;
    for my $port ( 2425 .. 2500 ) {
        $ipmsg1 = Net::IPMessenger->new(
            Port     => $port,
            NickName => 'ipmsg1',
            UserName => 'ipmsg1',
            HostName => $host,
        );
        if ($ipmsg1) {
            $port1 = $port;
            last;
        }
    }

    for my $port ( $port1 .. $port1 + 50 ) {
        $ipmsg2 = Net::IPMessenger->new(
            Port     => $port,
            NickName => 'ipmsg2',
            UserName => 'ipmsg2',
            HostName => $host,
        );
        if ($ipmsg2) {
            $port2 = $port;
            last;
        }
    }
    my $test = {
        ipmsg1 => {
            ipmsg => $ipmsg1,
            port  => $port1,
        },
        ipmsg2 => {
            ipmsg => $ipmsg2,
            port  => $port2,
        },
    };
    return $test;
}
