use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Page::End;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Page::End->new;
isa_ok($obj, 'Tags::HTML::Page::End');

# Test.
$obj = Tags::HTML::Page::End->new(
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::Page::End');

# Test.
eval {
	Tags::HTML::Page::End->new(
		'tags' => 'foo',
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Missing required parameter 'tags'.",
);
clean();

# Test.
my $mock = Test::MockObject->new;
eval {
	Tags::HTML::Page::End->new(
		'tags' => $mock,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Bad 'Tags::Output' instance.",
);
clean();
