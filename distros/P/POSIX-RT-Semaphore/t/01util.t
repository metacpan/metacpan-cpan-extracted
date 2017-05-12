#! /usr/bin/perl
#
# 01util.t
#
# Make sure util.pl does what we want.
#

use Test::More tests => 10;
use Errno qw(ENOSYS ENXIO);
use strict;

# Test::More <= 0.51 explodes on require_ok("t/util.pl"), so we
# do it the hard way:  supply a prototype for proper parsing of
# the below (otherwise is_impl {block} is taken as an OO call),
# and eval the require.

sub is_implemented(&); # defined *is_impl{CODE}, !defined &is_impl;

eval { require 't/util.pl'; };

ok(!$@, "require 't/util.pl'");

ok(defined &is_implemented, "is_implemented defined");
ok(defined &zero_but_true, "zero_but_true defined");
ok(defined &make_semname, "make_semname defined");

my $v = undef;
$! = &ENXIO;
SKIP: {
	skip "expected skip", 1
		unless is_implemented { $v = "foo"; $! = &ENOSYS; };

	fail("fell through!");
}

ok($v eq "foo", "$v was set");
ok($! == &ENXIO, "errno not altered");

SKIP: {
	skip "no skip", 1
		unless is_implemented { $v = "bar"; };

	pass("no skip supported");
}

ok($v eq "bar", "$v was set");
ok($! == &ENXIO, "errno not altered");
