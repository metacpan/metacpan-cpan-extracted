# Pragmas.
use strict;
use warnings;

# Modules.
use Tags::Output;
use Test::More 'tests' => 2;
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
