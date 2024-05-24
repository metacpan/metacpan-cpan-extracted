use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::SendMessage;
use Tags::Output::Structure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::SendMessage->new(
	'tags' => $tags,
);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'id', 'send-message'],

		['b', 'form'],
		['a', 'action', ''],

		['b', 'fieldset'],

		['b', 'legend'],
		['d', 'Leave us a message'],
		['e', 'legend'],

		['b', 'label'],
		['a', 'for', 'name-and-surname'],
		['d', 'Name and surname:'],
		['e', 'label'],

		['b', 'br'],
		['e', 'br'],

		['b', 'input'],
		['a', 'id', 'name-and-surname'],
		['a', 'name', 'name-and-surname'],
		['a', 'size', 30],
		['e', 'input'],

		['b', 'br'],
		['e', 'br'],

		['b', 'label'],
		['a', 'for', 'email'],
		['d', 'Email:'],
		['e', 'label'],

		['b', 'br'],
		['e', 'br'],

		['b', 'input'],
		['a', 'id', 'email'],
		['a', 'name', 'email'],
		['a', 'size', 30],
		['e', 'input'],

		['b', 'br'],
		['e', 'br'],

		['b', 'label'],
		['a', 'for', 'subject'],
		['d', 'Subject of you question:'],
		['e', 'label'],

		['b', 'br'],
		['e', 'br'],

		['b', 'input'],
		['a', 'id', 'subject'],
		['a', 'name', 'subject'],
		['a', 'size', 72],
		['e', 'input'],

		['b', 'br'],
		['e', 'br'],

		['b', 'label'],
		['a', 'for', 'your-message'],
		['d', 'Your message:'],
		['e', 'label'],

		['b', 'br'],
		['e', 'br'],

		['b', 'textarea'],
		['a', 'id', 'your-message'],
		['a', 'name', 'your-message'],
		['a', 'cols', 75],
		['a', 'rows', 10],
		['e', 'textarea'],

		['b', 'br'],
		['e', 'br'],

		['b', 'input'],
		['a', 'type', 'submit'],
		['a', 'value', 'Send question'],
		['e', 'input'],

		['e', 'fieldset'],
		['e', 'form'],
		['e', 'div'],
	],
	'Input HTML code (image).',
);
