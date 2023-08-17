use strict;
use warnings;

use Data::Message::Simple;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Messages;
use Tags::Output::Structure;
use Test::MockObject;
use Test::More 'tests' => 13;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Messages->new(
	'tags' => $tags,
);
my $message_ar = [
	Data::Message::Simple->new(
		'text' => 'This is message.',
	),
];
$obj->process($message_ar);
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'messages'],
		['b', 'span'],
		['a', 'class', 'info'],
		['d', 'This is message.'],
		['e', 'span'],
		['e', 'div'],
	],
	'One message.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Messages->new(
	'tags' => $tags,
);
$message_ar = [
	Data::Message::Simple->new(
		'lang' => 'en',
		'text' => 'This is message.',
	),
];
$obj->process($message_ar);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'messages'],
		['b', 'span'],
		['a', 'class', 'info'],
		['a', 'lang', 'en'],
		['d', 'This is message.'],
		['e', 'span'],
		['e', 'div'],
	],
	'One message (with lang).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Messages->new(
	'flag_no_messages' => 0,
	'tags' => $tags,
);
$message_ar = [
	Data::Message::Simple->new(
		'text' => 'This is message.',
	),
];
$obj->process($message_ar);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'messages'],
		['b', 'span'],
		['a', 'class', 'info'],
		['d', 'This is message.'],
		['e', 'span'],
		['e', 'div'],
	],
	'One message (with flag_no_messages => 0).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Messages->new(
	'css_messages' => 'foo',
	'tags' => $tags,
);
$message_ar = [
	Data::Message::Simple->new(
		'text' => 'This is message.',
	),
];
$obj->process($message_ar);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'foo'],
		['b', 'span'],
		['a', 'class', 'info'],
		['d', 'This is message.'],
		['e', 'span'],
		['e', 'div'],
	],
	'One message.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Messages->new(
	'tags' => $tags,
);
$message_ar = [
	Data::Message::Simple->new(
		'text' => 'This is message.',
	),
	Data::Message::Simple->new(
		'text' => 'Error message.',
		'type' => 'error',
	),
];
$obj->process($message_ar);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'messages'],
		['b', 'span'],
		['a', 'class', 'info'],
		['d', 'This is message.'],
		['e', 'span'],
		['b', 'br'],
		['e', 'br'],
		['b', 'span'],
		['a', 'class', 'error'],
		['d', 'Error message.'],
		['e', 'span'],
		['e', 'div'],
	],
	'Two message one info, second error.',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Messages->new(
	'flag_no_messages' => 1,
	'tags' => $tags,
);
$message_ar = [];
$obj->process($message_ar);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'messages'],
		['d', 'No messages'],
		['e', 'div'],
	],
	'No messages (flag_no_messages = 1).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Messages->new(
	'flag_no_messages' => 0,
	'tags' => $tags,
);
$message_ar = [];
$obj->process($message_ar);
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[],
	'No messages (flag_no_messages = 0).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Messages->new(
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[],
	'No messaes (messages array ref is undef).',
);

# Test.
$obj = Tags::HTML::Messages->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n",
	"Parameter 'tags' isn't defined.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Messages->new(
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
$obj = Tags::HTML::Messages->new(
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
$obj = Tags::HTML::Messages->new(
	'tags' => $tags,
);
my $test_obj = Test::MockObject->new;
eval {
	$obj->process([$test_obj]);
};
is($EVAL_ERROR, "Bad message data object.\n",
	"Bad message data object.");
clean();
