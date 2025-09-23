use strict;
use warnings;

use CSS::Struct::Output::Structure;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Footer;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Footer->new(
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::Footer');

# Test.
$obj = Tags::HTML::Footer->new(
	'css' => CSS::Struct::Output::Structure->new,
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::Footer');

# Test.
eval {
	Tags::HTML::Footer->new(
		'css' => Test::MockObject->new,
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
	Tags::HTML::Footer->new(
		'lang' => 'xxx',
	);
};
is($EVAL_ERROR, "Parameter 'lang' doesn't contain valid ISO 639-2 code.\n",
	"Parameter 'lang' doesn't contain valid ISO 639-2 code.");
clean();

# Test.
eval {
	Tags::HTML::Footer->new(
		'tags' => 0,
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
	Tags::HTML::Footer->new(
		'tags' => Test::MockObject->new,
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
	Tags::HTML::Footer->new(
		'text' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'text' isn't hash reference.\n",
	"Parameter 'text' isn't hash reference (undef).");
clean();

# Test.
eval {
	Tags::HTML::Footer->new(
		'text' => [],
	);
};
is($EVAL_ERROR, "Parameter 'text' isn't hash reference.\n",
	"Parameter 'text' isn't hash reference (reference to array).");
clean();

# Test.
eval {
	Tags::HTML::Footer->new(
		'text' => {},
	);
};
is($EVAL_ERROR, "Parameter 'text' doesn't contain expected keys.\n",
	"Parameter 'text' doesn't contain expected keys (blank text).");
clean();

# Test.
eval {
	Tags::HTML::Footer->new(
		'lang' => 'cze',
		'text' => {
			'cze' => {},
		},
	);
};
is($EVAL_ERROR, "Parameter 'text' doesn't contain expected keys.\n",
	"Parameter 'text' doesn't contain expected keys (blank text->{'cze'}).");
clean();

# Test.
eval {
	Tags::HTML::Footer->new(
		'lang' => 'cze',
		'text' => {
			'cze' => {
				'foo' => 'Foo',
			},
		},
	);
};
is($EVAL_ERROR, "Parameter 'text' doesn't contain expected keys.\n",
	"Parameter 'text' doesn't contain expected keys (foo key, but no version key).");
clean();
