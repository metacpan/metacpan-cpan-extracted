use strict;
use warnings;

use Test::More;


BEGIN { use_ok( 'Solaris::ProcessContract::Contract::Control' ); }

can_ok( 'Solaris::ProcessContract::Contract::Control', 'new' );
can_ok( 'Solaris::ProcessContract::Contract::Control', 'abandon' );
can_ok( 'Solaris::ProcessContract::Contract::Control', 'reset' );
can_ok( 'Solaris::ProcessContract::Contract::Control', 'open' );
can_ok( 'Solaris::ProcessContract::Contract::Control', 'close' );
can_ok( 'Solaris::ProcessContract::Contract::Control', 'fd' );


done_testing()

