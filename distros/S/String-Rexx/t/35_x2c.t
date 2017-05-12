use Test::More;
use Test::Exception;
use String::Rexx qw( x2c );


BEGIN { plan tests =>  7  };

# Common Usage
is  x2c ( '616e206170706c65')  =>  'an apple'   ;
is  x2c ( 6162 )               =>  'ab'         ;
is  x2c ( 33   )               =>   3           ;

# Extra
is  x2c ( '')     =>  ''    ;
is  x2c ( 0)      =>  ''    ;
dies_ok { x2c 'z' }         ;
dies_ok { x2c 'z', 1 }      ;

