use Test::More ;
use String::Rexx qw(translate);



BEGIN { plan tests =>  9  };


### Basic Usage
is   translate( 'apple'                    )            ,  'APPLE'  ;
is   translate( 'apple', 'AE', 'ae'        )            ,  'ApplE'  ;
is   translate( 'apple', 'AE', 'ae'  , '_' )            ,  'ApplE'  ;
is   translate( 'apple', 'AE', 'aep' , '_' )            ,  'A__lE'  ;


# Extra

is   translate( ''     , 'AE', 'ae'        )            ,  ''       ;
is   translate( 'apple', ''  , 'ae'  , '_' )            ,  '_ppl_'  ;
is   translate( 'apple', 'AE', ''    , '_' )            ,  'apple'  ;
is   translate( 'apple', ''  , 'ae'  , ''  )            ,  ' ppl '  ;
is   translate( 'apple' , 'AE' )                        ,   undef   ;
