use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

# Test of polling via NN_SNDFD/NN_RCVFD mechanism.

sub getevents {
    my ($s, $events, $timeout) = @_;

    my ($rin, $win, $ein) = (('') x 3);
    my ($rcvfd, $sndfd);

    if ($events->{in}) {
        $rcvfd = unpack 'I', nn_getsockopt($s, NN_SOL_SOCKET, NN_RCVFD);
        ok defined $rcvfd;
        vec($rin, $rcvfd, 1) = 1;
    }

    if ($events->{out}) {
        $sndfd = unpack 'I', nn_getsockopt($s, NN_SOL_SOCKET, NN_SNDFD);
        ok defined $sndfd;
        vec($win, $sndfd, 1) = 1;
    }

    my $fds = select $rin, $win, undef, $timeout;
    cmp_ok $fds, '>=', 0;

    +{
        ($events->{in} && vec($rin, $rcvfd, 1)
             ? (in => 1) : ()),
        ($events->{out} && vec($win, $sndfd, 1)
             ? (out => 1) : ()),
    };
}

my $socket_address = 'inproc://a';

my $sb = nn_socket AF_SP, NN_PAIR;
cmp_ok $sb, '>=', 0;
cmp_ok nn_bind($sb, $socket_address), '>=', 0;

my $sc = nn_socket AF_SP, NN_PAIR;
cmp_ok $sc, '>=', 0;
cmp_ok nn_connect($sc, $socket_address), '>=', 0;

# Check the initial state of the socket.
my $events = getevents($sb, { in => 1, out => 1 }, 1);
ok $events->{out};
ok !$events->{in};

# Poll for IN when there's no message available. The call should time out.
$events = getevents($sb, { in => 1 }, .001);
ok !$events->{in};

# Send a message and start polling. This time IN event should be signaled.
is nn_send($sc, 'ABC', 0), 3;
$events = getevents($sb, { in => 1 }, 1);
ok $events->{in};

# Receive the message and make sure that IN is no longer signaled.
is nn_recv($sb, my $buf, 3, 0), 3;
$events = getevents($sb, { in => 1 }, .001);
ok !$events->{in};

ok nn_close($_) for $sc, $sb;

done_testing;
