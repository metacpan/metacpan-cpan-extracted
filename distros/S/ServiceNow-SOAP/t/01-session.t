use strict;
use warnings;
use ServiceNow::SOAP;
use Test::More tests => 1;

my $sn = ServiceNow("instance", "username", "password");
isa_ok ($sn, "ServiceNow::SOAP::Session");

1;
