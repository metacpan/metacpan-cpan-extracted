use strict;
use warnings;
use Test::More tests => 2;
use Net::Google::Analytics::MeasurementProtocol;

srand(1);
is(
    Net::Google::Analytics::MeasurementProtocol::_gen_uuid_v4(),
    '5974a80a-0356-46d5-b300-c3908dfd0530',
    'random uuid (cid) generated from seed 1'
);

srand(42);
is(
    Net::Google::Analytics::MeasurementProtocol::_gen_uuid_v4(),
    'bb5799be-1e6c-401c-bfdb-c314937ab17f',
    'random uuid (cid) generated from seed 42'
);
