use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Page::End;
use Tags::Output::Structure;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Page::End->new(
	'tags' => $tags,
);
$tags->put(
	['b', 'html'],
	['b', 'body'],
);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'html'],
		['b', 'body'],
		['e', 'body'],
		['e', 'html'],
	],
	'End of page.',
);

# Test.
$obj = Tags::HTML::Page::End->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n", "Parameter 'tags' isn't defined.");
clean();
