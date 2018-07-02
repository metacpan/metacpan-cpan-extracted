use strict;
use warnings;

use Test::Most;

use constant MODULE => 'MojoX::ConfigAppStart';

BEGIN { use_ok(MODULE); }
require_ok(MODULE);

done_testing;
