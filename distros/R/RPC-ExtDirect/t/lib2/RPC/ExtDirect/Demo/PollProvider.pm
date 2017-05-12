package RPC::ExtDirect::Demo::PollProvider;

use strict;
use warnings;
no  warnings 'uninitialized';

use POSIX 'strftime';

use RPC::ExtDirect;
use RPC::ExtDirect::Event;

sub poll : ExtDirect(pollHandler) {
    my $time = strftime "Successfully polled at: %a %b %e %H:%M:%S %Y",
                        localtime;

    return RPC::ExtDirect::Event->new('message', $time);
}

1;
