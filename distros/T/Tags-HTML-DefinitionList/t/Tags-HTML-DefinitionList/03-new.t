use strict;
use warnings;

use CSS::Struct::Output::Structure;
use English;
use Error::Pure::Utils qw(clean err_msg);
use Tags::HTML::DefinitionList;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 15;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::DefinitionList->new;
isa_ok($obj, 'Tags::HTML::DefinitionList');

# Test.
$obj = Tags::HTML::DefinitionList->new(
	'css' => CSS::Struct::Output::Structure->new,
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::DefinitionList');

# Test.
eval {
	Tags::HTML::DefinitionList->new(
		'css_class' => '@foo',
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'css_class' has bad CSS class name.\n",
	'Parameter \'css_class\' has bad CSS class name (@bad).',
);
clean();

# Test.
eval {
	Tags::HTML::DefinitionList->new(
		'css_class' => '1foo',
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'css_class' has bad CSS class name (number on begin).\n",
	"Parameter 'css_class' has bad CSS class name (number on begin) (1foo).",
);
clean();

# Test.
eval {
	Tags::HTML::DefinitionList->new(
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
	Tags::HTML::DefinitionList->new(
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
	Tags::HTML::DefinitionList->new(
		'dd_left_padding' => 'bad',
	);
};
my @error = err_msg();
is_deeply(
	\@error,
	[
		"Parameter 'dd_left_padding' doesn't contain unit number.",
		'Value',
		'bad',
	],
	"Parameter 'dd_left_padding' doesn't contain unit number.",
);
clean();

# Test.
eval {
	Tags::HTML::DefinitionList->new(
		'dd_left_padding' => '100',
	);
};
@error = err_msg();
is_deeply(
	\@error,
	[
		"Parameter 'dd_left_padding' doesn't contain unit name.",
		'Value',
		'100',
	],
	"Parameter 'dd_left_padding' doesn't contain unit name.",
);
clean();

# Test.
eval {
	Tags::HTML::DefinitionList->new(
		'dd_left_padding' => '100xx',
	);
};
@error = err_msg();
is_deeply(
	\@error,
	[
		"Parameter 'dd_left_padding' contain bad unit.",
		'Unit',
		'xx',
		'Value',
		'100xx',
	],
	"Parameter 'dd_left_padding' contain bad unit.",
);
clean();

# Test.
eval {
	Tags::HTML::DefinitionList->new(
		'dt_width' => 'bad',
	);
};
@error = err_msg();
is_deeply(
	\@error,
	[
		"Parameter 'dt_width' doesn't contain unit number.",
		'Value',
		'bad',
	],
	"Parameter 'dt_width' doesn't contain unit number.",
);
clean();

# Test.
eval {
	Tags::HTML::DefinitionList->new(
		'dt_width' => '100',
	);
};
@error = err_msg();
is_deeply(
	\@error,
	[
		"Parameter 'dt_width' doesn't contain unit name.",
		'Value',
		'100',
	],
	"Parameter 'dt_width' doesn't contain unit name.",
);
clean();

# Test.
eval {
	Tags::HTML::DefinitionList->new(
		'dt_width' => '100xx',
	);
};
@error = err_msg();
is_deeply(
	\@error,
	[
		"Parameter 'dt_width' contain bad unit.",
		'Unit',
		'xx',
		'Value',
		'100xx',
	],
	"Parameter 'dt_width' contain bad unit.",
);
clean();

# Test.
eval {
	Tags::HTML::DefinitionList->new(
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
eval {
	Tags::HTML::DefinitionList->new(
		'tags' => Test::MockObject->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Bad 'Tags::Output' instance.",
);
clean();
