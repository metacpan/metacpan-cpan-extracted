use strict;
use OpenGL qw(GL_FLOAT GL_INT GL_UNSIGNED_BYTE);
use Test::More tests => 141;

my $o1 = OpenGL::Array->new(5, GL_FLOAT);
ok($o1, "O::A->new");
is($o1->elements, 5, '$o1->elements');
ok($o1->length, '$o1->length');

my $o2 = OpenGL::Array->new(5, GL_INT, GL_INT, GL_INT, GL_INT, GL_INT);
ok($o2, "O::A->new");
is($o2->elements, 25, '$o2->elements');
ok($o2->length, '$o->length');

###----------------------------------------------------------------###

sub init { OpenGL::Array->new_list(GL_FLOAT, 1..9) }

sub fmt {
   my @val = ref($_[0]) ? $_[0]->retrieve(0, $_[0]->elements) : @_;
   push @val, 0 while @val < 9;
   return sprintf "%2d %2d %2d    %2d %2d %2d    %2d %2d %2d", @val;
}

sub lfmt { qr/^ \d  \d  \d     \d  \d  \d     \d  \d  \d$/ }

$o1 = init();
$o2 = init();
ok($o1, "O::A->new_list");
is(fmt($o1), fmt(1,2,3,4,5,6,7,8,9), '$o1->retrieve');
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->retrieve');

$o1->assign(2, 7);
is(fmt($o1), fmt(1,2,7,4,5,6,7,8,9), '$o1->assign(2,7)');

###----------------------------------------------------------------###

my $ptr = $o2->ptr();
ok($ptr, '$o2->ptr()');
$o1 = OpenGL::Array->new_pointer(GL_FLOAT, $ptr, 4);
ok($o1, 'O::A->new_pointer');
is(fmt($o1), fmt(1,2,3,4,0,0,0,0,0), '$o1->retrieve');

$o2->assign(2, 7);
is(fmt($o1), fmt(1,2,7,4,0,0,0,0,0), '$o1->assign(2,7)');
is(fmt($o2), fmt(1,2,7,4,5,6,7,8,9), '$o1->assign(2,7)');

$o1->assign(1, 7);
is(fmt($o1), fmt(1,7,7,4,0,0,0,0,0), '$o1->assign(2,7)');
is(fmt($o2), fmt(1,7,7,4,5,6,7,8,9), '$o1->assign(2,7)');

$ptr = $o2->offset(5);
ok($ptr, '$o2->offset(5)');
$o1 = OpenGL::Array->new_pointer(GL_FLOAT, $ptr, 4);
ok($o1, 'O::A->new_pointer');
is(fmt($o1), fmt(6,7,8,9,0,0,0,0,0), '$o1->retrieve');

$o1->update_pointer($o2->ptr());
is(fmt($o1), fmt(1,7,7,4,0,0,0,0,0), '$o1->update_pointer($o2->ptr())');

###----------------------------------------------------------------###

$o2 = OpenGL::Array->new_list(GL_UNSIGNED_BYTE, 1..9);
$o1 = OpenGL::Array->new_from_pointer($o2->ptr(), 9);
ok($o1, 'O::A->new_from_pointer');
is(fmt($o1), fmt(1,2,3,4,5,6,7,8,9), '$o1->new_from_pointer');

$o2->assign(2, 7);
is(fmt($o1), fmt(1,2,7,4,5,6,7,8,9), '$o1->assign(2,7)');
is(fmt($o2), fmt(1,2,7,4,5,6,7,8,9), '$o1->assign(2,7)');

$o1->assign(1, 7);
is(fmt($o1), fmt(1,7,7,4,5,6,7,8,9), '$o1->assign(2,7)');
is(fmt($o2), fmt(1,7,7,4,5,6,7,8,9), '$o1->assign(2,7)');

###----------------------------------------------------------------###

my $str = pack 'C*', 1..9;
$o1 = OpenGL::Array->new_scalar(GL_UNSIGNED_BYTE,$str,length($str));
is(fmt($o1), fmt(1,2,3,4,5,6,7,8,9), '$o1->new_scalar');

###----------------------------------------------------------------###

ok($o1->can('bind'), 'can ->bind');
ok(!$o1->bound, '$o1->bound()');

###----------------------------------------------------------------###

# affine
my $left   = -800;
my $right  = 800;
my $bottom = -100;
my $top    = 100;
my $zFar   = 5;
my $zNear  = -5;

my $A =  2 / ($right - $left);
my $B =  2 / ($top   - $bottom);
my $C = -2 / ($zFar   - $zNear);
my $tx = -($right + $left) / ($right - $left);
my $ty = -($top + $bottom) / ($top - $bottom);
my $tz = -($zFar + $zNear) / ($zFar - $zNear);

