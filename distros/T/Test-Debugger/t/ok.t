# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::Debugger;
# in case you don't have Devel::Messenger installed, I 'require' instead of 'use' it.
eval { require Devel::Messenger; };
if ($@) {
    sub note;
    sub note {};
} else {
    undef &note;
    import Devel::Messenger qw(note);
}
my $note = note { output => 'debug.txt' };
local *Test::Debugger::note = $note if $note;
local *note = $note if $note;

my $t = Test::Debugger->new(
    tests    => 29,
    log_file => 'test.log',
);
$t->param_order('ok' => [qw(self expected actual message error operator)]);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $c = 0;

$c += $t->ok('A','A','equal','error message','eq');
$c += $t->ok('2','2','equal','error message','==');
$c += $t->ok('a','A','not equal','error message','ne');
$c += $t->ok('1','2','not equal','error message','!=');
$c += $t->ok('a','b','greater than','error message','gt');
$c += $t->ok('1','2','greater than','error message','>');
$c += $t->ok('a','a','greater or equal', 'error message', 'ge');
$c += $t->ok('1','1','greater or equal', 'error message', 'ge');
$c += $t->ok('b','a','less than','error message','lt');
$c += $t->ok('2','1','less than','error message','lt');
$c += $t->ok('a','a','less or equal', 'error message', 'le');
$c += $t->ok('1','1','less or equal', 'error message', 'le');
$c += $t->ok('help', 'help me', 'regex', 'error message', 're');
$c += $t->ok('help', 'help me', 'regex', 'error_message', '=~');
$c += $t->ok(qr/help/, 'help me', 'with qr//');

$c += $t->ok(undef(),undef(),'undefs match');

$c += $t->ok_ne('2','1','ok_ne','error message');
$c += $t->ok_gt('a','b','ok_gt','error message');
$c += $t->ok_gt('2','10','ok_gt','error message');
$c += $t->ok_ge('a','b','ok_ge','error message');
$c += $t->ok_ge('2','10','ok_ge','error message');
$c += $t->ok_lt('b','a','ok_lt','error message');
$c += $t->ok_lt('10','2','ok_lt','error message');
$c += $t->ok_le('b','a','ok_le','error message');
$c += $t->ok_le('10','2','ok_le','error message');
$c += $t->ok_re('^help', 'help me', 'ok_re');

$c += $t->ok('A');
$c += $t->ok('1');

$t->ok(28, $c, 'ok returned true for all tests');

