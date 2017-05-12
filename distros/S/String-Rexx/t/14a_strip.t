use Test::More ;
use Test::Exception;
use String::Rexx qw(strip) ;


BEGIN { plan tests =>  23  };


### Basic Functionality

is  strip( 'The'      ,  'l'       )    =>    'The'     ,  'leading' ;
is  strip( ' The'     ,  'L'       )    =>    'The'     ;
is  strip( ' The'     ,  'l'       )    =>    'The'     ; 
is  strip( '_The'     ,   l => '_' )    =>    'The'     ; 
is  strip( '  strip  ',   l =>     )    =>    'strip  ' ;
is  strip( '  strip  ',   L =>     )    =>    'strip  ' ;

is  strip( 'The'      , 't'        )    =>    'The'     ,  'trailing';
is  strip( 'The '     , 'T'        )    =>    'The'     ; 
is  strip( 'The_'     ,  T=> '_'   )    =>    'The'     ; 
is  strip( '  strip  ', T =>       )    =>    '  strip' ;


is  strip( 'The'      , 'b'        )    =>    'The'     ,  'both' ; 
is  strip( ' The '    , 'B'        )    =>    'The'     ;
is  strip( '_The_'    , 'B' , '_'  )    =>    'The'     ;
is  strip( '__The__'  , 'B' , '_'  )    =>    'The'     ;
is  strip( '  strip  ',  B =>      )    =>    'strip'   ;
is  strip( '  strip  ',    =>      )    =>    'strip'   ;
is  strip( '  strip  ',            )    =>    'strip'   ;



### Extra
is  strip( '**strip**', L  => '*'  )    =>   'strip**'   ;
is  strip( '++strip++', L  => '+'  )    =>   'strip++'   ;
is  strip( '..strip..', L  => '.'  )    =>   'strip..'   ;
is  strip( '..strip..', L  => '.'  )    =>   'strip..'   ;

SKIP: {
	eval {  require Test::Exception ; Test::Exception::->import } ;
        skip 'Test::Exception not available',  2   if $@ ;

        dies_ok(   sub { strip(apple => '   leading'     )}    );
        dies_ok(   sub { strip(apple => 'wrong_direction')}    );
}