$o2 = OpenGL::Array->new_list(GL_FLOAT,
   $A, 0,  0,  $tx,
   0,  $B, 0,  $ty,
   0,  0,  $C, $tz,
   0, 0,   0,  1);

$o1 = OpenGL::Array->new_list(GL_FLOAT, 1, 1, 0);
$o1->affine($o2);
$o1->calc('1000,*');
is(fmt($o1), fmt(1,10,0,0,0,0,0,0,0), '$o1->affine($o2)');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o1->calc(1);
is(fmt($o1), fmt(1,1,1,1,1,1,1,1,1), '$o1->calc(1)');

$o1->calc(1,2,3);
is(fmt($o1), fmt(1,2,3,1,2,3,1,2,3), '$o1->calc(1,2,3)');

ok(!eval { $o1->calc(1,2,3,4) }, "Correctly failed because column count wasn't a divisor of total elements");

###----------------------------------------------------------------###

$o1->calc(1);
$o1->assign_data(0, $o2->retrieve_data(0,$o2->length));
is(fmt($o1), fmt(1,2,3,4,5,6,7,8,9), "retrieve_data / assign_data (all)");

my $size = $o2->length / $o2->elements;
for my $i (1 .. $o2->elements) {
   $o1->calc(1);
   $o1->assign_data($i - 1, $o2->retrieve_data($i - 1, $size));
   my @test = (1) x $o2->elements;
   $test[$i-1] = $i;
   is(fmt($o1), fmt(@test), "retrieve_data / assign_data (".($i-1).")");
}

###----------------------------------------------------------------###

