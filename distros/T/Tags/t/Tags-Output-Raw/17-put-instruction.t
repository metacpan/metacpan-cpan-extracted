use strict;
use warnings;

use Tags::Output::Raw;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new;
$obj->put(
	['i', 'perl', 'print "1\n";'],
);
my $ret = $obj->flush;
is($ret, '<?perl print "1\n";?>', 'Simple perl instruction.');

# Test.
$obj->reset;
$obj->put(
	['i', 'perl'],
);
$ret = $obj->flush;
is($ret, '<?perl?>', 'Perl instruction without code.');

# Test.
$obj->reset;
$obj->put(
	['b', 'element'],
	['i', 'perl', 'print "1\n";'],
	['e', 'element'],
);
$ret = $obj->flush;
is($ret, '<element><?perl print "1\n";?></element>',
	'Instruction inside element.');
