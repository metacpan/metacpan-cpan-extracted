use strict     ;
use Test::More ;
use String::Rexx qw(Length);
 


BEGIN { plan tests =>  2  };



### Basic Usage
is   Length( 'YAS' )  ,  3  ;
is   Length( ''    )  ,  0  ;
