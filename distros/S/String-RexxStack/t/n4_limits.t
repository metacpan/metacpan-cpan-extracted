use Test::More ;
use String::RexxStack::Named  ':all' ;
BEGIN { plan tests => 24 }

is +(limit_bytes 'jack', 3)           =>  3 , 'limit_bytes (named)' ;
is +(limit_bytes 'jack')              =>  3 ;
is +(limit_bytes 'jack', 0)           =>  0 ;
is +(limit_bytes 'jack')              =>  0 ;
is +(limit_bytes 'jack', undef)       =>  0 ;  
is +(limit_bytes 'jack')              =>  0 ;

is +(limit_bytes 'SESSION', 3)        =>  3 , 'limit_bytes SESSION' ;
is +(limit_bytes )                    =>  3 ;
is +(limit_bytes 'SESSION', 0)        =>  0 ;
is +(limit_bytes )                    =>  0 ;
is +(limit_bytes 'SESSION', undef)    =>  0 ;  
is +(limit_bytes 'SESSION')           =>  0 ;


is +(limit_entries 'john', 3)         =>  3 , 'limit_entries (named)' ;
is +(limit_entries 'john')            =>  3 ;
is +(limit_entries 'john', 0)         =>  0 ;
is +(limit_entries 'john')            =>  0 ;
is +(limit_entries 'john', undef)     =>  0 ;  
is +(limit_entries 'john')            =>  0 ;

is +(limit_entries 'SESSION', 3)      =>  3 , 'limit_entries SESSION' ;
is +(limit_entries )                  =>  3 ;
is +(limit_entries 'SESSION', 0)      =>  0 ;
is +(limit_entries )                  =>  0 ;
is +(limit_entries 'SESSION', undef)  =>  0 ;  
is +(limit_entries 'SESSION')         =>  0 ;
#dumpe  ;

