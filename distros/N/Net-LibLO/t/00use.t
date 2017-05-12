
use strict;
use Test;


# use a BEGIN block so we print our plan before loading modules
BEGIN { plan tests => 4 }


# Check Net::LibLO loads ok
use Net::LibLO;
ok(1);

# Check Net::LibLO::Address loads ok
use Net::LibLO::Address;
ok(1);

# Check Net::LibLO::Bundle loads ok
use Net::LibLO::Bundle;
ok(1);

# Check Net::LibLO::Message loads ok
use Net::LibLO::Message;
ok(1);


exit;
