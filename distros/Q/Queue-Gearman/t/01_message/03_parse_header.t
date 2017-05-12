use strict;
use Test::More 0.98;

use Queue::Gearman::Message qw/parse_header/;

is_deeply [parse_header("\0REQ".pack("NN", 1, 0))], ['REQ', 'CAN_DO', 0], 'request';
is_deeply [parse_header("\0RES".pack("NN", 6, 4))], ['RES', 'NOOP',   4], 'response';

done_testing;
