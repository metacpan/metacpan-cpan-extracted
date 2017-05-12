use strict;
use Test::More 0.98;

use Queue::Gearman::Message qw/parse_args/;

is_deeply [parse_args("")],           [],               'no args';
is_deeply [parse_args("arg1")],       ["arg1"],         'single args';
is_deeply [parse_args("arg1\0arg2")], ["arg1", "arg2"], 'multiple args';

done_testing;
