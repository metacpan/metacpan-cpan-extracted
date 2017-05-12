#! perl

use strict;
use warnings;

use Test::More 0.88;
use List::Util qw/first/;

# we need a META.json to do anything
ok(first { -e $_ } qw/MYMETA.json MYMETA.yml META.json META.yml/, 'META.* found')
	or diag 'this test requires a built dist - you must run "dzil test"';

use Test::CheckDeps;

check_dependencies('recommends');

done_testing;
# vim: set ts=2 sw=2 noet nolist :
