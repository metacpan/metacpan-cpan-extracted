use strict;
use Test;

BEGIN { plan tests => 3 };

ok(eval { require Net::IRC; });

use Net::IRC;
ok(1);

my $irc = Net::IRC->new;
ok($irc);
