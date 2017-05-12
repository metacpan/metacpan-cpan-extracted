#!/usr/bin/perl

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

plan ( 
    tests => 4,
    todo => [1,2],
    log_file => 'test.log',
);
Test::Debugger::param_order('ok' => [qw(expected actual message)]);

ok(1, 0, 'should fail as TODO'); # see 'todo' parameter of 'plan'
ok(1, 1, 'should "unexpectedly succeed"');
todo(1, 1, 'should "unexpectedly succeed" (second time)');
todo(1, 0, 'should fail as second TODO');

