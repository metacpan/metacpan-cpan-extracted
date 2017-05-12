use strict;
use warnings;
use Config;
use Test::More;

plan skip_all => 'this test requires threads' if !$Config{useithreads};

plan tests => 1;

require threads;
create threads sub{}=>->join;
require Scalar::Defer;
create threads sub{}=>->join;

pass();
