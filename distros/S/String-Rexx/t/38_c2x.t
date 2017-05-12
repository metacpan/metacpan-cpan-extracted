use Test::More;
use Test::Exception;
use String::Rexx qw( c2x );


BEGIN { plan tests =>  4  };


is  c2x ( 'ab' )       =>  '6162'               ;
is  c2x ( 3    )       =>  33                   ;
is  c2x ( 'an apple')  =>  '616e206170706c65'   ;
is  c2x ( '')          =>  ''                   ;

