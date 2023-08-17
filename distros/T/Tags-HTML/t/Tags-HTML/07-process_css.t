use strict;
use warnings;

use CSS::Struct::Output::Raw;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n", "Parameter 'css' isn't defined.");
clean();

# Test.
$obj = Tags::HTML->new(
	'css' => CSS::Struct::Output::Raw->new,
);
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Need to be implemented in inherited class in _process_css() method.\n",
	'Need to be implemented in inherited class in _process_css() method.');
clean();

# Test.
$obj = Tags::HTML->new(
	'no_css' => 1,
);
my $ret = $obj->process_css;
is($ret, undef, 'No css mode.');
