use strict;
use Test;

BEGIN { plan tests => 3 };

ok(eval { require Net::ICQ; });

use Net::ICQ;
ok(1);

# this doesn't actually talk to the server, so we just
# need a host that will always be available.
my $icq = Net::ICQ->new('1234', '1234', '127.0.0.1');
ok($icq);

