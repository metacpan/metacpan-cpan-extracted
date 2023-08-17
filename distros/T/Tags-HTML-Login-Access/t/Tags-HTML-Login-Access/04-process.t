use strict;
use warnings;

use Data::Message::Simple;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Login::Access;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 11;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Login::Access->new(
	'tags' => $tags,
);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form-login'],
		['a', 'method', 'post'],

		['b', 'fieldset'],
		['b', 'legend'],
		['d', 'Login'],
		['e', 'legend'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'username'],
		['e', 'label'],
		['d', 'User name'],
		['b', 'input'],
		['a', 'type', 'text'],
		['a', 'name', 'username'],
		['a', 'id', 'username'],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password'],
		['d', 'Password'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'password'],
		['a', 'id', 'password'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'button'],
		['a', 'type', 'submit'],
		['a', 'name', 'login'],
		['a', 'value', 'login'],
		['d', 'Login'],
		['e', 'button'],
		['e', 'p'],

		['e', 'fieldset'],

		['e', 'form'],
	],
	'Default login form without messages.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Login::Access->new(
	'tags' => $tags,
);
$obj->process([]);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form-login'],
		['a', 'method', 'post'],

		['b', 'fieldset'],
		['b', 'legend'],
		['d', 'Login'],
		['e', 'legend'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'username'],
		['e', 'label'],
		['d', 'User name'],
		['b', 'input'],
		['a', 'type', 'text'],
		['a', 'name', 'username'],
		['a', 'id', 'username'],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password'],
		['d', 'Password'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'password'],
		['a', 'id', 'password'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'button'],
		['a', 'type', 'submit'],
		['a', 'name', 'login'],
		['a', 'value', 'login'],
		['d', 'Login'],
		['e', 'button'],
		['e', 'p'],

		['e', 'fieldset'],

		['e', 'form'],
	],
	'Default login form without messages (blank message array).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Login::Access->new(
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
		['a', 'class', 'form-login'],
		['a', 'method', 'post'],

		['b', 'fieldset'],
		['b', 'legend'],
		['d', 'Login'],
		['e', 'legend'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'username'],
		['e', 'label'],
		['d', 'User name'],
		['b', 'input'],
		['a', 'type', 'text'],
		['a', 'name', 'username'],
		['a', 'id', 'username'],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password'],
		['d', 'Password'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'password'],
		['a', 'id', 'password'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'button'],
		['a', 'type', 'submit'],
		['a', 'name', 'login'],
		['a', 'value', 'login'],
		['d', 'Login'],
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
	'Default login form with messages.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Login::Access->new(
	'register_url' => '/register',
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form-login'],
		['a', 'method', 'post'],

		['b', 'fieldset'],
		['b', 'legend'],
		['d', 'Login'],
		['e', 'legend'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'username'],
		['e', 'label'],
		['d', 'User name'],
		['b', 'input'],
		['a', 'type', 'text'],
		['a', 'name', 'username'],
		['a', 'id', 'username'],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password'],
		['d', 'Password'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'password'],
		['a', 'id', 'password'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'button'],
		['a', 'type', 'submit'],
		['a', 'name', 'login'],
		['a', 'value', 'login'],
		['d', 'Login'],
		['e', 'button'],
		['e', 'p'],

		['b', 'a'],
		['a', 'href', '/register'],
		['d', 'Register'],
		['e', 'a'],

		['e', 'fieldset'],

		['e', 'form'],
	],
	'Default login form with register url.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Login::Access->new(
	'logo_image_url' => '/img/logo.jpg',
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form-login'],
		['a', 'method', 'post'],

		['b', 'fieldset'],
		['b', 'legend'],
		['d', 'Login'],
		['e', 'legend'],

		['b', 'div'],
		['a', 'class', 'logo'],
		['b', 'img'],
		['a', 'src', '/img/logo.jpg'],
		['a', 'alt', 'logo'],
		['e', 'img'],
		['e', 'div'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'username'],
		['e', 'label'],
		['d', 'User name'],
		['b', 'input'],
		['a', 'type', 'text'],
		['a', 'name', 'username'],
		['a', 'id', 'username'],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password'],
		['d', 'Password'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'password'],
		['a', 'id', 'password'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'button'],
		['a', 'type', 'submit'],
		['a', 'name', 'login'],
		['a', 'value', 'login'],
		['d', 'Login'],
		['e', 'button'],
		['e', 'p'],

		['e', 'fieldset'],

		['e', 'form'],
	],
	'Default login form with register url.',
);

# Test.
$obj = Tags::HTML::Login::Access->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n",
	"Parameter 'tags' isn't defined.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Login::Access->new(
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
$obj = Tags::HTML::Login::Access->new(
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
$obj = Tags::HTML::Login::Access->new(
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
$obj = Tags::HTML::Login::Access->new(
	'tags' => $tags,
	'text' => {
		'eng' => {},
	},
);
eval {
	$obj->process;
};
is($EVAL_ERROR, "Text for lang 'eng' and key 'login' doesn't exist.\n",
	"Text for lang 'eng' and key 'login' doesn't exist.");
