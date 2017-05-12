use Test::More ;
use String::RexxStack::Named ':all';
BEGIN { plan tests => 21 }

my $ret;


limit_bytes 'apple', 3;
is +(limit_bytes 'apple')      =>  3 ;
is   qstack('apple')           =>  1 ; 
is   +([NEWSTACK 'apple'])     =>  2 ;

is   +([NEWSTACK 'paul'])      =>  1 ;
is   qstack('paul')            =>  1 ; 

[delstack 'apple'];


is   qstack()            =>   1   ,   'qstack trivial';
is   qstack('')          =>   1   ; 
is   qstack('john')      =>   0   ; 

ok   exists +(newstack 'john')  ->{max_sos} ;
is   qstack('john')      =>   1   ,  'qstack common' ;

Push 'john' ,  qw(one two) ;
ok   [NEWSTACK 'john'];
is   qstack('john')       =>   2   ; 
is   +(delstack 'john')   =>   1   ;
is   qstack('john')       =>   1   ; 

$ret = delstack 'john';
is   $ret                 =>   1   ;
is   qstack('john')       =>   1   ; 
 
is   +([DELSTACK])        =>   1   ;
is   +([DELSTACK])        =>   1   ;

limit_entries 'SESSION', 32         ; 
is   +(limit_entries 'SESSION')  =>  32   ;
Push 'SESSION', 'apple';
[NEWSTACK]    ;
is   +(limit_entries)     =>  32    ;
is   +([DELSTACK])        =>   1    ;

#dumpe;
