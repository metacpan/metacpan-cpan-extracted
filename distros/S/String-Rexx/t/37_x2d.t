use Test::More;
use Test::Exception;
use String::Rexx qw( x2d );


BEGIN { plan tests =>  5  };

# Common
is  x2d( '0x10')   =>  '16'   ;
is  x2d( '0x00')   =>  '0'    ;
is  x2d( '0xa0')   =>  '160'  ;

# Extra
is  x2d( ''    )   =>  0      ;
dies_ok  { x2d 'za' };
