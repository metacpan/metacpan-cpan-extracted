use strict     ;
use Test::More ;
use String::Rexx qw(insert);
 

BEGIN { plan tests =>  15  };



### Basic Usage
is   insert( 'e' ,  'Perl'              )        =>     'ePerl'           ;
is   insert( 'he',  'Perl'              )        =>     'hePerl'          ;

is   insert( 'e' ,  'Perl' , 0          )        =>     'ePerl'           ;
is   insert( 'e' ,  'Perl' , 1          )        =>     'Peerl'           ;
is   insert( 'e' ,  'Perl' , 4          )        =>     'Perle'           ;
is   insert( 'e' ,  'Perl' , 5          )        =>     'Perl e'          ;

is   insert( 'her' , 'Perl' , 5 , 2     )        =>     'Perl he'         ;
is   insert( 'her' , 'Perl' , 5 , 2, '_')        =>     'Perl_he'         ;

## Extra

is  insert( '' , 'Perl'                 )        =>     'Perl'            ; 
is  insert( '' , 'Perl', 0              )        =>     'Perl'            ; 
is  insert( '' , '', 0                  )        =>     ''                ; 
is  insert( 'Perl' , '', 0              )        =>     'Perl'            ; 
is  insert( 'Perl' , '', 0 , 2          )        =>     'Pe'              ; 
is  insert( 'Perl' , '', 0 , 2, '_'     )        =>     'Pe'              ; 
is  insert( 'Perl' , '', 2 , 1, '_'     )        =>     '__P'             ; 


