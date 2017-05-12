use 5.006;
use strict;
use warnings;

use Test;

BEGIN { plan tests => 2 }

use Muldis::D::Manual;
ok(1);

ok( $Muldis::D::Manual::VERSION, 0.009000 );

1;
