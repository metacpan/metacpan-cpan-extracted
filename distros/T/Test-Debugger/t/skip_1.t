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

plan(tests => 1);

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

skip('if_true', 'value', 'expected', 'to show how to skip a subtest');
