use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg);
use Tags::HTML::Tree;
use Test::MockObject;
use Test::More 'tests' => 15;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Tree->new;
isa_ok($obj, 'Tags::HTML::Tree');

# Test.
eval {
	Tags::HTML::Tree->new(
		'css' => 'bad_css',
	);
};
is($EVAL_ERROR, "Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class (bad string).");
clean();

# Test.
eval {
	Tags::HTML::Tree->new(
		'css' => 0,
	);
};
is($EVAL_ERROR, "Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class (bad number).");
clean();

# Test.
my $test_obj = Test::MockObject->new;
eval {
	Tags::HTML::Tree->new(
		'css' => $test_obj,
	);
};
is($EVAL_ERROR, "Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class (bad object).");
clean();

# Test.
eval {
	Tags::HTML::Tree->new(
		'css_class' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'css_class' is required.\n",
	"Parameter 'css_class' is required.");
clean();

# Test.
eval {
	Tags::HTML::Tree->new(
		'css_class' => '@foo',
	);
};
is($EVAL_ERROR, "Parameter 'css_class' has bad CSS class name.\n",
	"Parameter 'css_class' has bad CSS class name (\@foo).");
clean();

# Test.
eval {
	Tags::HTML::Tree->new(
		'css_class' => '1foo',
	);
};
is($EVAL_ERROR, "Parameter 'css_class' has bad CSS class name (number on begin).\n",
	"Parameter 'css_class' has bad CSS class name (number on begin) (1foo).");
clean();

# Test.
eval {
	Tags::HTML::Tree->new(
		'indent' => 'bad',
	);
};
my @error = err_msg();
is_deeply(
	\@error,
	[
		"Parameter 'indent' doesn't contain unit number.",
		'Value',
		'bad',
	],
	"Parameter 'indent' doesn't contain unit number (bad).",
);
clean();

# Test.
eval {
	Tags::HTML::Tree->new(
		'indent' => '100',
	);
};
@error = err_msg();
is_deeply(
	\@error,
	[
		"Parameter 'indent' doesn't contain unit name.",
		'Value',
		'100',
	],
	"Parameter 'indent' doesn't contain unit name (100).",
);
clean();

# Test.
eval {
	Tags::HTML::Tree->new(
		'indent' => '100xx',
	);
};
@error = err_msg();
is_deeply(
	\@error,
	[
		"Parameter 'indent' contain bad unit.",
		'Unit',
		'xx',
		'Value',
		'100xx',
	],
	"Parameter 'indent' contain bad unit (100xx).",
);
clean();

# Test.
eval {
	Tags::HTML::Tree->new(
		'tags' => 'bad_tags',
	);
};
is($EVAL_ERROR, "Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class (bad string).");
clean();

# Test.
eval {
	Tags::HTML::Tree->new(
		'tags' => 0,
	);
};
is($EVAL_ERROR, "Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class (bad number).");
clean();

# Test.
$test_obj = Test::MockObject->new;
eval {
	Tags::HTML::Tree->new(
		'tags' => $test_obj,
	);
};
is($EVAL_ERROR, "Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class (bad object)");
clean();

# Test.
eval {
	Tags::HTML::Tree->new(
		'xxx' => 'value',
	);
};
is($EVAL_ERROR, "Unknown parameter 'xxx'.\n",
	"Unknown parameter 'xxx'.");
clean();
