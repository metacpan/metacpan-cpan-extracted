use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::ChangePassword;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::ChangePassword->new;
my $message_types_hr = {
	'error' => 'red',
};
my $ret = $obj->prepare($message_types_hr);
is($ret, undef, 'Prepare returns undef.');

# Test.
$obj = Tags::HTML::ChangePassword->new;
eval {
	$obj->prepare;
};
is($EVAL_ERROR, "No message types to prepare.\n", "No message types to prepare.");
clean();
