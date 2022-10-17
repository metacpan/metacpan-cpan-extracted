use strict;
use warnings;

use Data::HTML::Form;
use Data::HTML::Form::Input;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Form;
use Tags::Output::Raw;
use Test::More 'tests' => 13;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Form->new;
isa_ok($obj, 'Tags::HTML::Form');

# Test.
$obj = Tags::HTML::Form->new(
	'tags' => Tags::Output::Raw->new,
);
isa_ok($obj, 'Tags::HTML::Form');

# Test.
eval {
	Tags::HTML::Form->new(
		'form' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'form' is required.\n",
	"Parameter 'form' is required.");
clean();

# Test.
eval {
	Tags::HTML::Form->new(
		'form' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'form' must be a 'Data::HTML::Form' instance.\n",
	"Parameter 'form' must be a 'Data::HTML::Form' instance.");
clean();

# Test.
eval {
	Tags::HTML::Form->new(
		'form' => Data::HTML::Form->new,
	);
};
is($EVAL_ERROR, "Parameter 'form' must define 'css_class' parameter.\n",
	"Parameter 'form' must define 'css_class' parameter.");
clean();

# Test.
eval {
	Tags::HTML::Form->new(
		'submit' => undef,
	);
};
is($EVAL_ERROR, "Parameter 'submit' is required.\n",
	"Parameter 'submit' is required.");
clean();

# Test.
eval {
	Tags::HTML::Form->new(
		'submit' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'submit' must be a 'Data::HTML::Form::Input' instance.\n",
	"Parameter 'submit' must be a 'Data::HTML::Form::Input' instance.");
clean();

# Test.
eval {
	Tags::HTML::Form->new(
		'submit' => Data::HTML::Form::Input->new(
			'type' => 'text',
		),
	);
};
is($EVAL_ERROR, "Parameter 'submit' instance has bad type.\n",
	"Parameter 'submit' instance has bad type.");
clean();

# Test.
eval {
	Tags::HTML->new(
		'tags' => 'bad_tags',
	);
};
is($EVAL_ERROR, "Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class.");
clean();

# Test.
eval {
	Tags::HTML->new(
		'tags' => 0,
	);
};
is($EVAL_ERROR, "Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Parameter 'tags' must be a 'Tags::Output::*' class.");
clean();

# Test.
eval {
	Tags::HTML->new(
		'css' => 'bad_css',
	);
};
is($EVAL_ERROR, "Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class.");
clean();

# Test.
eval {
	Tags::HTML->new(
		'css' => 0,
	);
};
is($EVAL_ERROR, "Parameter 'css' must be a 'CSS::Struct::Output::*' class.\n",
	"Parameter 'css' must be a 'CSS::Struct::Output::*' class.");
clean();
