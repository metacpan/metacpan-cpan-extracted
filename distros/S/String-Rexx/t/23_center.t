use strict     ;
use Test::More ;
use String::Rexx qw(center);
 


BEGIN { plan tests =>  12  };

### Basic Usage
is   center( 'a' , 0 )        ,  ''            ;
is   center( 'a' , 1 )        ,  'a'           ;
is   center( 'a' , 3 )        ,  ' a '         ;
is   center( 'a' , 4 )        ,  ' a  '        ;
is   center( 'a' , 5 )        ,  '  a  '       ;

is   center( 'ab' , 0 )        ,  ''           ,   'zero length'   ;
is   center( 'ab' , 1 )        ,  'a'          ;
is   center( 'ab' , 2 )        ,  'ab'         ;
is   center( 'ab' , 3 )        ,  'ab '        ;
is   center( 'ab' , 4 )        ,  ' ab '       ;
is   center( 'ab' , 5 )        ,  ' ab  '      ;

### Extra
is   center( '' , 4 )        ,  '    '      ;
