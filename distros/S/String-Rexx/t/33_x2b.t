use Test::More;
use Test::Exception;
use String::Rexx qw( x2b );


BEGIN { plan tests =>  8  };

is x2b( 1  )     =>  '1'                  ;
is x2b( 61 )     =>  '1100001'            ;
is x2b( 'f')     =>  '1111'               ;
is x2b( '0')     =>  0                    ;
is x2b( '' )     =>  ''                   ;
is x2b( '7bdef') =>  '1111011110111101111';
dies_ok { x2b 'z'   }                     ;
dies_ok { x2b '31z' }                     ;
