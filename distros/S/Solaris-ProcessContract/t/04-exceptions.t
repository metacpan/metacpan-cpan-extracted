use strict;
use warnings;

use Test::More;


BEGIN { use_ok( 'Solaris::ProcessContract' ); }

my $pc = new_ok( 'Solaris::ProcessContract' );

can_ok( 'Solaris::ProcessContract::Exception',          'throw' );
can_ok( 'Solaris::ProcessContract::Exception::XS',      'throw' );
can_ok( 'Solaris::ProcessContract::Exception::Params',  'throw' );

{

  eval 
  {
    Solaris::ProcessContract::Exception->throw
    (
      "generic exception",
    );
  };

  if ( my $ex = Solaris::ProcessContract::Exception->caught() )
  {
    pass ( 'caught generic exception' );
    is( $ex->error(), 'generic exception', 'got error from generic exception' );
  }
  else
  {
    fail( 'caught generic exception' );
  }

}


{

  eval 
  {
    Solaris::ProcessContract::Exception::XS->throw
    (
      "xs exception",
    );
  };

  if ( my $ex = Solaris::ProcessContract::Exception::XS->caught() )
  {
    pass ( 'caught xs exception' );
    is( $ex->error(), 'xs exception', 'got error from xs exception' );
    isa_ok( $ex, 'Solaris::ProcessContract::Exception', 'xs exception is also a generic exception' );
  }
  else
  {
    fail( 'caught xs exception' );
  }

}


{

  eval 
  {
    Solaris::ProcessContract::Exception::Params->throw
    (
      "params exception",
    );
  };

  if ( my $ex = Solaris::ProcessContract::Exception::Params->caught() )
  {
    pass ( 'caught params exception' );
    is( $ex->error(), 'params exception', 'got error from params exception' );
    isa_ok( $ex, 'Solaris::ProcessContract::Exception', 'params exception is also a generic exception' );
  }
  else
  {
    fail( 'caught params exception' );
  }

}


done_testing()
