use strict     ;
use Test::More ;
use String::Rexx qw(right);
 

BEGIN { plan tests =>  7  };


### Basic Usage
is   right( Perl =>  0      )   =>  ''         ;
is   right( 'of Perl'=> 4   )   =>  'Perl'     ;
is   right( Perl => 6       )   =>  '  Perl'   ;
is   right( Perl => 0 , '_' )   =>  ''         ;
is   right( Perl => 6 , '_' )   =>  '__Perl'   ;


## Extra
is   right( ''=> 2          )   =>   '  '      ;
is   right( ''=> 2, '_'     )   =>   '__'      ;
