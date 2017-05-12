use strict;
use warnings;

use Test::More;


BEGIN { use_ok( 'Solaris::ProcessContract' ); }

can_ok( 'Solaris::ProcessContract', 'new' );
can_ok( 'Solaris::ProcessContract', 'get_template' );
can_ok( 'Solaris::ProcessContract', 'get_latest_contract' );
can_ok( 'Solaris::ProcessContract', 'get_latest_contract_id' );
can_ok( 'Solaris::ProcessContract', 'get_contract' );


done_testing()

