use Test::More tests=>11;
use  String::TieStack;

my $s = new String::TieStack;
my $t = tie my @arr , 'String::TieStack';

push     @arr , 'one';
unshift  @arr , 'zero';

$t->makebuf;
push    @arr, 'three' ;
unshift @arr, 'two';

pop @arr;
pop @arr;
is $t->buffers_count   =>  1 , 'pop bellow buffer';
pop @arr;
is $t->buffers_count   =>  0 ;
pop @arr;
is $t->buffers_count   =>  0 ;
is pop @arr , undef;
is $t->buffers_count   =>  0 ;

push @arr , 'zero';
$t->makebuf;
push @arr , 'one';
$t->CLEAR;
is  @arr , 0            =>  'clear ';

push @arr, 'zero';
$t->dropbuf;
is  @arr , 1            =>  'should not drop zero buffer';

$t->CLEAR;
push @arr, 'zero';
$t->makebuf;
push @arr, 'one';
$t->makebuf;
push @arr, 'two';
is @arr , 3              =>  'desbuf';
$t->desbuf;
is @arr                  =>  1;

is $t->qelem  , 1        => 'qelem'  ;
is $t->queued , 1        => 'queued' ;
