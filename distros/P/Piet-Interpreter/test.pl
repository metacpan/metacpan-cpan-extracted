#!/usr/local/bin/perl -w

use Test;
BEGIN { plan tests => 39, onfail => sub { print "\n*** Tests failed! ***\n" } };
END   { print "not ok 1\n" unless $loaded }

use Image::Magick;
ok(1);

use Piet::Interpreter;
$loaded = 1;

my $h = Piet::Interpreter->new(codel_size => 10,
                               image      => 'testimg/hello2big.gif', );
print "\nRunning hello:\n";
print "Codel size = $h->{_codel_size}, ";
ok($h->codel_size,10);
$h->run;
ok(1);

print "\nRunning count:\n";
my $p = Piet::Interpreter->new;
$p->image('testimg/count.gif');
$p->run;

ok(1);

print "\nTesting PVM state:\n";

#  testimg/count.gif  (10 x 18)
#    Codel Size:  1
#    Step:  0   CX:  5   CY:  5   DP:  3   CC:  -1
#    Last color:  light red
#    Stack:  10,32

print "File = $p->{_filename}, ";
ok($p->filename,'testimg/count.gif');
print "Cols = $p->{_cols}, ";
ok($p->cols,10);
print "Rows = $p->{_rows}, ";
ok($p->rows,18);

print "CX = $p->{_cx}, ";
ok($p->{_cx},5);
print "CY = $p->{_cy}, ";
ok($p->{_cy},5);
print "DP = $p->{_dp}, ";
ok($p->{_dp},3);
print "CC = $p->{_cc}, ";
ok($p->{_cc},-1);

print "Last Color = $p->{_last_color}, ";
ok($p->{_last_color},'FFC0C0');

print "Stack = ";
$stack = join",",$p->_stack;
ok($stack, '10,32');


print "\nTesting reset:\n";

$p->reset;

ok($p->{_cx},0);
ok($p->{_cy},0);
ok($p->{_dp},0);
ok($p->{_cc},-1);
ok($p->{_last_color},'FF0000');
ok($p->_stack,0);

print "\nTesting step:\n";
for (1..6) { $p->step; print '.' }

#  testimg/count.gif  (10 x 18)
#    Codel Size:  1
#    Step:  6   CX:  9   CY:  2   DP:  1   CC:  1
#    Last color:  blue
#    Stack:  1,0

ok($p->{_cx},9);
ok($p->{_cy},2);
ok($p->{_dp},1);
ok($p->{_cc},1);
ok($p->{_last_color},'0000FF');
$stack = join",",$p->_stack;
ok($stack,'1,0');

print "\nTesting operations:\n";
$p->reset;

print "push ";
$p->do_push(3);
$p->do_push(6);
$p->do_push(9);
$stack = join",",$p->_stack;
ok($stack,'3,6,9');

print "pop ";
$p->do_pop;
$stack = join",",$p->_stack;
ok($stack,'3,6');

print "add ";
$p->do_add;
$stack = join",",$p->_stack;
ok($stack,'9');

print "subtract ";
$p->do_push(4);
$p->do_subtract;
$stack = join",",$p->_stack;
ok($stack,'5');

print "multiply ";
$p->do_push(8);
$p->do_multiply;
$stack = join",",$p->_stack;
ok($stack,'40');

print "divide ";
$p->do_push(10);
$p->do_divide;
$stack = join",",$p->_stack;
ok($stack,'4');

print "mod ";
$p->do_push(3);
$p->do_mod;
$stack = join",",$p->_stack;
ok($stack,'1');

print "not ";
$p->do_not;
$stack = join",",$p->_stack;
ok($stack,'0');

print "greater ";
$p->do_push(10);
$p->do_push(6);
$p->do_greater;
$stack = join",",$p->_stack;
ok($stack,'0,1');

print "pointer ";
$p->do_push(7);
$p->do_pointer;
ok($p->{_dp},3);

print "switch ";
$p->do_push(5);
$p->do_switch;
ok($p->{_cc},1);

print "duplicate ";
$p->do_duplicate;
$p->do_duplicate;
$stack = join",",$p->_stack;
ok($stack,'0,1,1,1');

print "roll ";
$p->do_pop;
$p->do_pop;
$p->do_pop;
$p->do_pop;

$p->do_push(1);
$p->do_push(2);
$p->do_push(3);
$p->do_push(4);
$p->do_push(3);
$p->do_push(2);
$stack = join",",$p->_stack;
ok($stack,'1,2,3,4,3,2');
$p->do_roll;
$stack = join",",$p->_stack;
ok($stack,'1,3,4,2');

#  todo:  in_n, in_c, out_n, out_c
#  todo:  add more tests for internal methods
#  todo:  add tests for nonstandard = black
#  todo:  ad more tests for faily conditions
