#!/usr/bin/perl
#
# This file is part of Redis
#
# This software is Copyright (c) 2015 by Pedro Melo, Damien Krotkine.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#

use strict;
use warnings;

if (my $pid = fork()) {
    #parent
    print "starting server-generator\n";
    system('./server-generator.pl');
    kill 'KILL', $pid;
} else {
    #child
    sleep(1);

    $| = 1;
    my $total_bytes = 5_000_000;
    my @lengths = (1, 2, 3, 4, 10, 50, 100, 1_000, 10_000);

    foreach my $length (@lengths) {
        my $cnt = int($total_bytes / $length);
        printf "--- # of lines: %d --- len of line: %d bytes ---\n", $cnt, $length;

        my $rl_res = `./client-readline.pl $cnt $length`;
        chomp $rl_res;
        print "readline: $rl_res sec\n";

        my $sr_res = `./client-sysread.pl $cnt $length`;
        chomp $sr_res;
        print "sysread: $sr_res sec\n";

        my $rc_res = `./client-recv.pl $cnt $length`;
        chomp $rc_res;
        print "recv: $rc_res sec\n";
    }

    print "hit ctrl+c to stop the server\n";
}
