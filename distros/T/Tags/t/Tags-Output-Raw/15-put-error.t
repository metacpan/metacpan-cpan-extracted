use strict;
use warnings;

use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Tags::Output::Raw;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Tags::Output::Raw->new(
	'xml' => 1,
);
eval {
	$obj->put(['b', 'ELEMENT']);
};
is($EVAL_ERROR, "In XML must be lowercase tag name.\n");
clean();

# Test.
$obj->reset;
eval {
	$obj->put(['b', 'element'], ['b', 'element2'], ['e', 'element']);
};
is($EVAL_ERROR, "Ending bad tag: 'element' in block of tag 'element2'.\n");
clean();

# Test.
$obj->reset;
eval {
	$obj->put(['a', 'key', 'val']);
};
is($EVAL_ERROR, 'Bad tag type \'a\'.'."\n");
clean();

# Test.
$obj->reset;
eval {
	$obj->put(['q', 'key', 'val']);
};
is($EVAL_ERROR, 'Bad type of data.'."\n");
clean();

# Test.
$obj->reset;
eval {
	$obj->put('q');
};
is($EVAL_ERROR, 'Bad data.'."\n");
clean();
