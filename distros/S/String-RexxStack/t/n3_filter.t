use Test::More ;
use String::RexxStack::Named ':all' ;
BEGIN { plan tests => 28 }


ok       [NEWSTACK 'JAck'];
is    +( [QSTACK 'JAck']    )     =>  1 ;
ok       [NEWSTACK 'JAck'];
is    +( [QSTACK 'JAck']    )     =>  2 ;
is    +( [DELSTACK 'JAck']  )     =>  1 ;



Push 'JAck' , 1, 2, 3;
is     +(qelem 'JAck')             =>  3 ;
[CLEAR 'JAck'];
is     0                           =>  qelem 'JAck';
Push 'JAck', 1, 2;
is    +( [MAKEBUF 'JAck'])         =>  1 ;
Push 'JAck', 3;
is    +([MAKEBUF 'JAck'])          =>  2 ;
is     qbuf('JAck')                =>  2 ;
[DROPBUF 'JAck'] ;
is     qbuf('JAck')                =>  1 ;
[DESBUF  'JAck'] ;
is     qbuf('JAck')                =>  0 ;

ok     [NEWSTACK];
is    +( [QSTACK ]             )   =>  2 ;
is    +( [DELSTACK ]           )   =>  1 ;
is    +( [DELSTACK 'SESSION' ] )   =>  1 ;
is    +( [QSTACK ]             )   =>  1 ;
is    +( [QSTACK 'SESSION']    )   =>  1 ;
Push 'SESSION', 1, 2, 3;
is    +(qelem)                     =>  3 ;
is    +(qelem 'SESSION')           =>  3 ;
[CLEAR];
is    +(qelem)                     =>  0 ;
is    +(qelem 'SESSION')           =>  0 ;
[CLEAR 'SESSION'];
is    +(qelem)                     =>  0 ;
Push 1 ;
is    +( [MAKEBUF] )               =>  1 ;
Push 2 ;
is    +( [MAKEBUF] )               =>  2 ;
is     qbuf()                      =>  2 ;
[DROPBUF] ;
is     qbuf()                      =>  1 ;
[DESBUF] ;
is     qbuf()                      =>  0 ;


#info ;
#dumpe 'JAck';
