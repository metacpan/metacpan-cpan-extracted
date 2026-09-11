#!perl
use 5.010;
use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('Shared::Arena') || print "Bail out!\n" }

ok(defined &Shared::Arena::have_atomics, 'the atomics probe is reachable');

diag("Shared::Arena $Shared::Arena::VERSION, Perl $], $^X, atomics="
   . (Shared::Arena::have_atomics() ? 'yes' : 'no'));
