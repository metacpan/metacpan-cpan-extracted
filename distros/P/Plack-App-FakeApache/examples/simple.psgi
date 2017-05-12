#
# A simple PSGI application
#
# This is mainly here to use with the wrapwrap.psgi example

use strict;
use warnings;

my $app = sub {
    my $env = shift;

    return [ 200, [], ["Hello World\n"] ];
};
