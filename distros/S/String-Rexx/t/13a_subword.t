use Test::More ;
use Test::Exception;
use String::Rexx qw(subword);
 
BEGIN { plan tests =>  28  };



### Common Usage
is  subword('The Republic of Perl', 1, 0)    =>   ''                     ;
is  subword('The Republic of Perl', 1, 1)    =>   'The'                  ;
is  subword('The Republic of Perl', 1, 2)    =>   'The Republic'         ;
is  subword('The Republic of Perl', 1, 3)    =>   'The Republic of'      ;
is  subword('The Republic of Perl', 1, 4)    =>   'The Republic of Perl' ;
is  subword('The Republic of Perl', 1, 5)    =>   'The Republic of Perl' ;
is  subword('The Republic of Perl', 1, 6)    =>   'The Republic of Perl' ;

is  subword('The Republic of Perl', 2, 1)    =>   'Republic'             ;
is  subword('The Republic of Perl', 2, 2)    =>   'Republic of'          ;
is  subword('The Republic of Perl', 2, 3)    =>   'Republic of Perl'     ;
is  subword('The Republic of Perl', 2, 4)    =>   'Republic of Perl'     ;

is  subword('The Republic of Perl', 4)       =>   'Perl'                 ; 
is  subword('The Republic of Perl', 3)       =>   'of Perl'              ; 
is  subword('The Republic of Perl', 2)       =>   'Republic of Perl'     ; 
is  subword('The Republic of Perl', 1)       =>   'The Republic of Perl' ; 


### Other Tests
is  subword('The   Republic of Perl', 1, 2)  =>   'The   Republic'       ; 

is subword ('an  apple  a day',  1, 1) , 'an'            ;
is subword ('an  apple  a'    ,  1,  ) , 'an  apple  a'  ;
is subword ('an  apple  a day',  2, 1) , 'apple'         ;
is subword ('an  apple  a day',  2, 2) , 'apple  a'      ;
is subword ('an  apple  a day',  2, 3) , 'apple  a day'  ;
is subword ('an  apple  a day',  4,  ) , 'day'           ;
is subword ('an  apple  a day',  4, 1) , 'day'           ;
is subword ('an  apple  a day',  4, 4) , 'day'           ;
is subword ('an  apple  a day',  4, 0) , ''              ;
is subword ('an  apple  a day',  8, 1) , ''              ;
is subword ('',  1, 1)                 , ''              ;
dies_ok    { subword ('an  apple  a day', 0,) } ;
