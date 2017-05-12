use Test::More;
use Test::Exception;
use String::Rexx qw( sign );


BEGIN { plan tests =>  3  };

is  sign(  9 ) ,  1;
is  sign( -2 ) , -1;
is  sign(  0 ) ,  0;
