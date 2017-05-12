use strict     ;
use Test::More ;
use String::Rexx qw( wordpos );


BEGIN { plan tests =>  8  };


### Basic Usage
is  wordpos (john   =>    'an apple a day') , 0;
is  wordpos (an     =>    'an apple a day') , 1;
is  wordpos (apple  =>    'an apple a day') , 2;
is  wordpos (a      =>    'an apple a day') , 3;
is  wordpos (day    =>    'an apple a day') , 4;


### Extra
is  wordpos ( '+'   =>    'an apple a day') , 0;
is  wordpos ( '+'   =>    'an apple a + y') , 4;
is  wordpos ( ''    =>    'an apple a day') , 0;
