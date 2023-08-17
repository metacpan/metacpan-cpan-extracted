use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Tags::Output::Raw;

# Test.
my $obj = Tags::HTML->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n", "Parameter 'tags' isn't defined.");
clean();

# Test.
$obj = Tags::HTML->new(
	'tags' => Tags::Output::Raw->new,
);
eval {
	$obj->process;
};
is($EVAL_ERROR, "Need to be implemented in inherited class in _process() method.\n",
	'Need to be implemented in inherited class in _process() method.');
clean();
