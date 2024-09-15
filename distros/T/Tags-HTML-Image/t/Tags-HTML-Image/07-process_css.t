use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Data::Image;
use Tags::HTML::Image;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Image->new(
	'css' => $css,
);
my $image = Data::Image->new(
	'url' => 'https://example.com/image.png',
);
$obj->init($image);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.image img'],
		['d', 'display', 'block'],
		['d', 'height', '100%'],
		['d', 'width', '100%'],
		['d', 'object-fit', 'contain'],
		['e'],

		['s', '.image'],
		['d', 'height', 'calc(100vh)'],
		['e'],
	],
	'CSS struct code (image).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Image->new(
	'css' => $css,
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[],
	'CSS struct code (no init).',
);
