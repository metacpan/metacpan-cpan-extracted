use Test::More ;
use String::TieStack  ;

BEGIN { plan tests => 38 }

my $t = tie my @arr , 'String::TieStack';

push  @arr , qw( one two three four ) ;
is   $t->qelem       =>  4;
is   $t->pull( 0 )   =>  0;
is   $t->qelem       =>  4;
is   $t->pull( 2 )   =>  2;
is   $t->qelem       =>  2;
is   $t->pull( 2 )   =>  2;
is   $t->qelem       =>  0;
is   $t->pull( 1 )   =>  undef ;
is   $t->qelem       =>  0;

@arr = () ;
push  @arr , qw( one two );
is    $t->makebuf                        =>               1 ;
push  @arr , qw( three four ) ;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [4, 1] ;
is_deeply   [ $t->pullbuf         ]      => ['four','three'];
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [2, 1] ;


@arr = () ;
push  @arr , qw( one two );
is    $t->makebuf                        =>               1 ;
push  @arr , qw( three );
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [3, 1] ;
is_deeply   [ $t->pullbuf         ]      =>       ['three'] ;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [2, 1] ;

@arr = () ;
push  @arr , qw( one two);
is    $t->makebuf                        =>               1 ;
push  @arr , qw( three four) ;
is    $t->makebuf                        =>               2 ;
push  @arr , qw( five six) ;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [6, 2] ;
is_deeply   [ $t->pullbuf         ]      =>  ['six', 'five'];
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [4, 2] ;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [4, 2] ;
is_deeply   [ $t->pullbuf         ]      =>              [] ;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [4, 2] ;

pop @arr;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [3, 1] ;

is_deeply   [ $t->pullbuf         ]      =>       ['three'] ;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [2, 1] ;

is_deeply   [ $t->pullbuf         ]      =>              [] ;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [2, 1] ;

pop @arr;
is $t->pullbuf                           =>            undef;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [1, 0] ;

is $t->pullbuf                           =>            undef;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [1, 0] ;

pop @arr;
is $t->pullbuf                           =>            undef;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [0, 0] ;
pop @arr;
is $t->pullbuf                           =>            undef;
is_deeply   [ $t->qelem, $t->qbuf ]      =>          [0, 0] ;

#$t->pdumpq;
