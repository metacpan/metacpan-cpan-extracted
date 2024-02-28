use strict;
use warnings;

use Data::Message::Simple;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::ChangePassword;
use Tags::Output::Structure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::ChangePassword->new(
	'tags' => $tags,
);
my $message_types_hr = {
	'error' => 'red',
};
$obj->prepare($message_types_hr);
my $messages_ar = [
	Data::Message::Simple->new(
		'text' => 'Error #1',
		'type' => 'error',
	),
];
$obj->init($messages_ar);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'form'],
		['a', 'class', 'form-change-password'],
		['a', 'method', 'post'],

		['b', 'fieldset'],
		['b', 'legend'],
		['d', 'Change password'],
		['e', 'legend'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'old_password'],
		['d', 'Old password'],
		['e', 'label'],
		['b', 'input'],
		['a', 'type', 'password'],
		['a', 'name', 'old_password'],
		['a', 'id', 'old_password'],
		['a', 'autofocus', 'autofocus'],
		['e', 'input'],
		['e', 'p'],

		['b', 'p'],
		['b', 'label'],
		['a', 'for', 'password1'],
		['d', 'New password'],
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
		['d', 'Confirm new password'],
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
		['a', 'name', 'change_password'],
		['a', 'value', 'change_password'],
		['d', 'Save Changes'],
		['e', 'button'],
		['e', 'p'],

		['e', 'fieldset'],

		['b', 'div'],
		['a', 'class', 'messages'],
		['b', 'span'],
		['a', 'class', 'error'],
		['d', 'Error #1'],
		['e', 'span'],
		['e', 'div'],

		['e', 'form'],
	],
	'Default form with error.',
);
