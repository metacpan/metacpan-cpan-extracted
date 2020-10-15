use strict;
use warnings;

use Tags::Output::Raw;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'xml' => 0,
);
my $text = <<"END";
  text
     text
	text
END
$obj->put(['b', 'MAIN'], ['b', 'CHILD1'], 
	['a', 'xml:space', 'default'], ['d', $text],
	['e', 'CHILD1'], ['e', 'MAIN']);
my $ret = $obj->flush;
my $right_ret = '<MAIN><CHILD1 xml:space="default">'.$text.'</CHILD1></MAIN>';
is($ret, $right_ret, 'SGML preserving test (default).');

# Test.
$obj = Tags::Output::Raw->new(
	'xml' => 1,
);
$obj->put(['b', 'main'], ['b', 'child1'], 
	['a', 'xml:space', 'default'], ['d', $text],
	['e', 'child1'], ['e', 'main']);
$ret = $obj->flush;
$right_ret = '<main><child1 xml:space="default">'.$text.'</child1></main>';
is($ret, $right_ret, 'XML preserving test (default).');

# TODO
SKIP: {
	skip 'Need check.', 1;
$obj = Tags::Output::Raw->new;
$obj->put(['b', 'MAIN'], ['b', 'CHILD1'], 
	['a', 'xml:space', 'preserve'], ['d', $text],
	['e', 'CHILD1'], ['e', 'MAIN']);
$ret = $obj->flush;
print "$ret\n";
$right_ret = "<MAIN><CHILD1 xml:space=\"preserve\">\n$text</CHILD1></MAIN>";
is($ret, $right_ret, 'SGML preserving test (preserve)');
};

# TODO Pridat vnorene testy.
# Bude jich hromada. Viz. ex18.pl az ex24.pl v Tags::Output::Indent.
