use strict;
use Test::More 0.98;

use Queue::Gearman::Message qw/build_header/;

is build_header(REQ => 'CAN_DO'), "\0REQ".pack("N", 1), "req pack";
is build_header(RES => 'NOOP'),   "\0RES".pack("N", 6), "res pack";

done_testing;
