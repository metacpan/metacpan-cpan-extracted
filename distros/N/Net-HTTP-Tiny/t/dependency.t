use warnings;
use strict;

use Test::More tests => 1;

eval q{ use IO::Socket::INET 1.24 (); }; is $@, "";

1;
