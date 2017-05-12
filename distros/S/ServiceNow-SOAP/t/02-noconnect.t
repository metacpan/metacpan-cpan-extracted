# test that connect() traps error and returns null if connection parameters are bad
use strict;
use warnings;
use Test::More tests => 2;
use ServiceNow::SOAP;
my $sn = ServiceNow("badcompany", "baduser", "badpassword")->connect();
note "connect returned: ", $@;
ok (!$sn, 'connect trapped bad connection parameters');
ok ($@, '$@ has an error message');

1;
