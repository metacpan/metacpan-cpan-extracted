use strict;
use warnings;

use CSS::Struct::Output::Structure;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::SendMessage;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::SendMessage->new(
	'css' => CSS::Struct::Output::Structure->new,
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::SendMessage');

# Test.
my $mock = Test::MockObject->new;
eval {
	Tags::HTML::SendMessage->new(
		'css' => $mock,
		'tags' => Tags::Output::Structure->new,
	);
};
is($EVAL_ERROR, "Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class (other object).");
clean();

# Test.
$mock = Test::MockObject->new;
eval {
	Tags::HTML::SendMessage->new(
		'css' => CSS::Struct::Output::Structure->new,
		'tags' => $mock,
	);
};
is($EVAL_ERROR, "Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class (other object).");
clean();

# Test.
eval {
	Tags::HTML::SendMessage->new(
		'css' => CSS::Struct::Output::Structure->new,
		'tags' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class (undef).");
clean();
