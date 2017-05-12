use Test::More ;
use String::TieStack  ;

BEGIN { plan tests => 36 }

my $t = tie my @arr , 'String::TieStack';

push  @arr , qw( one two three four ) ;
is   $t->qelem       =>  4     ;
$t->pull( 0 ) ;
is   $t->qelem       =>  4     ;
$t->pull( 2 ) ;
is   $t->qelem       =>  2     ;
$t->pull( 2 ) ;
is   $t->qelem       =>  0     ;
is   $t->pull( 1 )   =>  undef ;
is   $t->qelem       =>  0     ;

@arr = () ;
push  @arr , qw( one two );
$t->makebuf;
push  @arr , qw( three four ) ;
is   $t->qelem        => 4 ;
is   $t->qbuf         => 1 ;
$t->pullbuf;
is   $t->qelem        => 2 ;
is   $t->qbuf         => 1 ;

@arr = () ;
push  @arr , qw( one two);
$t->makebuf;
push  @arr , qw( three );
is   $t->qelem        =>  3 ;
is   $t->qbuf         =>  1 ;
$t->pullbuf;
is   $t->qelem        =>  2 ;
is   $t->qbuf         =>  1 ;

@arr = () ;
push  @arr , qw( one two );
$t->makebuf;
push  @arr , qw( three four ) ;
$t->makebuf;
push  @arr , qw( five six ) ;
is   $t->qelem        =>  6 ;
is   $t->qbuf         =>  2 ;
$t->pullbuf;
is   $t->qelem        =>  4 ;
is   $t->qbuf         =>  2 ;
$t->pullbuf;
is   $t->qelem        =>  4 ;
is   $t->qbuf         =>  2 ;
pop @arr;
is   $t->qelem        =>  3 ;
is   $t->qbuf         =>  1 ;
$t->pullbuf;
is   $t->qelem        =>  2 ;
is   $t->qbuf         =>  1 ;
$t->pullbuf;
is   $t->qelem        =>  2 ;
is   $t->qbuf         =>  1 ;
pop @arr;
$t->pullbuf;
is   $t->qelem        =>  1 ;
is   $t->qbuf         =>  0 ;
$t->pullbuf;
is   $t->qelem        =>, 1 ;
is   $t->qbuf         =>  0 ;
pop @arr;
is   $t->qelem        =>  0 ;
is   $t->qbuf         =>  0 ;
pop @arr;
is   $t->qelem        =>  0 ;
is   $t->qbuf         =>  0 ;
$t->pullbuf;
is   $t->qelem        =>  0 ;
is   $t->qbuf         =>  0 ;
