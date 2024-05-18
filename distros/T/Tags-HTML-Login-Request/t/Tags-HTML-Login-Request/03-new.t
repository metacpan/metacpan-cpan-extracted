use strict;
use warnings;

use CSS::Struct::Output::Structure;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Login::Request;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 14;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Login::Request->new(
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::Login::Request');

# Test.
$obj = Tags::HTML::Login::Request->new(
	'css' => CSS::Struct::Output::Structure->new,
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::Login::Request');

# Test.
eval {
	Tags::HTML::Login::Request->new(
		'css' => Test::MockObject->new,
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
	Tags::HTML::Login::Request->new(
		'lang' => 'xxx',
	);
};
is($EVAL_ERROR, "Parameter 'lang' doesn't contain valid ISO 639-2 code.\n",
	"Parameter 'lang' doesn't contain valid ISO 639-2 code.");
clean();

# Test.
eval {
	Tags::HTML::Login::Request->new(
		'form_method' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'form_method' has bad value.\n",
	"Parameter 'form_method' has bad value.");
clean();

# Test.
eval {
	Tags::HTML::Login::Request->new(
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
	Tags::HTML::Login::Request->new(
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
	Tags::HTML::Login::Request->new(
		'text' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'text' is required.\n",
	"Parameter 'text' is required.");
clean();

# Test.
eval {
	Tags::HTML::Login::Request->new(
		'text' => [],
	);
};
is($EVAL_ERROR, "Parameter 'text' must be a hash with language texts.\n",
	"Parameter 'text' must be a hash with language texts.");
clean();

# Test.
eval {
	Tags::HTML::Login::Request->new(
		'text' => {},
	);
};
is($EVAL_ERROR, "Texts for language 'eng' doesn't exist.\n",
	"Texts for language 'eng' doesn't exist.");
clean();

# Test.
eval {
	Tags::HTML::Login::Request->new(
		'width' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'width' doesn't contain unit number.\n",
	"Parameter 'width' doesn't contain unit number (foo).");
clean();

# Test.
eval {
	Tags::HTML::Login::Request->new(
		'width' => '123',
	);
};
is($EVAL_ERROR, "Parameter 'width' doesn't contain unit name.\n",
	"Parameter 'width' doesn't contain unit name (123).");
clean();

# Test.
eval {
	Tags::HTML::Login::Request->new(
		'width' => '123xx',
	);
};
is($EVAL_ERROR, "Parameter 'width' contain bad unit.\n",
	"Parameter 'width' contain bad unit (123xx).");
clean();
