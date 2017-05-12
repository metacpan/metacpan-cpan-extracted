use strict     ;
use Test::More ;
use String::Rexx qw( centre errortext d2c);

######### Usefull Constants
BEGIN { plan tests =>  3  };

is     centre('a',3)  , ' a '                    ,   'centre'     ;
is     errortext(15)  , 'Block device required'  ,   'errortext'  ;    
is     d2c(65)        , 'A'                      ,   'd2c'        ;
