use strict;
use warnings;

use Test::More 'tests' => 7;


use_ok( 'Solaris::ProcessContract' );
use_ok( 'Solaris::ProcessContract::Base' );
use_ok( 'Solaris::ProcessContract::Contract' );
use_ok( 'Solaris::ProcessContract::Contract::Control' );
use_ok( 'Solaris::ProcessContract::Exceptions' );
use_ok( 'Solaris::ProcessContract::Template' );
use_ok( 'Solaris::ProcessContract::XS' );


done_testing()

