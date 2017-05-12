use strict     ;
use Test::More ;
use String::Rexx qw(Substr);
 


BEGIN { plan tests =>  7  };

### Usefull Variables
my $str  = 'The Republic of Perl' ;


### Basic Usage
is   Substr( $str, 1, 5 )          ,     'The R'        ;
is   Substr( $str, 2, 5 )          ,     'he Re'        ;

is   Substr( $str, 18, 2, '_' )    ,     'er'           ;
is   Substr( $str, 18, 3, '_' )    ,     'erl'          ;
is   Substr( $str, 18, 4, '_' )    ,     'erl_'         ;
is   Substr( $str, 18, 5, '_' )    ,     'erl__'        ;

###  More Thorough
is   Substr( '', 18, 0, '_' )      ,     ''             ;

#is   Substr( '', 18, 1, '_' )      ,     '_'            ; 
#is   Substr( '', 18, 2, '_' )      ,     '__'           ;
