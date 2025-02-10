use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Data::Icon;
use Tags::HTML::Icon;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Icon->new(
	'css' => $css,
);
my $icon = Data::Icon->new(
	'url' => 'https://example.com/image.png',
);
$obj->init($icon);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		# No default CSS.
	],
	'CSS struct code (icon).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Icon->new(
	'css' => $css,
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[],
	'CSS struct code (no init).',
);
