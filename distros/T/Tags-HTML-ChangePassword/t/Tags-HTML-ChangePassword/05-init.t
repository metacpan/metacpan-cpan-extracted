use strict;
use warnings;

use Data::Message::Simple;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::ChangePassword;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::ChangePassword->new;
my $messages_ar = [
	Data::Message::Simple->new(
		'text' => 'Error #1',
		'type' => 'error',
	),
];
my $ret = $obj->init($messages_ar);
is($ret, undef, 'Init returns undef.');

# Test.
$obj = Tags::HTML::ChangePassword->new;
eval {
	$obj->init;
};
is($EVAL_ERROR, "No messages to init.\n", "No messages to init.");
clean();
