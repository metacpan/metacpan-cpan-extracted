use strict     ;
use Test::More ;
use String::Rexx qw(compare);
 

BEGIN { plan tests =>  10  };



### Basic Usage
is   compare( 'a'  ,  'a'       )      =>  0      ;
is   compare( 'b'  ,  'a'       )      =>  1      ;
is   compare( 'a'  ,  'b'       )      =>  1      ;
is   compare( 'aa' ,  'ab'      )      =>  2      ,    'two'      ;

is   compare( 'a'  ,  'aa', 'a' )      =>  0      ,    'padding'  ;
is   compare( 'a'  ,  'a '      )      =>  0      ;
is   compare( 'a'  ,  'ab'      )      =>  2      ;
is   compare( 'a'  ,  'ab', 'b' )      =>  0      ;

### Extra
is   compare( ''  ,   'b'       )      =>  1      ;
is   compare( 'b' ,   ''        )      =>  1      ;

