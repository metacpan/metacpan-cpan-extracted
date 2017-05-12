use strict     ;
use Test::More ;
use Test::Exception;
use String::Rexx qw(word);
 
BEGIN { plan tests =>  10  };


### Basic Usage
is   word ( 'The Republic of Perl', 1 )        =>   'The'          ;
is   word ( 'The Republic of Perl', 2 )        =>   'Republic'     ;
is   word ( 'The Republic of Perl', 3 )        =>   'of'           ;
is   word ( 'The Republic of Perl', 4 )        =>   'Perl'         ;

## Extra
is   word ( '', 4   )                          =>   ''             ;
is   word ( 'The Republic of Perl', 6 )        =>   ''             ;
is   word ( 'an  apple  a day',  5)            =>   ''             ;
is   word ( '',  1  )                          =>   ''             ;

dies_ok { word ('an  apple  a day',  0) }                          ;
dies_ok { word ('an  apple  a day', -1) }                          ;
