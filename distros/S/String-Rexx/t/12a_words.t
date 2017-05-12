use strict       ;
use Test::More   ;
use String::Rexx qw( words) ;



BEGIN { plan tests =>  9  };

### Common Usage
is  words('a')   ,  1 ;
is  words(' a')  ,  1 ;
is  words('a ')  ,  1 ;
is  words('a b') ,  2 ;
is  words('The Republic of Perl')    ,    4 ;


### OTher Tests
is  words('') , 0            ;
is  words('a# @ ')      , 2  ;
is  words( 'x . $ ! ')  , 4  ;
is  words ( 3) , 1           ;
