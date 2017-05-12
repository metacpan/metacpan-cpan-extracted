use strict;
use warnings;
use Test::More tests => 2;

BEGIN { require_ok('ServiceNow::SOAP'); }

my $sn = ServiceNow::SOAP::Session->new('instance','username','password');
isa_ok ($sn, 'ServiceNow::SOAP::Session');

1;
