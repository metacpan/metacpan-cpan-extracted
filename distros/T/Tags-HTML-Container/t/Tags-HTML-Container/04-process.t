use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Container;
use Tags::Output::Structure;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Container->new(
	'tags' => $tags,
);
$obj->process(sub {
	my $self = shift;
	$self->{'tags'}->put(
		['d', 'Hello world'],
	);
	return;
});
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'container'],
		['b', 'div'],
		['a', 'class', 'inner'],
		['d', 'Hello world'],
		['e', 'div'],
		['e', 'div'],
	],
	'Container HTML code (with hello world).',
);

# Test.
$obj = Tags::HTML::Container->new(
	'tags' => $tags,
);
eval {
	$obj->process;
};
is($EVAL_ERROR, "There is no contained callback with Tags code.\n",
	"There is no contained callback with Tags code.");
clean();

# Test.
$obj = Tags::HTML::Container->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n",
	"Parameter 'tags' isn't defined.");
clean();
