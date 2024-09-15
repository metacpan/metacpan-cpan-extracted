use strict;
use warnings;

use Data::Image;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Image;
use Tags::Output::Structure;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Image->new(
	'tags' => $tags,
);
my $image = Data::Image->new(
	'url' => 'https://example.com/image.png',
);
$obj->init($image);
$obj->process;
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'figure'],
		['a', 'class', 'image'],
		['b', 'img'],
		['a', 'src', 'https://example.com/image.png'],
		['e', 'img'],
		['e', 'figure'],
	],
	'Image HTML code (image).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Image->new(
	'tags' => $tags,
);
$obj->process;
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Image HTML code (no init).',
);

# Test.
$obj = Tags::HTML::Image->new;
eval {
	$obj->process;
};
is($EVAL_ERROR, "Parameter 'tags' isn't defined.\n",
	"Parameter 'tags' isn't defined.");
clean();
