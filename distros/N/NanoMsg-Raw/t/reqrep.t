use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

my $socket_address = 'inproc://test';

{
    my $rep1 = nn_socket(AF_SP, NN_REP);
    ok defined $rep1;
    ok defined nn_bind($rep1, $socket_address);

    my $req1 = nn_socket(AF_SP, NN_REQ);
    ok defined $req1;
    ok defined nn_connect($req1, $socket_address);

    my $req2 = nn_socket(AF_SP, NN_REQ);
    ok defined $req2;
    ok defined nn_connect($req2, $socket_address);

    is nn_send($rep1, 'ABC', 0), undef;
    ok nn_errno == EFSM;
    is nn_recv($req1, my $buf, 7, 0), undef;
    ok nn_errno == EFSM;

    is nn_send($req2, 'ABC', 0), 3;
    is nn_recv($rep1, $buf, 3, 0), 3;
    is nn_send($rep1, $buf, 0), 3;
    is nn_recv($req2, $buf, 3, 0), 3;

    is nn_send($req1, 'ABC', 0), 3;
    is nn_recv($rep1, $buf, 3, 0), 3;
    is nn_send($rep1, $buf, 0), 3;
    is nn_recv($req1, $buf, 3, 0), 3;

    ok nn_close $_ for $rep1, $req1, $req2;
}

{
    my $req1 = nn_socket(AF_SP, NN_REQ);
    ok defined $req1;
    ok defined nn_bind($req1, $socket_address);

    my $rep1 = nn_socket(AF_SP, NN_REP);
    ok defined $rep1;
    ok defined nn_connect($rep1, $socket_address);

    my $rep2 = nn_socket(AF_SP, NN_REP);
    ok defined $rep2;
    ok defined nn_connect($rep2, $socket_address);

    is nn_send($req1, 'ABC', 0), 3;
    is nn_recv($rep1, my $buf, 3, 0), 3;
    is nn_send($rep1, $buf, 0), 3;
    is nn_recv($req1, $buf, 3, 0), 3;

    is nn_send($req1, 'ABC', 0), 3;
    is nn_recv($rep2, $buf, 3, 0), 3;
    is nn_send($rep2, $buf, 0), 3;
    is nn_recv($req1, $buf, 3, 0), 3;

    ok nn_close $_ for $rep2, $rep1, $req1;
}

{
    my $rep1 = nn_socket(AF_SP, NN_REP);
    ok defined $rep1;
    ok defined nn_bind($rep1, $socket_address);

    my $req1 = nn_socket(AF_SP, NN_REQ);
    ok defined $req1;
    ok defined nn_connect($req1, $socket_address);

    ok nn_setsockopt($req1, NN_REQ, NN_REQ_RESEND_IVL, 100);

    is nn_send($req1, 'ABC', 0), 3;
    is nn_recv($rep1, my $buf, 3, 0), 3;
    is nn_recv($rep1, $buf, 3, 0), 3;

    ok nn_close $_ for $req1, $rep1;
}

{
    my $req1 = nn_socket(AF_SP, NN_REQ);
    ok defined $req1;
    ok defined nn_connect($req1, $socket_address);

    is nn_send($req1, 'ABC', 0), 3;

    my $rep1 = nn_socket(AF_SP, NN_REP);
    ok defined $rep1;
    ok defined nn_bind($rep1, $socket_address);

    ok nn_setsockopt($rep1, NN_SOL_SOCKET, NN_RCVTIMEO, 100);

    is nn_recv($rep1, my $buf, 3, 0), 3;

    ok nn_close $_ for $req1, $rep1;
}

done_testing;
