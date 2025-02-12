use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Tags::HTML::InfoBox;
use Test::More 'tests' => 3;
use Test::NoWarnings;
use Test::Shared::Fixture::Data::InfoBox::Street;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::InfoBox->new(
	'css' => $css,
);
my $info_box = Test::Shared::Fixture::Data::InfoBox::Street->new;
$obj->init($info_box);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.info-box'],
		['d', 'background-color', '#32a4a8'],
		['d', 'padding', '1em'],
		['e'],

		['s', '.info-box .icon'],
		['d', 'text-align', 'center'],
		['e'],

		['s', '.info-box a'],
		['d', 'text-decoration', 'none'],
		['e'],
	],
	'CSS struct code (street fixture).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::InfoBox->new(
	'css' => $css,
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[],
	'CSS struct code (no init).',
);
