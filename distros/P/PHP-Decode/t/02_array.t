# Tests: array
#
# see: more array tests in decode.t

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More;
use PHP::Decode::Array;
use Data::Dumper;

plan tests => 8;

my $arr = new PHP::Decode::Array();
is($arr->{name}, '#arr1', 'array name');

my $res = $arr->to_str();
is($res, '()', 'array init');

$arr->set(undef, "a");
$res = $arr->to_str();
is($res, "(0 => 'a')", 'array append a');

$arr->set(undef, "b");
$res = $arr->to_str();
is($res, "(0 => 'a', 1 => 'b')", 'array append b');

$arr->set("x", "c");
$res = $arr->to_str();
is($res, "(0 => 'a', 1 => 'b', 'x' => 'c')", 'array set x');

$arr->set("y", new PHP::Decode::Array()->set(undef, "d"));
$res = $arr->to_str();
is($res, "(0 => 'a', 1 => 'b', 'x' => 'c', (0 => 'd'))", 'array set y');

$res = $arr->get("x");
is($res, "c", 'array get x');

my $arr2 = $arr->copy();
$res = $arr2->to_str();
is($res, "(0 => 'a', 1 => 'b', 'x' => 'c', (0 => 'd'))", 'array copy');
