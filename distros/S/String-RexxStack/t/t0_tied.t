use Test::More;

BEGIN { plan tests=> 10 }
use String::TieStack;

my $s = new String::TieStack;
my $t = tie my @arr , 'String::TieStack';

is  push( @arr, 'perl')  	=>    1       ;
is  scalar @arr          	=>    1       ;
is  $#arr                	=>    0       ;
is  pop( @arr )          	=>   'perl'   ;

push     @arr , 'one';
unshift  @arr , 'zero';

$t->makebuf;
push    @arr, 'three' ;
unshift @arr, 'two';
push    @arr, 'four' ;

is   $#arr  => 4;

$t->makebuf;
push    @arr, 'six';
unshift @arr, 'five'  ;
is   $#arr  => 6;

$t->dropbuf;
is   $#arr  => 4;
$t->makebuf;
push    @arr, 'six';
unshift @arr, 'five'  ;
is   $#arr  => 6;

$t->dropbuf;
$t->dropbuf;
is   $#arr  => 1;

$t->dropbuf();
is  $#arr   => 1;

#print Dumper tied @arr; exit;
