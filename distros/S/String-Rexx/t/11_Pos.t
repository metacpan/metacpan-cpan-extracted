use strict     ;
use Test::More ;
use String::Rexx qw(Pos);
 


BEGIN { plan tests =>  11  };



### Basic Usage
is   Pos( 'he',  'The Republic' )        ,  2      ;
is   Pos( 'T' ,  'The Republic' )        ,  1      ;
is   Pos( 'e' ,  'The Republic' )        ,  3      ;
is   Pos( 'c' ,  'The Republic' )        ,  12     ;

is   Pos( 'e' ,  'The Republic' , 1 )    ,  3      ;
is   Pos( 'e' ,  'The Republic' , 4 )    ,  6      ;



## Extra
is  Pos( 'notExist' , 'The Republic')    ,  0       ;
is  Pos( ''         , 'The Republic')    ,  0       ;
is  Pos( '0'        , 'The Republic')    ,  0       ;
is  Pos( 'e'        , ''            )    ,  0       ;
is  Pos( 'e'        , '', 2         )    ,  0       ;


