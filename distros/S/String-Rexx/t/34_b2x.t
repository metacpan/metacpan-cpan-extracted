use Test::More;
use Test::Exception;
use String::Rexx qw( b2x );


BEGIN { plan tests =>  10  };

is b2x( '01100001'  )   =>  '61' ;
is b2x( '001100001' )   =>  '61' ;
is b2x( '1100001'   )   =>  '61' ;
is b2x( '0000001'   )   =>  '1'  ;
is b2x( '01111'     )   =>  'f'  ;
is b2x( '0'         )   =>  '0'  ;
is b2x( ''          )   =>  ''   ;
is b2x( '1111011110111101111' ) => '7bdef' ;
dies_ok { b2x 'a'   }            ;
dies_ok { b2x '310' }            ;
