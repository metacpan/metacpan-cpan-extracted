use strict;
use warnings;

use Test::Most;

use MooseX::Params;

sub test :Args(Int first) { $_{first} }

is (test(42), 42, 'function call');
dies_ok { test([42]) } 'validation';

done_testing;
