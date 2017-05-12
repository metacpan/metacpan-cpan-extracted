use strict     ;
use Test::More ;
use String::Rexx qw(lastpos);
 

BEGIN { plan tests =>  11  };


### Basic Usage
is   lastpos( 'he'   ,    'The Republic' )        =>  2      ;
is   lastpos( 'T'    ,    'The Republic' )        =>  1      ;
is   lastpos( 'e'    ,    'The Republic' )        =>  6      ;
is   lastpos( 'c'    ,    'The Republic' )        =>  12     ;


is   lastpos( 'e'    ,    'The Republic', 5 )     =>  3      ;
is   lastpos( 'e'    ,    'The Republic', 6 )     =>  6      ;


## Extra
is  lastpos( 'cntr',    'The Republic')          =>  0      ;
is  lastpos( ''      ,    'The Republic')          =>  0      ;
is  lastpos( '0'     ,    'The Republic')          =>  0      ;
is  lastpos( 'e'     ,    ''            )          =>  0      ;
is  lastpos( 'e'     ,    '', 2         )          =>  0      ;



