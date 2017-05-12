use strict     ;
use Test::More ;
use String::Rexx qw(countstr);
 



BEGIN { plan tests =>   14 };


### Basic Usage
is   countstr( a   =>  'apple'        )    =>    1      ;
is   countstr( p   =>  'apple'        )    =>    2      ;
is   countstr( pp  =>  'apple'        )    =>    1      ;
is   countstr( aa  =>  'aapaa'        )    =>    2      ;
is   countstr( pp  => 'an apple a day')    =>    1      ;
is   countstr( a   => 'an apple a day')    =>    4      ;
is   countstr( p   => 'an apple a day')    =>    2      ;


# Extra
is   countstr( p  =>  ''              )     =>   0      ;        
is   countstr( '' ,   'apple'         )     =>   0      ;        
is  countstr( '*' =>  'an apple a day')     =>   0      ;
is  countstr( '*' =>  'an apple * day')     =>   1      ;
is  countstr( '.' =>  'an apple * day')     =>   0      ;
is  countstr( '.' =>  "an apple \n . day")  =>   1      ;
is  countstr(  a  =>  3              )      =>   0      ;
