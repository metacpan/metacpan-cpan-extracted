#!perl

use strict;
use warnings;
use lib './lib';
use Test::More;

plan tests => 23;

use Net::ISC::DHCPd::Types qw/:all/;

my @required_types = qw/
    HexInt Ip Mac State Time Statements FailoverState
    ConfigObject LeasesObject OMAPIObject ProcessObject
/;
my @types = Net::ISC::DHCPd::Types->get_type_list;

is_deeply(\@required_types, \@types, "all types defined");

ok(!is_State(""), "invalid State");
ok(is_State("expired"), "valid State");
is(to_State(1), "free", "valid coerced State");

ok(!is_HexInt("abc"), "invalid HexInt");
ok(is_HexInt(123), "valid HexInt");
is(to_HexInt("aa:12"), 43538, "valid coerced HexInt");

ok(!is_Time("abc"), "invalid Time");
ok(is_Time(123), "valid Time");
is(to_Time("aa:12"), 43538, "valid coerced Time");

ok(!is_Mac("qwerty"), "invalid Mac");
ok(is_Mac("11:22:33:44:55:66"), "valid Mac");
ok(is_Mac("0:0:c0:5d:bd:95"), "valid mac with single digits");  # gh#18
ok(is_Mac("0:0:c0:5d:BD:95"), "valid mac (uppercase)");
is(to_Mac("1122.3344.5566"), "11:22:33:44:55:66", "valid coerced Mac");
is(to_Mac("11-22-33-44-55-66"), "11:22:33:44:55:66", "valid coerced Mac");
is(to_Mac("112233445566"), "11:22:33:44:55:66", "valid coerced Mac");

ok(!is_Ip("abcde"), "invalid Ip");
ok(is_Ip("127.1"), "valid Ip");
is(to_Ip("7f:1"), "127.1", "valid coerced Ip");

ok(!is_Statements("hello-world"), "invalid Statements");
ok(is_Statements("foo,bar"), "valid Statements");
is(to_Statements([qw/foo bar/]), "foo,bar", "valid coerced Statements");

