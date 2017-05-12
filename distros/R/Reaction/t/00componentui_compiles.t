use strict;
use warnings;
use Test::More tests => 1;

BEGIN { $ENV{DBIC_OVERWRITE_HELPER_METHODS_OK} = 1; }

use_ok('ComponentUI') 
  or BAIL_OUT('ComponentUI does not compile, giving up');

