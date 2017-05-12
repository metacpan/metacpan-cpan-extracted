# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test::Debugger;
plan(
    'skip'         => (1 == 1),
    'skip_message' => 'to show how to skip a test',
    'tests'        => 4, # not really, just want to verify where we get our numbers
);
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

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

ok('A','A','equal','error message');
ok('2','2','equal','error message');
ok('a','A','not equal','error message','ne');
ok('1','2','not equal','error message','!=');
