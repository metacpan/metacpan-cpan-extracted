#!perl

use strict;
use warnings;
use Test::More tests => 20;

use No::Worries::Export qw(export_control);

#
# exporting module
#

package e;
{
    use constant C => "c00l";
    our $s = "scalar";
    our @a = (0 .. 3);
    our %h = ("key" => "val");
    sub f () { return("foo") }
    sub import : method {
	my($pkg, %exported);
	$pkg = shift(@_);
	grep($exported{$_}++, qw(C f $s @a %h));
	::export_control(scalar(caller()), $pkg, \%exported, @_);
    }
}

#
# importing module
#

package i;
{
    no strict;
    no warnings qw(once);

    ::ok(!defined(&C),             "before - constant");
    ::ok(!defined(&f),             "before - function");
    ::ok(!defined($s),             "before - scalar");
    ::ok(!scalar(@a),              "before - array");
    ::ok(!scalar(%h),              "before - hash");

    e->import("*");

    ::ok(defined(&C),              "after - constant");
    ::ok(defined(&f),              "after - function");
    ::ok(defined($s),              "after - scalar");
    ::ok(scalar(@a),               "after - array");
    ::ok(scalar(%h),               "after - hash");

    ::is(C(), "c00l",              "test - constant");
    ::is(f(), "foo",               "test - function");
    ::is($s, "scalar",             "test - scalar");
    ::is(scalar(@a), 4,            "test - array");
    ::is(join("",keys(%h)), "key", "test - hash");
}

#
# outside
#

package main;
{
    no strict;
    no warnings qw(once);

    ok(!defined(&C),             "outside - constant");
    ok(!defined(&f),             "outside - function");
    ok(!defined($s),             "outside - scalar");
    ok(!scalar(@a),              "outside - array");
    ok(!scalar(%h),              "outside - hash");
}
