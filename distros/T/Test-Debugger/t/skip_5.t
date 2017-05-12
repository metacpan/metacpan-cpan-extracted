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
    tests    => 6,
    log_file => 'test.log',
);
$t->param_order('ok' => [qw(self expected actual message error operator)]);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $c = 0;

$c += $t->ok_skip('0');
$c += $t->ok_skip('');
$c += $t->ok_skip(undef());
$c += $t->ok_skip(undef(),'undef','undef imposter is exposed!');
$c += $t->ok_skip(qr/help/, 'no thank you', 'failed regex');

$t->ok(5, $c, 'ok returned true for all tests');

