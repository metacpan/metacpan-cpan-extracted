#!perl 

# pragmas
use 5.10.0;
use strict;
use warnings;

# imports
use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

BEGIN { use_ok 'Mojo::RoleTiny' }

done_testing();

