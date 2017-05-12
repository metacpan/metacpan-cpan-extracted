use strict     ;
use Test::More ;
use Test::Exception;

use String::Rexx qw(wordindex);
 
BEGIN { plan tests =>  19  };


### Basic Usage
is   wordindex ( 'one two three' ,  1 )    =>  1  ;
is   wordindex ( 'one two three' ,  2 )    =>  5  ;
is   wordindex ( ' one two three',  2 )    =>  6  ;
is   wordindex ( 'an     apple a',  2 )    =>  8  ;
is   wordindex ( 'an apple a'    ,  0 )    =>  0  ;
is   wordindex ( 'an apple a'    ,  1 )    =>  1  ;
is   wordindex ( '   an apple a' ,  1 )    =>  4  ;
is   wordindex ( 'an apple a'    ,  3 )    => 10  ;
is   wordindex ( 'an apple a'    ,  4 )    =>  0  ;
is   wordindex ( 'an apple a day',  1 )    =>  1  ;
is   wordindex ( 'an apple a day',  2 )    =>  4  ;
is   wordindex ( 'an apple a day',  3 )    => 10  ;
is   wordindex ( 'an apple a day',  4 )    => 12  ;
is   wordindex ( 'an apple a day',  6 )    =>  0  ;
is   wordindex ( ' an apple a day', 1 )    =>  2  ;


# Extra
is   wordindex ( '?f* two three' ,  2  )   =>  5  ;
is   wordindex ( 'an ,, apple a' ,  2  )   =>  4  ;
is   wordindex ( 'an,, apple a'  ,  2  )   =>  6  ;

dies_ok {   wordindex ('an apple a', -1) }        ;
                            
