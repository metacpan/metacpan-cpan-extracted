use strict;
use warnings;

use Tags::Output;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output->new;
$obj->put(
	['b', 'element'],
	['d', 'data section'],
);
$obj->finalize;
my $ret = $obj->flush;
my $right_ret = <<'END';
Begin of tag
Data
End of tag
END
chomp $right_ret;
is($ret, $right_ret, 'Simple test of finalize of element.');

# Test.
$obj = Tags::Output->new;
$obj->put(
	['b', 'element'],
	['d', 'data section'],
	['b', 'second'],
);
$obj->finalize;
$ret = $obj->flush;
$right_ret = <<'END';
Begin of tag
Data
Begin of tag
End of tag
End of tag
END
chomp $right_ret;
is($ret, $right_ret, 'Finalize two elements.');
