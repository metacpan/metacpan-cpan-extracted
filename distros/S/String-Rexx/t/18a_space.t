use strict     ;
use Test::More ;
use String::Rexx qw(space);


BEGIN { plan tests =>  15  };

### Basic Usage
is   space( 'a ', 3 )         =>   'a'          ;
is   space( ' a', 3 )         =>   'a'          ;
is   space( 'a b', 0 )        =>   'ab'         ;
is   space( 'a b', 1 )        =>   'a b'        ;
is   space( 'a b', 2 )        =>   'a  b'       ;
is   space( 'a b', 3 )        =>   'a   b'      ;
is   space( 'a b c', 0 )      =>   'abc'        ;
is   space( 'a b c', 1 )      =>   'a b c'      ;
is   space( 'a b c', 2 )      =>   'a  b  c'    ;
is   space( 'a b c', 3 )      =>   'a   b   c'  ;
is   space( 'a b', 1, '+' )   =>   'a+b'        ;
is   space( 'a b', 2, '+' )   =>   'a++b'       ;
is   space( 'a   b' )         =>   'a b'        ;
is   space('an  apple     a') => 'an apple a'   ;

# Extra
is  space('an apple', 1 , '*') => 'an*apple'    ;
