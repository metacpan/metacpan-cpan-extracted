#!perl -T
use warnings;
use strict;

use Test::More tests => 18;
use Carp;

use lib qw( t t/lib ./lib );

    package TestConst;
    use base qw(Package::Data::Inheritable);
    BEGIN {
        TestConst->pkg_inheritable('$b' => 'bbb');
        TestConst->pkg_const_inheritable('$a' => 'aaa');
        TestConst->pkg_const_inheritable('$c' => 'ccc');
        TestConst->pkg_inheritable('$d' => 'ddd');
    }

    package DerivedConst;
    use base qw(TestConst);
    BEGIN {
        inherit TestConst;
        DerivedConst->pkg_inheritable('$c' => 'CCC');       # was const, becomes non const
        DerivedConst->pkg_const_inheritable('$d' => 'DDD'); # was non const, becomes const
    }

package main;

sub throws_ok(&$$);
sub lives_ok(&$);

is($TestConst::b,    'bbb', "Checking non const value");
is($TestConst::a,    'aaa', "Checking const value");
is($DerivedConst::b, 'bbb', "Checking derived non const value");
is($DerivedConst::a, 'aaa', "Checking derived const value");
is($DerivedConst::c, 'CCC', "Checking derived redefined non const value");
is($DerivedConst::d, 'DDD', "Checking derived redefined const value");

throws_ok { $TestConst::a    = "boom" } qr/Modification of a read-only value attempted/, "Checking constantness";
lives_ok  { $TestConst::b    = "boom" } "Checking constantness";
throws_ok { $TestConst::c    = "boom" } qr/Modification of a read-only value attempted/, "Checking constantness";
throws_ok { $DerivedConst::a = "boom" } qr/Modification of a read-only value attempted/, "Checking derived constantness";
lives_ok  { $DerivedConst::c = "boom" } "Checking derived constantness";
lives_ok  { $TestConst::d    = "boom" } "Checking constantness";
throws_ok { $DerivedConst::d = "boom" } qr/Modification of a read-only value attempted/, "Checking derived constantness";

throws_ok { TestConst->pkg_const_inheritable('@array') } qr/not a scalar/i, "Checking non scalars";
throws_ok { TestConst->pkg_const_inheritable('%array') } qr/not a scalar/i, "Checking non scalars";
throws_ok { TestConst->pkg_const_inheritable('&array') } qr/not a scalar/i, "Checking non scalars";
throws_ok { TestConst->pkg_const_inheritable('*array') } qr/not a scalar/i, "Checking non scalars";
throws_ok { TestConst->pkg_const_inheritable('array')  } qr/no sigil/i, "Checking non scalars";


######################################################################
# TEST UTILITIES

# throws_ok { $foo->method3 } qr/division by zero/, 'zero caught okay';
sub throws_ok(&$$) {
    my ($code, $rexp, $message) = @_;

    eval {
        $code->();
    };
    if (not $@) {
        is("No error", $rexp, $message);
    }
    else {
        like($@, $rexp, $message);
    }

}

# lives_ok { $foo->method3 } qr/division by zero/, 'zero caught okay';
sub lives_ok(&$) {
    my ($code, $message) = @_;

    eval {
        $code->();
    };
    if ($@) {
        fail("died: $@");
    }
    pass($message);
}