$o1->calc(0,4,1,-1,4,0,2,2,4);
$o1->calc('!');
is(fmt($o1), fmt(1,0,0,0,0,1,0,0,0), '$o1->calc("!")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o1->calc("-");
is(fmt($o1), fmt(-1,-2,-3,-4,-5,-6,-7,-8,-9), '$o1->calc("-")');
$o1->calc("1,-");
is(fmt($o1), fmt(-1,-1,-1,-1,-1,-1,-1,-1,-1), '$o1->calc("1,-")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("+");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("+")');
$o1->calc("1,+");
is(fmt($o1), fmt(2,3,4,5,6,7,8,9,10), '$o1->calc("1,+")');

$o1 = init();
$o2 = init();
$o2->calc("or");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("or")');
$o1->calc("1,or");
is(fmt($o1), fmt(2,3,4,5,6,7,8,9,10), '$o1->calc("1,or")');

$o1 = init();
$o2 = init();
$o2->calc(3);
$o1->calc($o2, "+");
is(fmt($o1), fmt(4,5,6,7,8,9,10,11,12), '$o1->calc($o2, "+")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("*");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("*")');
$o1->calc("2,*");
is(fmt($o1), fmt(2,4,6,8,10,12,14,16,18), '$o1->calc("2,*")');

$o1 = init();
$o2 = init();
$o2->calc("and");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("and")');
$o1->calc("2,and");
is(fmt($o1), fmt(2,4,6,8,10,12,14,16,18), '$o1->calc("2,and")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("/");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("/")');
$o1->calc("3,/");
is(fmt($o1), fmt(0,0,1,1,1,2,2,2,3), '$o1->calc("3,/") # S1 / S0');
is(sprintf('%.2f',$o1->retrieve(3,1)), '1.33', '$o1->calc("3,/")');

$o1 = init();
$o2 = init();
$o1->calc("3,/,floor");
is(fmt($o1), fmt(0,0,1,1,1,2,2,2,3), '$o1->calc("3,/,floor") # S1 / S0');
is(sprintf('%.2f',$o1->retrieve(3,1)), '1.00', '$o1->calc("3,/,floor")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("%");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("%")');
$o1->calc("3,%");
is(fmt($o1), fmt(1,2,0,1,2,0,1,2,0), '$o1->calc("3,%") # S1 % S0');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("=");
is(fmt($o2), fmt(0,0,0,0,0,0,0,0,0), '$o2->calc("=")');
$o1->calc("3,=");
is(fmt($o1), fmt(0,0,1,0,0,0,0,0,0), '$o1->calc("3,=")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc(">");
is(fmt($o2), fmt(1,1,1,1,1,1,1,1,1), '$o2->calc(">")');
$o1->calc("3,>");
is(fmt($o1), fmt(1,1,0,0,0,0,0,0,0), '$o1->calc("3,>") # S0 > S1');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("<");
is(fmt($o2), fmt(0,0,0,0,0,0,0,0,0), '$o2->calc("<")');
$o1->calc("3,<");
is(fmt($o1), fmt(0,0,0,1,1,1,1,1,1), '$o1->calc("3,<") # S0 < S1');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc('7,swap');
is(fmt($o1), fmt(1,2,3,4,5,6,7,8,9), '$o1->calc("7,swap")');
$o2->calc('7,swap,swap');
is(fmt($o2), fmt(7,7,7,7,7,7,7,7,7), '$o2->calc("7,swap,swap")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc('7,swap,pop');
is(fmt($o2), fmt(7,7,7,7,7,7,7,7,7), '$o2->calc("7,swap,pop")');
$o2->calc('7,swap,swap,pop');
is(fmt($o1), fmt(1,2,3,4,5,6,7,8,9), '$o1->calc("7,swap,swap,pop")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("dup");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("dup")');
$o1->calc("dup,+");
is(fmt($o1), fmt(2,4,6,8,10,12,14,16,18), '$o1->calc("dup,+")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("dec");
is(fmt($o2), fmt(0,1,2,3,4,5,6,7,8), '$o2->calc("dec")');

$o2->calc("inc");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("inc")');

### ---------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("dec,4,swap,3,swap,2,swap,?"); # dec will introduce a zero
is(fmt($o2), fmt(2,3,3,3,3,3,3,3,3), '$o1->calc("dec,4,swap,3,swap,2,swap,?")');
$o1->calc("inc,4,swap,3,swap,2,swap,?");
is(fmt($o1), fmt(3,3,3,3,3,3,3,3,3), '$o1->calc("inc,4,swap,3,swap,2,swap,?")');

$o1 = init();
$o2 = init();
$o2->calc("dec,4,swap,3,swap,2,swap,if"); # dec will introduce a zero
is(fmt($o2), fmt(2,3,3,3,3,3,3,3,3), '$o1->calc("dec,4,swap,3,swap,2,swap,if")');
$o1->calc("inc,4,swap,3,swap,2,swap,if");
is(fmt($o1), fmt(3,3,3,3,3,3,3,3,3), '$o1->calc("inc,4,swap,3,swap,2,swap,if")');

###----------------------------------------------------------------###

$o1->calc('10,rand,*');
like(fmt($o1), lfmt(), '$o1->calc("10,rand,*")');


###----------------------------------------------------------------###

TODO: {
   local $TODO = 'OpenGL::Array tests under development';

   $o2 = init();
   $o2->calc('get,+,set');
   is(fmt($o2), fmt(1,3,6,10,15,21,28,36,45), '$o2->calc("get,+,set")');

   $o1 = init();
   $o1->calc('get,+,set', '', '');
   is(fmt($o1), fmt(1,2,3,5,5,6,12,8,9), '$o1->calc("get,+,set","","")');
}

###----------------------------------------------------------------###

$o1 = init();
$o1->calc("2,colget", "", "");
is(fmt($o1), fmt(3,2,3,6,5,6,9,8,9), '$o1->calc("2,colget", "", "")');

$o1 = init();
$o1->calc('2,colset', '', '');
is(fmt($o1), fmt(1,2,1,4,5,4,7,8,7), '$o1->calc("2,colset", "", "")');

$o1 = init();
$o1->calc("1,2,rowget", "2,1,rowget", "");
is(fmt($o1), fmt(6,8,3,6,8,6,6,8,9), '$o1->calc("1,2,rowget", "2,1,rowget", ""');

$o1 = init();
$o1->calc("1,2,rowset", "2,1,rowset", "0,0,rowset");
is(fmt($o1), fmt(9,2,3,4,5,7,7,5,9), '$o1->calc("1,2,rowset", "2,1,rowset", "0,0,rowset")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
my $o3 = init();
my $o4 = init();
$o2->calc('-10,+');
$o3->calc('10,+');
$o4->calc('27');
$o1->calc("0,store,get","get","get");
is(fmt($o1), fmt(1,2,3,4,5,6,7,8,9), '$o1->calc("0,store,get","get","get")');
$o1->calc($o2,$o3,$o4,"0,store,get","get","get");
is(fmt($o1), fmt(1,2,3,4,5,6,7,8,9), '$o1->calc($o2,$o3,$o4,"0,store,get","get","get")');
$o1->calc($o2,$o3,$o4,"1,store",'','');
is(fmt($o1), fmt(1,2,3,4,5,6,7,8,9), '$o1->calc($o2,$o3,$o4,"1,store","","")');
$o1->calc($o2,$o3,$o4,"1,store,get",'','get');
is(fmt($o1), fmt(-9,2,-7,-6,5,-4,-3,8,-1), '$o1->calc($o2,$o3,$o4,"1,store,get","","get")');
$o1->calc($o2,$o3,$o4,"2,store,get");
is(fmt($o1), fmt(11,12,13,14,15,16,17,18,19), '$o1->calc($o2,$o3,$o4,"2,store,get")');
$o1->calc($o2,$o3,$o4,"3,store,get");
is(fmt($o1), fmt(27,27,27,27,27,27,27,27,27), '$o1->calc($o2,$o3,$o4,"3,store,get")');

$o1 = init();
$o2->assign(0, 7, 8 ,9,  10, 11, 12,  13, 14, 15);
$o1->calc($o2, "1,store,get","","get");
is(fmt($o1), fmt(7, 2, 9,  10, 5, 12,  13, 8, 15), '$o1->calc($o2, "1,store,get","","get")');

$o2 = init();
$o2->calc('-10,+');
is(fmt($o2), fmt(-9,-8,-7,-6,-5,-4,-3,-2,-1), '$o1->calc("-10,+")');
$o1 = init();
$o1->calc($o2,$o3,$o4,"","","0,store,1,load");
is(fmt($o1), fmt(1,2,3,4,5,6,7,8,9), '$o1->calc("","","0,store,1,load")');
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o1->calc("","","0,store,1,load")');
$o1->calc($o2,$o3,$o4,"","","2,store,3,load");
is(fmt($o1), fmt(1,2,3,4,5,6,7,8,9), '$o1->calc($o2,$o3,$o4,"","","2,store,3,load")');
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o1->calc($o2,$o3,$o4,"","","2,store,3,load")');
is(fmt($o3), fmt(11,12,13,14,15,16,17,18,19), '$o1->calc($o2,$o3,$o4,"","","2,store,3,load")');
is(fmt($o4), fmt(11,12,13,14,15,16,17,18,19), '$o1->calc($o2,$o3,$o4,"","","2,store,3,load")');

TODO: {

   local $TODO = 'OpenGL::Array tests under development';

   $o1 = init();
   $o2->assign(0, 7, 8 ,9,  10, 11, 12,  13, 14, 15);
   $o1->calc($o2, "set","", "set,1,load");
   is(fmt($o2), fmt(1, 0, 3,  4, 0, 6,  7, 0, 9), '$o1->calc($o2, "set","", "set,1,store")');
}

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc(3,"5,end,8",'');
is(fmt($o2), fmt(3,2,3,3,5,6,3,8,9), '$o2->calc(3,"5,end,8","")');

$o1 = init();
$o2 = init();
$o2->calc(3,"5,end,8",9);
is(fmt($o2), fmt(3,2,9,3,5,9,3,8,9), '$o2->calc(3,"5,end,8",9)');

$o1 = init();
$o2 = init();
$o2->calc(3,"5,return,8",'');
is(fmt($o2), fmt(3,5,3,3,5,6,3,5,9), '$o2->calc(3,"5,return,8","")');

$o1 = init();
$o2 = init();
$o2->calc(3,"5,return,8",9);
is(fmt($o2), fmt(3,5,9,3,5,9,3,5,9), '$o2->calc(3,"5,return,8",9)');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc(3,"5,1,endif,8",'');
is(fmt($o2), fmt(3,2,3,3,5,6,3,8,9), '$o2->calc(3,"5,1,endif,8","")');

$o1 = init();
$o2 = init();
$o2->calc(3,"5,0,endif,8",'');
is(fmt($o2), fmt(3,8,3,3,8,6,3,8,9), '$o2->calc(3,"5,0,endif,8","")');

$o1 = init();
$o2 = init();
$o2->calc(3,"5,1,returnif,8",'');
is(fmt($o2), fmt(3,5,3,3,5,6,3,5,9), '$o2->calc(3,"5,1,returnif,8","")');

$o1 = init();
$o2 = init();
$o2->calc(3,"5,0,returnif,8",'');
is(fmt($o2), fmt(3,8,3,3,8,6,3,8,9), '$o2->calc(3,"5,0,returnif,8","")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc(3,"5,endrow,8",9);
is(fmt($o2), fmt(3,2,3,3,5,6,3,8,9), '$o2->calc(3,"5,endrow,8",9)');

$o1 = init();
$o2 = init();
$o2->calc(3,"5,returnrow,8",9);
is(fmt($o2), fmt(3,5,3,3,5,6,3,5,9), '$o2->calc(3,"5,returnrow,8",9)');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc(3,"5,1,endrowif,8",9);
is(fmt($o2), fmt(3,2,3,3,5,6,3,8,9), '$o2->calc(3,"5,1,endrowif,8",9)');

$o1 = init();
$o2 = init();
$o2->calc(3,"5,0,endrowif,8",9);
is(fmt($o2), fmt(3,8,9,3,8,9,3,8,9), '$o2->calc(3,"5,0,endrowif,8",9)');

$o1 = init();
$o2 = init();
$o2->calc(3,"5,1,returnrowif,8",9);
is(fmt($o2), fmt(3,5,3,3,5,6,3,5,9), '$o2->calc(3,"5,1,returnrowif,8",9)');

$o1 = init();
$o2 = init();
$o2->calc(3,"5,0,returnrowif,8",9);
is(fmt($o2), fmt(3,8,9,3,8,9,3,8,9), '$o2->calc(3,"5,0,returnrowif,8",9)');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("sum");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("sum")');
$o2->calc("1,2,sum");
is(fmt($o2), fmt(4,5,6,7,8,9,10,11,12), '$o2->calc("1,2,sum")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("avg");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("avg")');
$o2->calc("5,avg");
is(fmt($o2), fmt(3,3,4,4,5,5,6,6,7), '$o2->calc("5,avg")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("-,abs");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("-,abs")');
$o2->calc(-3);
$o2->calc('abs');
is(fmt($o2), fmt(3,3,3,3,3,3,3,3,3), '$o2->calc("abs")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("power");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("power")');

$o1->calc("2,power");
is(fmt($o1), fmt(1,4,9,16,25,36,49,64,81), '$o1->calc("2,power")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("min");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("min")');

$o1->calc("5,min");
is(fmt($o1), fmt(1,2,3,4,5,5,5,5,5), '$o2->calc("5,min")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("max");
is(fmt($o2), fmt(1,2,3,4,5,6,7,8,9), '$o2->calc("max")');

$o1->calc("5,max");
is(fmt($o1), fmt(5,5,5,5,5,6,7,8,9), '$o2->calc("5,max")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("pi");
ok((9 == grep {$_ =~ /^3\.14159\d+$/} $o2->retrieve(0,9)), '$o2->calc("pi")');

# this test may fail if the system floats have less that 6 digits of precision
$o1->calc("dec,6,min,10,swap,power,pi,*,10,%");
# decrement
# take a digit
# make sure it is less than 6
# raise 10 to that digit
# multiply by pi
# mod 10 to get that digit of pi
is(fmt($o1), fmt(3,1,4,1,5,9,2,2,2), '$o2->calc("dec,6,min,10,swap,power,pi,*,10,%")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("10,/,pi,*,sin,10,*"); # sin in 10 degree increments
is(fmt($o2), fmt(3,5,8,9,10,9,8,5,3), '$o2->calc("10,/,pi,*,sin,10,*")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("10,/,pi,*,cos,10,*"); # cos in 10 degree increments
is(fmt($o2), fmt(9,8,5,3,0,-3,-5,-8,-9), '$o2->calc("10,/,pi,*,cos,10,*")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("10,/,pi,*,tan,10,*,abs,100,min"); # tan in 10 degree increments
is(fmt($o2), fmt(3,7,13,30,100,30,13,7,3), '$o2->calc("10,/,pi,*,tan,10,*,abs,100,min")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("1,swap,atan2,400,*,dup,0,swap,300,<,?"); # 3 digits of pie
is(fmt($o2), fmt(314,0,0,0,0,0,0,0,0), '$o2->calc("1,swap,atan2,400,*,dup,0,swap,300,<,?")');

###----------------------------------------------------------------###

$o1 = init();
$o2 = init();
$o2->calc("count","count","count");
is(fmt($o2), fmt(9,9,9,9,9,9,9,9,9), '$o2->calc("count","count","count")');

$o2->calc("index","index","index");
is(fmt($o2), fmt(0,1,2,3,4,5,6,7,8), '$o2->calc("index","index","index")');

$o2->calc("columns","columns","columns");
is(fmt($o2), fmt(3,3,3,3,3,3,3,3,3), '$o2->calc("columns","columns","columns")');

$o2->calc("column","column","column");
is(fmt($o2), fmt(0,1,2,0,1,2,0,1,2), '$o2->calc("column","column","column")');

$o2->calc("rows","rows","rows");
is(fmt($o2), fmt(3,3,3,3,3,3,3,3,3), '$o2->calc("rows","rows","rows")');

$o2->calc("row","row","row");
is(fmt($o2), fmt(0,0,0,1,1,1,2,2,2), '$o2->calc("row","row","row")');

###----------------------------------------------------------------###
