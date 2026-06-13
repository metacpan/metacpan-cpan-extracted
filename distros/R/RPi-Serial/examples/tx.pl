use warnings;
use strict;

use RPi::Serial;

my $s = RPi::Serial->new('/dev/ttyS0', 9600);

for (qw(x [[[hello]]] ! [[[world]]] a b)){
    # x     = no start marker seen yet, reset
    # [[[   = start data ok
    # hello = data
    # ]]]   = end data ok
    # !     = RX reset command
    # [[[   = start data ok
    # world = data
    # ]]]   = end data ok
    # a     = no start marker set, reset
    # b     = no start marker set, reset

    #
    # output at RX side should be:
    # "hello"
    # "world"
    #

    $s->puts($_);
}

