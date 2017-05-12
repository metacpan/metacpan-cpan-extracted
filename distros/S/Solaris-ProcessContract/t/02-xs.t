use strict;
use warnings;

use Test::More;


BEGIN { use_ok( 'Solaris::ProcessContract::XS' ); }

my $xs = new_ok( 'Solaris::ProcessContract::XS' );

ok( @Solaris::ProcessContract::XS::PARAM_FLAGS, 'PARAM_FLAGS list exists' );
ok( @Solaris::ProcessContract::XS::EVENT_FLAGS, 'EVENT_FLAGS list exists' );
ok( @Solaris::ProcessContract::XS::FUNCTIONS,   'FUNCTIONS list exists' );

PARAM_FLAG: foreach my $flag ( @Solaris::ProcessContract::XS::PARAM_FLAGS )
{
  ok( $xs->can( $flag ), "param flag $flag exists" );
}

EVENT_FLAG: foreach my $flag ( @Solaris::ProcessContract::XS::EVENT_FLAGS )
{
  ok( $xs->can( $flag ), "event flag $flag exists" );
}

METHODS: foreach my $function ( @Solaris::ProcessContract::XS::FUNCTIONS )
{
  my $method = substr $function, 1;
  ok( $xs->can( $method ), "method $method exists" );
}


done_testing();

