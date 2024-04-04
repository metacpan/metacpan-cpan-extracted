use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use Tags::HTML;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Tags::Output::Raw;
use Tags::Output::Structure;

# Data directory.
my $data = File::Object->new->up->dir('data');

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

# Test.
unshift @INC, $data->s;
require Ex1;
my $tags = Tags::Output::Structure->new;
$obj = Ex1->new(
	'tags' => $tags,
);
my $ret = $obj->process;
is($ret, undef, 'Method process() returns undef.');
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['d', 'Hello'],
		['e', 'div'],
	],
	'Process do <div>Hello</div>.',
);
