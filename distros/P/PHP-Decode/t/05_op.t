# Tests: op
#
# see: more op tests in decode.t

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::More;
use PHP::Decode::Parser;
use PHP::Decode::Op;

plan tests => 6;

sub warn_msg {
	my ($action, $fmt) = (shift, shift);
	my $msg = sprintf $fmt, @_;
	print 'WARN: ', $action, ': ', $msg, "\n";
}

my %strmap;
my $parser = PHP::Decode::Parser->new(strmap => \%strmap, warn => \&warn_msg);
isnt($parser, undef, 'op init');

my $val1 = $parser->setnum('2');
my $val2 = $parser->setnum('3');
my $res = PHP::Decode::Op::binary($parser, $val1, '+', $val2);
is($res, '5', 'op binary + val');

my $val = $parser->setnum($res);
$res = PHP::Decode::Op::unary($parser, '-', $val);
is($res, '-5', 'op unary - val');

my $arr1 = $parser->newarr();
my $arr2 = $parser->newarr();
$arr1->set(undef, $val1);
$arr2->set(undef, $val2);
$res = PHP::Decode::Op::array_compare($parser, $arr1->{name}, $arr2->{name});
is($res, -1, 'op array compare');

$res = PHP::Decode::Op::array_is_const($parser, $arr1->{name});
is($res, 1, 'op array is_const');

my $num = PHP::Decode::Op::to_num('-6');
is($num, -6, 'op to_num');

