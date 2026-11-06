package Demo::Logger;
use strict;
use warnings;
use Demo::Config;

sub info {
    my ($message) = @_;
    return "INFO: $message";
}
1;
