use strict;
use warnings;

use CSS::Struct::Output::Raw;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::GradientIndicator;
use Tags::Output::Structure;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::GradientIndicator->new(
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::GradientIndicator');

# Test.
$obj = Tags::HTML::GradientIndicator->new(
	'css' => CSS::Struct::Output::Raw->new,
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::GradientIndicator');

# Test.
eval {
	Tags::HTML::GradientIndicator->new;
};
is(
	$EVAL_ERROR,
	"Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Missing required parameter 'tags'.",
);
clean();

# Test.
eval {
	Tags::HTML::GradientIndicator->new(
		'tags' => Tags::HTML::GradientIndicator->new(
			'tags' => Tags::Output::Structure->new,
		),
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Bad 'Tags::Output' instance.",
);
clean();

# Test.
eval {
	Tags::HTML::GradientIndicator->new(
		'css' => Tags::Output::Structure->new,
		'tags' => Tags::Output::Structure->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Bad 'CSS::Struct::Output' instance.",
);
clean();

# Test.
eval {
	Tags::HTML::GradientIndicator->new(
		'tags' => Tags::Output::Structure->new,
		'height' => 'foo',
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'height' doesn't contain number.\n",
	"Parameter 'height' doesn't contain number (foo).",
);
clean();

# Test.
eval {
	Tags::HTML::GradientIndicator->new(
		'tags' => Tags::Output::Structure->new,
		'height' => '123',
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'height' doesn't contain unit.\n",
	"Parameter 'height' doesn't contain unit (123).",
);
clean();

# Test.
eval {
	Tags::HTML::GradientIndicator->new(
		'tags' => Tags::Output::Structure->new,
		'height' => '123xx',
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'height' contain bad unit.\n",
	"Parameter 'height' contain bad unit (123xx).",
);
clean();

# Test.
eval {
	Tags::HTML::GradientIndicator->new(
		'tags' => Tags::Output::Structure->new,
		'width' => 'foo',
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'width' doesn't contain number.\n",
	"Parameter 'width' doesn't contain number (foo).",
);
clean();

# Test.
eval {
	Tags::HTML::GradientIndicator->new(
		'tags' => Tags::Output::Structure->new,
		'width' => '123',
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'width' doesn't contain unit.\n",
	"Parameter 'width' doesn't contain unit (123).",
);
clean();

# Test.
eval {
	Tags::HTML::GradientIndicator->new(
		'tags' => Tags::Output::Structure->new,
		'width' => '123xx',
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'width' contain bad unit.\n",
	"Parameter 'width' contain bad unit (123xx).",
);
clean();
