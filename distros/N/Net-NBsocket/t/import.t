# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

use Net::NBsocket qw(
        open_UDP
        open_udpNB
        open_Listen
        open_listenNB
        connectBlk
        connect_NB
        accept_Blk
        accept_NB
        set_NB
        set_so_linger
        dyn_bind
        inet_aton
        inet_ntoa
        sockaddr_in
        sockaddr_un
        inet_pton  
        inet_ntop
        ipv6_aton
        ipv6_n2x
        ipv6_n2d
        INADDR_ANY
        INADDR_BROADCAST
        INADDR_LOOPBACK
        INADDR_NONE
        in6addr_any
        in6addr_loopback
        AF_INET
        AF_INET6
        havesock6
        isupport6
        pack_sockaddr_in6
        unpack_sockaddr_in6
);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

