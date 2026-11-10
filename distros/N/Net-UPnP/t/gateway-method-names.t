use strict;
use warnings;
use Test::More;

use Net::UPnP::GW::Gateway;

# RT #123509: the correctly spelled method exists and the historical
# misspelling remains available as an alias.
can_ok('Net::UPnP::GW::Gateway', 'gettotalbytesreceived');
can_ok('Net::UPnP::GW::Gateway', 'gettotalbytesrecieved');
is(
    Net::UPnP::GW::Gateway->can('gettotalbytesrecieved'),
    Net::UPnP::GW::Gateway->can('gettotalbytesreceived'),
    'old name is an alias of the new name',
);

done_testing;
