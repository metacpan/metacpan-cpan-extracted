use strict;
use warnings;
use Test::More;
use Net::APNs::Extended qw(:constants);

is NO_ERRORS, 0;
is PROCESSING_ERROR, 1;
is MISSING_DEVICE_TOKEN, 2;
is MISSING_TOPIC, 3;
is MISSING_PAYLOAD, 4;
is INVALID_TOKEN_SIZE, 5;
is INVALID_TOPIC_SIZE, 6;
is INVALID_PAYLOAD_SIZE, 7;
is INVALID_TOKEN, 8;
is SHUTDOWN, 10;
is UNKNOWN_ERROR, 255;

done_testing;
