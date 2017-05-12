use strict;
use warnings;

# Test Pod::Constant with no POD

use Test::More tests => 1;
use Pod::Constant qw(:all);

pass(  'Module passes through without error' );
