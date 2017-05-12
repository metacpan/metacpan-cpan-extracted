use Test::More;
use Test::Exception;
use String::Rexx qw( d2x );

BEGIN { plan tests =>  5  };

is  d2x (745651) , "b60b3"  ;
is  d2x (0)      ,  '0'     ;
is  d2x (10)     ,  'a'     ;

dies_ok  { d2x  -3  } ;
dies_ok  { d2x  a=> } ;

