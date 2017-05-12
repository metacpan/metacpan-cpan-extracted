use strict;
use warnings;

use Test::More;


BEGIN { use_ok( 'Solaris::ProcessContract::Base' ); }

can_ok( 'Solaris::ProcessContract::Base', 'new' );
can_ok( 'Solaris::ProcessContract::Base', 'debug' );


done_testing()

