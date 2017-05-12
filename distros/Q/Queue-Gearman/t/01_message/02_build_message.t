use strict;
use Test::More 0.98;

use Queue::Gearman::Message qw/build_message :headers/;

is build_message(HEADER_REQ_CAN_DO),                 "\0REQ".pack("NN", 1, 0),              'no args';
is build_message(HEADER_REQ_CAN_DO, "arg1"),         "\0REQ".pack("NN", 1, 4)."arg1",       'single args';
is build_message(HEADER_REQ_CAN_DO, "arg1", "arg2"), "\0REQ".pack("NN", 1, 9)."arg1\0arg2", 'multiple args';

done_testing;
