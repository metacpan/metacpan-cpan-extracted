use strict;
use warnings;

use Tags::Output;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output->new;
$obj->put(
	['a', 'key', 'val'],
	['b', 'element'],
	['c', 'comment'],
	['cd', 'cdata section'],
	['d', 'data section'],
	['e', 'element'],
	['i', 'target', 'code'],
	['r', 'raw data'],
);
my $ret = $obj->flush;
my $right_ret = <<'END';
Attribute
Begin of tag
Comment
CData
Data
End of tag
Instruction
Raw data
END
chomp $right_ret;
is($ret, $right_ret, 'Simple test of all elements.');

# Test.
my $struct_hr = {};
$obj = Tags::Output->new(
	'input_tags_item_callback' => sub {
		my $tags_ar = shift;
		if (! exists $struct_hr->{$tags_ar->[0]}) {
			$struct_hr->{$tags_ar->[0]} = 0;
		}
		$struct_hr->{$tags_ar->[0]}++;
		return;
	},
);
$obj->put(
	['a', 'key', 'val'],
	['b', 'element'],
	['c', 'comment'],
	['cd', 'cdata section'],
	['d', 'data section'],
	['e', 'element'],
	['i', 'target', 'code'],
	['r', 'raw data'],
);
$ret = $obj->flush;
is_deeply(
	$struct_hr,
	{
		'a' => 1,
		'b' => 1,
		'c' => 1,
		'cd' => 1,
		'd' => 1,
		'e' => 1,
		'i' => 1,
		'r' => 1,
	},
	"Count of all 'Tags' items."
);
