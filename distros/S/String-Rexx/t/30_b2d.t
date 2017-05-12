use Test::More;
use Test::Exception;
use String::Rexx qw( b2d );

BEGIN { plan tests =>  6  };


is  b2d ( '00'      ) ,   0   ;
is  b2d ( '0011'    ) ,   3   ;
is  b2d ( '0111'    ) ,   7   ;
is  b2d ( '11111111') , 255   ;

dies_ok  { b2d 'a'  } ;
dies_ok  { b2d '03' } ;


