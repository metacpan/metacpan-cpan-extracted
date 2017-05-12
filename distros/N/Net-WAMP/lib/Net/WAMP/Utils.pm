package Net::WAMP::Utils;

use strict;
use warnings;

use constant ARCH_BITS => length(pack 'l!', 0) << 3;

sub generate_global_id {
    #Between 0 and 2^53 (9_007_199_254_740_992), inclusive.
    #It must serialize as a number, which means we need Perl to represent
    #this value internally with an IV, not a PV. This means we have to use
    #Perl-native integers, which means 32-bit systems can’t use the full
    #range of number values that WAMP envisions. All that should mean is that
    #we can only generate up to 32-bit global IDs, though; otherwise (e.g.,
    #for receiving from a 64-bit peer) there shouldn’t be a problem.

    if (ARCH_BITS < 64) {
        return int rand 2**32;
    }

    return int rand 9_007_199_254_740_993;
}

1;
