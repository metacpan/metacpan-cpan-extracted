use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use TestUtil::Socket;

# Port
my $port = TestUtil::Socket::search_available_port();

warn "[Test Output]Port:$port";

ok($port >= 20000);

done_testing;
