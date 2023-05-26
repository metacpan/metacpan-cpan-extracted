use strict;
use warnings;
use Test::More tests => 2;
use Net::Google::Analytics::MeasurementProtocol;

srand(42);
is(
    Net::Google::Analytics::MeasurementProtocol::_gen_uuid_v4(),
    'bb5799be-1e6c-401c-bfdb-c314937ab17f',
    'random uuid (client_id) generated from seed 42'
);

is(
    Net::Google::Analytics::MeasurementProtocol::_gen_uuid_v4(),
    'a7d5d9b0-e093-4076-a006-b288e49912c5',
    'second random uuid (client_id) generated ok'
);
