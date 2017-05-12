use Test::More ;
use String::Rexx qw(delword);
 

BEGIN { plan tests =>  26  };


### Basic Usage

is   delword( 'a b c'   , 1     )           =>  ''             ;  
is   delword( 'a b c'   , 2     )           =>  'a '           ;  
is   delword( 'a b c'   , 5     )           =>  'a b c'        ;  
is   delword( 'a b c'   , 1, 1  )           =>   'b c'         ;  
is   delword( 'a b c'   , 2, 1  )           =>   'a c'         ;  
is   delword( 'a b  c'  , 2, 1  )           =>   'a c'         ;  
is   delword( 'a  b  c' , 2, 1  )           =>   'a  c'        ;  
is   delword( 'a b c'   , 2, 2  )           =>   'a '          ; 
is   delword( 'a b c'   , 3, 1  )           =>   'a b '        ; 
is   delword( 'a b c'   , 3, 9  )           =>   'a b '        ; 
is   delword( 'a b  c'  , 3, 1  )           =>   'a b  '       ; 
is   delword( 'a b  c'  , 1, 3  )           =>   ''            ; 
is   delword( 'one two three' , 1, 1  )     =>  'two three'    ;  
is   delword( 'one two three' , 1, 2  )     =>  'three'        ;  
is   delword( 'one two three' , 2, 1  )     =>  'one three'    ;  
is   delword( 'an apple a day', 2    )      =>  'an '          ;
is   delword( 'an apple a day', 2    )      =>  'an '          ;
is   delword( 'an apple a day', 3    )      =>  'an apple '    ;
is   delword( 'an apple a day', 4    )      =>  'an apple a '  ;
is   delword( 'an apple a day', 1, 2 )      =>  'a day'        ;
is   delword( 'an apple a day', 1, 3 )      =>  'day'          ;


### Extra

is   delword( 'a b c'  , 1, 0  )            =>  'a b c'         ;  
is   delword( ''       , 1, 0  )            =>  ''              ;  
is   delword( 'a *?? b', 2, 1  )            =>  'a b'           ;  
is   delword( 'an apple a day', 5    )      =>  'an apple a day';
is   delword( 'an apple a day', 6    )      =>  'an apple a day';

