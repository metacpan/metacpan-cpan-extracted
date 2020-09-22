use strict;
use warnings;

use CSS::Struct::Output::Raw;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Page::Begin;
use Tags::Output::Raw;
use Test::More 'tests' => 14;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Page::Begin->new(
	'tags' => Tags::Output::Raw->new,
);
isa_ok($obj, 'Tags::HTML::Page::Begin');

# Test.
$obj = Tags::HTML::Page::Begin->new(
	'css' => CSS::Struct::Output::Raw->new,
	'tags' => Tags::Output::Raw->new,
);
isa_ok($obj, 'Tags::HTML::Page::Begin');

# Test.
eval {
	Tags::HTML::Page::Begin->new;
};
is(
	$EVAL_ERROR,
	"Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Missing required parameter 'tags'.",
);
clean();

# Test.
eval {
	Tags::HTML::Page::Begin->new(
		'tags' => Tags::HTML::Page::Begin->new(
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
	Tags::HTML::Page::Begin->new(
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

# Test.
eval {
	Tags::HTML::Page::Begin->new(
		'script_js' => undef,
		'tags' => Tags::Output::Raw->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'script_js' must be a array.\n",
	"Parameter 'script_js' is undef.",
);
clean();

# Test.
eval {
	Tags::HTML::Page::Begin->new(
		'script_js' => 'foo',
		'tags' => Tags::Output::Raw->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'script_js' must be a array.\n",
	"Parameter 'script_js' is string.",
);
clean();

# Test.
eval {
	Tags::HTML::Page::Begin->new(
		'script_js_src' => undef,
		'tags' => Tags::Output::Raw->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'script_js_src' must be a array.\n",
	"Parameter 'script_js_src' is undef.",
);
clean();

# Test.
eval {
	Tags::HTML::Page::Begin->new(
		'script_js_src' => 'foo',
		'tags' => Tags::Output::Raw->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'script_js_src' must be a array.\n",
	"Parameter 'script_js_src' is string.",
);
clean();

# Test.
eval {
	Tags::HTML::Page::Begin->new(
		'favicon' => 'foo.bmp',
		'tags' => Tags::Output::Raw->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'favicon' contain bad image type.\n",
	"Parameter 'favicon' contain bad image type.",
);
clean();

# Test.
eval {
	Tags::HTML::Page::Begin->new(
		'css_src' => 'foo',
		'tags' => Tags::Output::Raw->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'css_src' must be a array.\n",
	"Parameter 'css_src' is string.",
);
clean();

# Test.
eval {
	Tags::HTML::Page::Begin->new(
		'css_src' => ['foo'],
		'tags' => Tags::Output::Raw->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'css_src' must be a array of hash structures.\n",
	"Parameter 'css_src' is array of strings.",
);
clean();

# Test.
eval {
	Tags::HTML::Page::Begin->new(
		'css_src' => [{'foo' => 'bar'}],
		'tags' => Tags::Output::Raw->new,
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'css_src' must be a array of hash structures with 'media' ".
		"and 'link' keys.\n",
	"Parameter 'css_src' is array of hashes with bad key.",
);
clean();
