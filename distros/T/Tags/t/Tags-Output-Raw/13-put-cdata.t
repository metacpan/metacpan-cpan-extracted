use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Tags::Output::Raw;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'xml' => 1,
);
$obj->put(
	['b', 'element'],
	['cd', 'aaaaa<dddd>dddd'],
	['e', 'element'],
);
my $ret = $obj->flush;
my $right_ret = '<element><![CDATA[aaaaa<dddd>dddd]]></element>';
is($ret, $right_ret);

# Test.
$obj->reset;
eval {
	$obj->put(
		['b', 'element'],
		['cd', 'aaaaa<dddd>dddd', ']]>'],
		['e', 'element'],
	);
};
is($EVAL_ERROR, "Bad CDATA data.\n");
clean();
