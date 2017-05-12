package MyTesting;

sub import {
    my $caller = caller();

    ## no critic ProhibitStringyEval
    eval <<"MAGIC" or die "Couldn't set up testing policy: $@";
package $caller;
use Test::Most '-Test::Deep','-Test::Exception';
use Test::Deep '!blessed';
use Test::Fatal;
use Data::Printer;
1;
MAGIC
    return 1;
}

1;
