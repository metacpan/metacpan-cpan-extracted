use strict;
use warnings;

use Test::More;


BEGIN { use_ok( 'Solaris::ProcessContract::Contract' ); }

can_ok( 'Solaris::ProcessContract::Contract', 'new' );
can_ok( 'Solaris::ProcessContract::Contract', 'id' );
can_ok( 'Solaris::ProcessContract::Contract', 'control' );


done_testing()

