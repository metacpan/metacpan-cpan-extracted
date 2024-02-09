use strict;
use warnings;

use Data::Message::Simple;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Login::Register;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Login::Register->new(
	'tags' => $tags,
);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form-register'],
		['a', 'method', 'post'],
		['b', 'fieldset'],

		['b', 'legend'],
		['d', 'Register'],
		['e', 'legend'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'username'],
		['d', 'User name'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'text'],
		['a', 'name', 'username'],
		['a', 'id', 'username'],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password1'],
		['d', 'Password #1'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'password1'],
		['a', 'id', 'password1'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password2'],
		['d', 'Password #2'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'password2'],
		['a', 'id', 'password2'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'button'],
		['a', 'type', 'submit'],
		['a', 'name', 'register'],
		['a', 'value', 'register'],
		['d', 'Register'],
		['e', 'button'],
		['e', 'p'],

		['e', 'fieldset'],
		['e', 'form'],
	],
	'Default registering form without messages.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Login::Register->new(
	'tags' => $tags,
);
$obj->process([]);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form-register'],
		['a', 'method', 'post'],
		['b', 'fieldset'],

		['b', 'legend'],
		['d', 'Register'],
		['e', 'legend'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'username'],
		['d', 'User name'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'text'],
		['a', 'name', 'username'],
		['a', 'id', 'username'],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password1'],
		['d', 'Password #1'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'password1'],
		['a', 'id', 'password1'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password2'],
		['d', 'Password #2'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'password2'],
		['a', 'id', 'password2'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'button'],
		['a', 'type', 'submit'],
		['a', 'name', 'register'],
		['a', 'value', 'register'],
		['d', 'Register'],
		['e', 'button'],
		['e', 'p'],

		['e', 'fieldset'],
		['e', 'form'],
	],
	'Default registering form without messages (blank message array).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Login::Register->new(
	'tags' => $tags,
);
my $messages_ar = [
	Data::Message::Simple->new(
		'text' => 'This is message.',
	),
	Data::Message::Simple->new(
		'lang' => 'cs',
		'text' => 'Toto je zpráva.',
	),
];
$obj->process($messages_ar);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form-register'],
		['a', 'method', 'post'],
		['b', 'fieldset'],

		['b', 'legend'],
		['d', 'Register'],
		['e', 'legend'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'username'],
		['d', 'User name'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'text'],
		['a', 'name', 'username'],
		['a', 'id', 'username'],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password1'],
		['d', 'Password #1'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'password1'],
		['a', 'id', 'password1'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password2'],
		['d', 'Password #2'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'password2'],
		['a', 'id', 'password2'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'button'],
		['a', 'type', 'submit'],
		['a', 'name', 'register'],
		['a', 'value', 'register'],
		['d', 'Register'],
		['e', 'button'],
		['e', 'p'],

		['e', 'fieldset'],

		['b', 'div'],
		['a', 'class', 'messages'],
		['b', 'span'],
		['a', 'class', 'info'],
		['d', 'This is message.'],
		['e', 'span'],

		['b', 'br'],
		['e', 'br'],

		['b', 'span'],
		['a', 'class', 'info'],
		['a', 'lang', 'cs'],
		['d', 'Toto je zpráva.'],
		['e', 'span'],
		['e', 'div'],

		['e', 'form'],
	],
	'Default registering form with messages.',
);

# Test.
$obj = Tags::HTML::Login::Register->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n",
	"Parameter 'tags' isn't defined.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Login::Register->new(
	'tags' => $tags,
);
eval {
	$obj->process('foo');
};
is($EVAL_ERROR, "Bad list of messages.\n",
	"Bad list of messages.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Login::Register->new(
	'tags' => $tags,
);
eval {
	$obj->process(['foo']);
};
is($EVAL_ERROR, "Bad message data object.\n",
	"Bad message data object.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Login::Register->new(
	'tags' => $tags,
);
my $test_obj = Test::MockObject->new;
eval {
	$obj->process([$test_obj]);
};
is($EVAL_ERROR, "Bad message data object.\n",
	"Bad message data object.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Login::Register->new(
	'tags' => $tags,
	'text' => {
		'eng' => {},
	},
);
eval {
	$obj->process;
};
is($EVAL_ERROR, "Text for lang 'eng' and key 'register' doesn't exist.\n",
	"Text for lang 'eng' and key 'register' doesn't exist.");
