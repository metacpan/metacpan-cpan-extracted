use strict     ;
use Test::More ;
use String::Rexx qw(Reverse) ;
 


BEGIN { plan tests =>  2  };

### Usefull Variables


### Basic Usage
is   Reverse( 'abc')    ,   'cba'       ;
is   Reverse( '')    ,   ''       ;
