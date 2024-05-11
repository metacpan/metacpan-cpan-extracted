use strict;
use warnings;

use CSS::Struct::Output::Structure;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Navigation::Grid;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Navigation::Grid->new;
isa_ok($obj, 'Tags::HTML::Navigation::Grid');

# Test.
$obj = Tags::HTML::Navigation::Grid->new(
	'css' => CSS::Struct::Output::Structure->new,
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::Navigation::Grid');

# Test.
eval {
	Tags::HTML::Navigation::Grid->new(
		'css' => 'foo',
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class (foo).",
);
clean();

# Test.
eval {
	Tags::HTML::Navigation::Grid->new(
		'css' => Test::MockObject->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class (bad instance).",
);
clean();

# Test.
eval {
	Tags::HTML::Navigation::Grid->new(
		'tags' => 'foo',
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class (foo).",
);
clean();

# Test.
eval {
	Tags::HTML::Navigation::Grid->new(
		'tags' => Test::MockObject->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class (bad instance).",
);
clean();

# Test.
eval {
	Tags::HTML::Navigation::Grid->new(
		'css_class' => undef,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'css_class' is required.\n",
	"Parameter 'css_class' is required.",
);
clean();
