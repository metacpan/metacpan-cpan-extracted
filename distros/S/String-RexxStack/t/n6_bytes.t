use Test::More ;
use String::RexxStack::Named ':all' ;
BEGIN { plan tests => 10 }

is    +(total_bytes)       => 0  , 'SESSION total_bytes' ;
limits 'SESSION', 0, 3 ;
Push   'SESSION' , 'apple';
is    +(total_bytes)       => 5 ;
Push   'SESSION' , 'c';
is    +(total_bytes)       => 6 ;
Pop    'SESSION' , 1 ;
is    +(total_bytes)       => 5 ;
clear;
is    +(total_bytes)       => 0 ;


is    +(total_bytes 'john')       => undef , 'named total_bytes' ;
limits 'john', 0, 3 ;
Push   'john' , 'apple';
is    +(total_bytes 'john')       => 5 ;
Push   'john' , 'c';
is    +(total_bytes 'john')       => 6 ;
Pop    'john' , 1 ;
is    +(total_bytes 'john')       => 5 ;
clear 'john';
is    +(total_bytes 'john')       => 0 ;
#dumpe;

