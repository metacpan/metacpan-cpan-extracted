use strict      ;
use Test::More  ;
use Test::Exception;
use String::Rexx qw( wordlength ) ;

BEGIN { plan tests =>  18  };


### Common Usage
is  wordlength ('an apple a day',       1)    =>  2 ;
is  wordlength ('an apple a day',       2)    =>  5 ;
is  wordlength ('an apple a day',       3)    =>  1 ;
is  wordlength ('an apple a day',       4)    =>  3 ;
is  wordlength ('an apple a day',       5)    =>  0 ;
is  wordlength ('an apple a day',       6)    =>  0 ;
is  wordlength ('The Republic of Perl', 0)    =>  0 ;
is  wordlength ('The Republic of Perl', 1)    =>  3 ;
is  wordlength ('The Republic of Perl', 2)    =>  8 ;
is  wordlength ('The Republic of Perl', 3)    =>  2 ;
is  wordlength ('The Republic of Perl', 4)    =>  4 ;
is  wordlength ('The Republic of Perl', 5)    =>  0 ;

### Extra
is  wordlength ('an apple a day',        0)   =>  0 ;
is  wordlength ('an, apple'     ,        1)   =>  3 ;
is  wordlength ('an , apple'    ,        2)   =>  1 ;
is  wordlength ('', 1)                        => 0 ;
is  wordlength ('', 2)                        => 0 ;
dies_ok { wordlength ('an apple a day', -1) };
