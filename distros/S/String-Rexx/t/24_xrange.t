use strict     ;
use Test::More ;
use String::Rexx qw(xrange);


BEGIN { plan tests =>  4  };


### Basic Usage
is   xrange ( 'a' , 'c' )     =>  'abc'  ;
is   xrange ( 'a' , 'b' )     =>  'ab'   ;


# Extra
is  xrange( 'a' , 'a' )       =>  'a'    ;
is  length xrange ('b', 'a')  =>  257    ;


