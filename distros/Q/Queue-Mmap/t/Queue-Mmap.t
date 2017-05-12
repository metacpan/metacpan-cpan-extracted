
use Test::More tests => 71;
#use Test::More 'no_plan';
BEGIN { use_ok('Queue::Mmap') };

my $file = "/tmp/Queue-Mmap".rand().".dat";
my $q = new Queue::Mmap(file=>$file,queue=>10,length=>10);

my $str6 = "012345";
my $str12 = "012345678901";
my $str18 = "012345678901234567";
my $str200 = "0123456789" x 20;
my $str80 = "0123456789" x 8;

my($t,$b,$c,$r) = $q->stat;
is $t,0, "top";
is $b,0, "bottom";
is $c,10, "capacity";
is $r,12, "record";
is $q->length,0,"length";

ok $q->push($str6),"push";
($t,$b) = $q->stat;
is $t,0, "top";
is $b,1, "bottom";
is $q->length,1,"length";

ok $q->push($str12),"push 2";
($t,$b) = $q->stat;
is $t,0, "top";
is $b,2, "bottom";
is $q->length,2,"length";

ok $q->push($str18),"push oversize";
($t,$b) = $q->stat;
is $t,0, "top";
is $b,4, "bottom";
is $q->length,4,"length";

is $q->pop,$str6,"pop";
($t,$b) = $q->stat;
is $t,1, "top";
is $b,4, "bottom";
is $q->length,3,"length";

is $q->pop,$str12,"pop 2";
($t,$b) = $q->stat;
is $t,2, "top";
is $b,4, "bottom";
is $q->length,2,"length";

is $q->top,$str18,"top good";
is $t,2, "top";
is $b,4, "bottom";
is $q->length,2,"length";

is $q->pop,$str18,"pop long";
($t,$b) = $q->stat;
is $t,4, "top";
is $b,4, "bottom";
is $q->length,0,"length";

is $q->pop,undef,"empty";
($t,$b) = $q->stat;
is $t,4, "top";
is $b,4, "bottom";
is $q->length,0,"length";

is $q->push($str200),undef,"push too long";

ok $q->push($str80),"push 80";
($t,$b) = $q->stat;
is $t,4, "top";
is $b,1, "bottom";
is $q->length,7,"length";

ok $q->push($str80),"push 80 once more";
($t,$b) = $q->stat;
is $t,1, "top";
is $b,8, "bottom";
is $q->length,7,"length";

is $q->pop,$str80,"pop long good";
($t,$b) = $q->stat;
is $t,8, "top";
is $b,8, "bottom";
is $q->length,0,"length";

is $q->pop,undef,"overrited";

ok $q->push($str18),"push oversize";
($t,$b) = $q->stat;
is $t,8, "top";
is $b,0, "bottom";
is $q->length,2,"length";

ok $q->push($str6),"push";
($t,$b) = $q->stat;
is $t,8, "top";
is $b,1, "bottom";
is $q->length,3,"length";

is $q->top,$str18,"top";
($t,$b) = $q->stat;
is $t,8, "top";
is $b,1, "bottom";
is $q->length,3,"length";

$q->drop;
($t,$b) = $q->stat;
is $t,0, "top";
is $b,1, "bottom";
is $q->length,1,"length";

is $q->top,$str6,"top";
($t,$b) = $q->stat;
is $t,0, "top";
is $b,1, "bottom";
is $q->length,1,"length";

unlink $file;


