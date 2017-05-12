use strict;
use warnings;

use Test::More;


BEGIN { use_ok( 'Solaris::ProcessContract::Template' ); }

can_ok( 'Solaris::ProcessContract::Template', 'new' );
can_ok( 'Solaris::ProcessContract::Template', 'activate' );
can_ok( 'Solaris::ProcessContract::Template', 'clear' );
can_ok( 'Solaris::ProcessContract::Template', 'reset' );
can_ok( 'Solaris::ProcessContract::Template', 'open' );
can_ok( 'Solaris::ProcessContract::Template', 'close' );
can_ok( 'Solaris::ProcessContract::Template', 'fd' );
can_ok( 'Solaris::ProcessContract::Template', 'set_parameters' );
can_ok( 'Solaris::ProcessContract::Template', 'get_parameters' );
can_ok( 'Solaris::ProcessContract::Template', 'set_informative_events' );
can_ok( 'Solaris::ProcessContract::Template', 'get_informative_events' );
can_ok( 'Solaris::ProcessContract::Template', 'set_fatal_events' );
can_ok( 'Solaris::ProcessContract::Template', 'get_fatal_events' );
can_ok( 'Solaris::ProcessContract::Template', 'set_critical_events' );
can_ok( 'Solaris::ProcessContract::Template', 'get_critical_events' );


done_testing()

