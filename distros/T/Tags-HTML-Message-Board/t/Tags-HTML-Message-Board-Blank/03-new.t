use strict;
use warnings;

use CSS::Struct::Output::Structure;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Message::Board::Blank;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Message::Board::Blank->new(
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::Message::Board::Blank');

# Test.
$obj = Tags::HTML::Message::Board::Blank->new(
	'css' => CSS::Struct::Output::Structure->new,
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::Message::Board::Blank');

# Test.
eval {
	Tags::HTML::Message::Board::Blank->new(
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
	Tags::HTML::Message::Board::Blank->new(
		'lang' => 'xxx',
	);
};
is($EVAL_ERROR, "Parameter 'lang' doesn't contain valid ISO 639-2 code.\n",
	"Parameter 'lang' doesn't contain valid ISO 639-2 code.");
clean();

# Test.
eval {
	Tags::HTML::Message::Board::Blank->new(
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
	Tags::HTML::Message::Board::Blank->new(
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
	Tags::HTML::Message::Board::Blank->new(
		'text' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'text' is required.\n",
	"Parameter 'text' is required.");
clean();

# Test.
eval {
	Tags::HTML::Message::Board::Blank->new(
		'text' => [],
	);
};
is($EVAL_ERROR, "Parameter 'text' must be a hash with language texts.\n",
	"Parameter 'text' must be a hash with language texts.");
clean();

# Test.
eval {
	Tags::HTML::Message::Board::Blank->new(
		'text' => {},
	);
};
is($EVAL_ERROR, "Texts for language 'eng' doesn't exist.\n",
	"Texts for language 'eng' doesn't exist.");
clean();

# Test.
eval {
	Tags::HTML::Message::Board::Blank->new(
		'lang' => 'cze',
		'text' => {
			'cze' => {},
		},
	);
};
is($EVAL_ERROR, "Number of texts isn't same as expected.\n",
	"Number of texts isn't same as expected (no translations for cze).");
clean();

# Test.
eval {
	Tags::HTML::Message::Board::Blank->new(
		'lang' => 'cze',
		'text' => {
			'cze' => {
				'foo' => 'Foo',
				'bar' => 'Bar',
			},
		},
	);
};
is($EVAL_ERROR, "Text for lang 'cze' and key 'add_message_board' doesn't exist.\n",
	"Text for lang 'cze' and key 'add_message_board' doesn't exist (no right translations).");
clean();
