#!/usr/bin/perl

package Some::Test::Package;

use strict;
use warnings;

use Test::More tests => 13;

my $m;
BEGIN { use_ok($m = "Package::Relative") }

ok(__PACKAGE__->can("PKG"), "PKG() exported");

isa_ok(PKG, $m, "PKG");

can_ok($m, "stringify");
is(PKG->stringify, __PACKAGE__, "stringify method works");
is(PKG, __PACKAGE__, "pretty much the same as __PACKAGE__");

can_ok($m, "concat");
is(PKG . "::Foo", __PACKAGE__ . "::Foo", "Concat subpackage");
is(PKG . "Foo", __PACKAGE__ . "::Foo", "Concat subpackage without colons");
is(PKG . "..::Foo", "Some::Test::Foo", "concat relative package");

my $pkg = PKG;
is("Foo::${pkg}::..::Bar", "Foo::Some::Test::Bar", "reversed argument order is handled");

is(PKG . "..::Foo" . "..::Bar", "Some::Test::Foo..::Bar", "concat returns a plain string when object is LHS");

is(PKG . ("..::Foo::" . "..::Bar"), "Some::Test::Bar", "parenthesized workaround works as advertized");

