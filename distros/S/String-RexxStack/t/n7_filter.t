use Test::More ;
use String::RexxStack::Named ':all' ;
BEGIN { plan tests => 6 }

[newstack 'john']; 
[NEWSTACK  'john']; 
[ NEWSTACK  'john']; 
[ NEWSTACK  'john' ]; 
is   +( [NEWSTACK 'john'])   =>   5     , 'filter named' ;
is   +( [NEWSTACK 'john'])   =>   6;
my $a=3;
is   $a                      =>   3;


[newstack ]; 
[NEWSTACK  ]; 
[ NEWSTACK  ]; 
is   +( [NEWSTACK ])         =>   5     , 'filter SESSION' ;
is   +( [NEWSTACK ])         =>   6;
is   $a                      =>   3;

