use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::InfoBox;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::InfoBox->new;
isa_ok($obj, 'Tags::HTML::InfoBox');

# Test.
$obj = Tags::HTML::InfoBox->new(
	'tags' => Tags::Output::Structure->new,
);
isa_ok($obj, 'Tags::HTML::InfoBox');

# Test.
eval {
	Tags::HTML::InfoBox->new(
		'tags' => 'bad_tags',
	);
};
is($EVAL_ERROR, "Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class (bad string).");
clean();

# Test.
eval {
	Tags::HTML::InfoBox->new(
		'tags' => 0,
	);
};
is($EVAL_ERROR, "Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class (bad number).");
clean();

# Test.
my $test_obj = Test::MockObject->new;
eval {
	Tags::HTML::InfoBox->new(
		'tags' => $test_obj,
	);
};
is($EVAL_ERROR, "Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class (bad object)");
clean();

# Test.
eval {
	Tags::HTML::InfoBox->new(
		'css' => 'bad_css',
	);
};
is($EVAL_ERROR, "Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class (bad string).");
clean();

# Test.
eval {
	Tags::HTML::InfoBox->new(
		'css' => 0,
	);
};
is($EVAL_ERROR, "Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class (bad number).");
clean();
