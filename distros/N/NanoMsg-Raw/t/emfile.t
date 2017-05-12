use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

my @socks;
while (1) {
    my $s = nn_socket AF_SP, NN_PAIR;
    if (!defined $s) {
        ok nn_errno == EMFILE;
        # does not work with german/any locale other than C
        #like nn_errno, qr/^too many open files/i;
        #like nn_strerror(nn_errno), qr/^too many open files/i;
        last;
    }
    push @socks, $s;
}

ok nn_close $_ for @socks;

done_testing;
