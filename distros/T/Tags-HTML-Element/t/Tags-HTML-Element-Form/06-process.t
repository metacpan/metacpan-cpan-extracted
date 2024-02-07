use strict;
use warnings;

use Data::HTML::Element::Button;
use Data::HTML::Element::Form;
use Data::HTML::Element::Input;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Element::Form;
use Tags::Output::Structure;
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Element::Form->new(
	'tags' => $tags,
);
my $form = Data::HTML::Element::Form->new(
	'css_class' => 'form',
);
$obj->init($form);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form'],
		['a', 'method', 'get'],
		['e', 'form'],
	],
	'Form HTML code (blank).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::Form->new(
	'tags' => $tags,
);
$form = Data::HTML::Element::Form->new(
	'css_class' => 'form',
	'label' => 'Form label',
);
$obj->init($form);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form'],
		['a', 'method', 'get'],
		['b', 'fieldset'],
		['b', 'legend'],
		['d', 'Form label'],
		['e', 'legend'],
		['e', 'fieldset'],
		['e', 'form'],
	],
	'Form HTML code (blank with form label).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::Form->new(
	'tags' => $tags,
);
$form = Data::HTML::Element::Form->new(
	'css_class' => 'form',
	'data' => [
		['d', 'Check box'],
		['b', 'input'],
		['a', 'name', 'check'],
		['a', 'type', 'checkbox'],
		['e', 'input'],
	],
	'data_type' => 'tags',
);
$obj->init($form);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form'],
		['a', 'method', 'get'],
		['d', 'Check box'],
		['b', 'input'],
		['a', 'name', 'check'],
		['a', 'type', 'checkbox'],
		['e', 'input'],
		['e', 'form'],
	],
	'Form HTML code (with checkbox inside by Tags).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::Form->new(
	'tags' => $tags,
);
$form = Data::HTML::Element::Form->new(
	'css_class' => 'form',
	'data' => [sub {
		$tags->put(
			['d', 'Check box'],
			['b', 'input'],
			['a', 'name', 'check'],
			['a', 'type', 'checkbox'],
			['e', 'input'],
		);
	}],
	'data_type' => 'cb',
);
$obj->init($form);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form'],
		['a', 'method', 'get'],
		['d', 'Check box'],
		['b', 'input'],
		['a', 'name', 'check'],
		['a', 'type', 'checkbox'],
		['e', 'input'],
		['e', 'form'],
	],
	'Form HTML code (with checkbox inside by callback).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Element::Form->new(
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Form HTML code (nothing, without init).',
);

# Test.
$obj = Tags::HTML::Element::Form->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n",
	"Parameter 'tags' isn't defined.");
clean();
