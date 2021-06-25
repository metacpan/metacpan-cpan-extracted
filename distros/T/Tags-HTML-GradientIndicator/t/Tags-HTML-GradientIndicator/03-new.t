use strict;
use warnings;

use CSS::Struct::Output::Raw;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::GradientIndicator;
use Tags::Output::Raw;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::GradientIndicator->new(
	'tags' => Tags::Output::Raw->new,
);
isa_ok($obj, 'Tags::HTML::GradientIndicator');

# Test.
$obj = Tags::HTML::GradientIndicator->new(
	'css' => CSS::Struct::Output::Raw->new,
	'tags' => Tags::Output::Raw->new,
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
			'tags' => Tags::Output::Raw->new,
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
		'css' => Tags::Output::Raw->new,
		'tags' => Tags::Output::Raw->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Bad 'CSS::Struct::Output' instance.",
);
clean();
