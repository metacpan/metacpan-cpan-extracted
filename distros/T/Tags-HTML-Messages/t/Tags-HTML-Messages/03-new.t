use strict;
use warnings;

use CSS::Struct::Output::Raw;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Messages;
use Tags::Output::Raw;
use Test::More 'tests' => 10;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Tags::HTML::Messages->new(
	'tags' => Tags::Output::Raw->new,
);
isa_ok($obj, 'Tags::HTML::Messages');

# Test.
$obj = Tags::HTML::Messages->new(
	'css' => CSS::Struct::Output::Raw->new,
	'tags' => Tags::Output::Raw->new,
);
isa_ok($obj, 'Tags::HTML::Messages');

# Test.
$obj = Tags::HTML::Messages->new(
	'css' => CSS::Struct::Output::Raw->new,
	'lang' => 'cze',
	'tags' => Tags::Output::Raw->new,
	'text' => {
		'cze' => {
			'no_messages' => decode_utf8('Nejsou žádné zprávy'),
		},
	},
);
isa_ok($obj, 'Tags::HTML::Messages');

# Test.
eval {
	Tags::HTML::Messages->new(
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
	Tags::HTML::Messages->new(
		'lang' => 'xxx',
	);
};
is($EVAL_ERROR, "Parameter 'lang' doesn't contain valid ISO 639-2 code.\n",
	"Parameter 'lang' doesn't contain valid ISO 639-2 code (xxx).");
clean();

# Test.
eval {
	Tags::HTML::Messages->new(
		'tags' => Tags::HTML::Messages->new(
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
	Tags::HTML::Messages->new(
		'text' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'text' isn't hash reference.\n",
	"Parameter 'text' isn't hash reference (bad).");
clean();

# Test.
eval {
	Tags::HTML::Messages->new(
		'text' => {},
	);
};
is($EVAL_ERROR, "Parameter 'text' doesn't contain expected keys.\n",
	"Parameter 'text' doesn't contain expected keys ({}).");
clean();

# Test.
eval {
	Tags::HTML::Messages->new(
		'lang' => 'cze',
		'text' => {
			'cze' => {},
		},
	);
};
is($EVAL_ERROR, "Parameter 'text' doesn't contain expected keys.\n",
	"Parameter 'text' doesn't contain expected keys ({'cze' => {}}).");
clean();
