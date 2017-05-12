use Test::More tests=>21;
use String::RexxStack::Named qw( :all );

$Data::Dumper::Indent=2;




is   qstack()  , 1   => 'qstack trivial';
is   qstack('john')  =>  0  ; 
is   qstack('')      =>  1  ; 

Push  'one';
Queue 'zero';
is  qelem , 2  ,    'session stack';
makebuf;
Push 'SESSION' , qw( 2 3 4 5 6);
is    qbuf()    =>   1;
is    qelem()   =>   7;
Pop ;
is    qelem()   =>   6;
Pull ; 
is    qelem()   =>   5;
Pull 2 ; 
is    qelem()   =>   3;
Pull 0 ; 
is    qelem()   =>   3;
pull;
is    qelem()   =>   0;
is    qbuf()    =>   0;

Push  'john' , 'one';
Queue 'john' , 'zero';
is  qelem('john') , 2  ,    'named stack';
makebuf('john') ;
Push 'john' , qw( 2 3 4 5 6);
is    qbuf('john')    =>   1;
is    qelem('john')   =>   7;
Pull 'john', 1;
is    qelem('john')   =>   6;
Pull 'john' , 1 ; 
is    qelem('john')   =>   5;
Pull 'john', 2 ; 
is    qelem('john')   =>   3;
Pull 'john', 0 ; 
is    qelem('john')   =>   3;
pull 'john';
is    qelem('john')   =>   0;
is    qbuf('john')    =>   0;

#dumpe;
