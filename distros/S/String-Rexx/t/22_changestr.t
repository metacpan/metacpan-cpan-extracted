use strict     ;
use Test::More ;
use String::Rexx qw(changestr);
 

BEGIN { plan tests =>  9  };



### Basic Usage
is   changestr(  p  =>  apple     => 'P'   )   =>   'aPPle'    ; 
is   changestr(  a  => 'an apple' =>  A  =>)   ,    'An Apple' ;


# Extra
is   changestr(  p  =>  ''        ,  'P'   ) =>   ''        ; 
is   changestr(  p  =>  apple     =>  ''   ) =>   'ale'     ; 
is   changestr(  a  => 'an apple' =>  ''   ) ,  'n pple'    ;
is   changestr( '*' => 'an *pple' =>  A  =>) ,  'an Apple'  ;
is   changestr( '(' => 'an )pple' =>  A  =>) ,  'an )pple'  ;
is   changestr( '(' => 'an (pple' =>  A  =>) ,  'an Apple'  ;
is   changestr(  a  => 3          => ''    ) ,  '3'         ;

