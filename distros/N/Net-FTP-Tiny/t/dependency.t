use warnings;
use strict;

use Test::More tests => 2;

eval q{ use IO::Socket::INET 1.24 (); }; is $@, "";
eval q{ use Socket 1.72 (); }; is $@, "";

1;
