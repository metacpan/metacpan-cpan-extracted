use Test::More ;
use String::TieStack  ;

BEGIN { plan tests => 10 }

my $t = tie my @arr , 'String::TieStack';
my $ret;

push  @arr , qw( one two ) ;
$ret = $t->makebuf;
is  $ret        =>  $t->qbuf;
push  @arr , qw( one two  three four) ;
$ret = $t->makebuf;
is  $ret        =>  $t->qbuf;
$ret = $t->makebuf;
is  $ret        =>  undef;
push  @arr , qw( one two  three four) ;
$ret = $t->makebuf;
is  $ret        =>  $t->qbuf;

@arr = ();
push  @arr , qw( one two ) ;
$t->makebuf;
$t->makebuf;
is   $t->qbuf    =>  1;
$t->makebuf;
is   $t->qbuf    =>  1;
$t->dropbuf;
is   $t->qbuf    =>  0;
$t->makebuf;
$t->makebuf;
$t->makebuf;
is   $t->qbuf    =>  1;
$t->dropbuf;
is   $t->qbuf    =>  0;
$t->dropbuf;
is   $t->qbuf    =>  0;
