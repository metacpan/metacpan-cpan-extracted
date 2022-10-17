use strict;
use warnings;

use Data::HTML::Form::Input;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Form::Input;
use Tags::Output::Structure;
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Form::Input->new(
	'tags' => $tags,
);
my $input = Data::HTML::Form::Input->new(
	'value' => 'Custom save',
	'type' => 'submit',
);
$obj->process($input);
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'input'],
		['a', 'type', 'submit'],
		['a', 'value', 'Custom save'],
		['e', 'input'],
	],
	'Input HTML code (submit button).',
);

# Test
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Form::Input->new(
	'tags' => $tags,
);
$input = Data::HTML::Form::Input->new(
	'checked' => 0,
	'type' => 'checkbox',
);
$obj->process($input);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'input'],
		['a', 'type', 'checkbox'],
		['e', 'input'],
	],
	'Input HTML code (checkbox).',
);

# Test.
$obj = Tags::HTML::Form::Input->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n",
	"Parameter 'tags' isn't defined.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Form::Input->new(
	'tags' => $tags,
);
eval {
	$obj->process('bad');
};
is($EVAL_ERROR, "Input object must be a 'Data::HTML::Form::Input' instance.\n",
	"Input object must be a 'Data::HTML::Form::Input' instance.");
clean();
