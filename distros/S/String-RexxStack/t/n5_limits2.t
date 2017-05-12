use Test::More ;
use String::RexxStack::Named ':all' ;
BEGIN { plan tests => 19 }

limits 'SESSION', 2, 3 ;
is   +(limit_entries)            =>     2 ,     'limits' ;
is   +(limit_bytes)              =>     3 ;
is_deeply    [limits]            =>  [2,3];

limits  'john', 5, 6 ;
is   +(limit_entries 'john')     =>     5 ;
is   +(limit_bytes 'john')       =>     6 ;
is_deeply    [limits 'john']     =>  [5,6];



limit_entries 'JAck' ,  4 ;
Push 'JAck' , 1, 2, 3;
is     +(qelem 'JAck')  =>  3 ;
is     +(limit_entries 'JAck')  =>  4  , 'limit_entries (named)'  ;
Push   'JAck' , 4, 5, 6;
is     +(qelem 'JAck')   =>  3  ;
Push   'JAck' , 4;
is     +(qelem 'JAck')   =>  4  ;
Push   'JAck' , 5 ;
is     +(qelem 'JAck')   =>  4  ;


clear  'JAck';
limit_bytes   'JAck'    =>   .004  ;
limit_entries 'JAck'    =>    0    ;
Push   'JAck' , 1, 2, 3, 4;
is     +(qelem 'JAck')  =>    4    , 'limit_bytes (named) ';
Push   'JAck' , 5;
is     +(qelem 'JAck')  =>    4    ;


limit_entries  'SESSION' =>   4 ;
is     +(limit_entries )  , 4  , 'limit_entries (session)'  ;
Push   'SESSION', 1, 2, 3;
is     +(qelem )   =>  3  ;
Push   'SESSION', 4;
is     +(qelem )   =>  4  ;
Push   'SESSION', 5 ;
is     +(qelem )   =>  4  ;

clear ;
limit_bytes   'SESSION'   =>   .004 ;
limit_entries 'SESSION'   =>    0   ;
Push   'SESSION' , 1, 2, 3, 4;
is     +(qelem) , 4  , 'limit_bytes (session) ';
Push   'SESSION' , 5;
is     +(qelem)   =>  4  ;

