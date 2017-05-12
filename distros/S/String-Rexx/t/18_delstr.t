use strict     ;
use Test::More ;
use String::Rexx qw(delstr);
 

BEGIN { plan tests =>  8  };



### Basic Usage
is   delstr( 'Republic', 1    )     =>  ''            ;
is   delstr( 'Republic', 2    )     =>  'R'           ;
is   delstr( 'Republic', 1, 2 )     =>  'public'      ;
is   delstr( 'Republic', 9, 0 )     =>  'Republic'    ;
is   delstr( 'Republic', 9, 2 )     =>  'Republic'    ;


### Extra
is   delstr( '', 2            )      =>  ''           ;
is   delstr( '', 0            )      =>  ''           ;
is   delstr( '', 0, 0         )      =>  ''           ;

