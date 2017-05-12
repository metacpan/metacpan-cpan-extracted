use strict     ;
use Test::More ;
use String::Rexx qw(left);
 


BEGIN { plan tests =>  7  };



### Basic Usage
is   left( Perl =>  0       )     =>   ''         ;
is   left( 'of Perl'=> 4    )     =>   'of P'     ;
is   left( Perl =>  6       )     =>   'Perl  '   ;
is   left( Perl =>  0 , '_' )     =>   ''         ;
is   left( Perl =>  6 , '_' )     =>   'Perl__'   ;



## Extra
is   left( '' => 2          )     =>   '  '       ;
is   left( '' => 2, '_'     )     =>   '__'       ;
