use strict;
use warnings;

use Tags::HTML::Page::End;
use Tags::Output::Structure;
use Test::More 'tests' => 2;
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
