#!/usr/bin/env perl
#
# This test ensures that signal delivery of HUP and USR1 works on this
# platform.  The other tests in this suite depend on signals that work.
#

use strict;
use warnings;
use lib 't/lib';
use My::Test::SignalHandlers;
use Test::More tests => 4;

cmp_ok $HUP, '==', 0;
cmp_ok $USR1, '==', 0;

kill HUP  => $$;
kill USR1 => $$;

cmp_ok $HUP, '==', 1, 'SIGHUP was delivered';
cmp_ok $USR1, '==', 1, 'SIGTERM was delivered';
