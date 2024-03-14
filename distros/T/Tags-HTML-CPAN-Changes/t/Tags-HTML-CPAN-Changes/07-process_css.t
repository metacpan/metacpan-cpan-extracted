use strict;
use warnings;

use CPAN::Changes;
use Tags::HTML::CPAN::Changes;
use CSS::Struct::Output::Structure;
use Test::More 'tests' => 4;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::CPAN::Changes->new(
	'css' => $css,
);
my $changes = CPAN::Changes->new(
        'preamble' => 'Revision history for perl module Foo::Bar',
);
$obj->init($changes);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.changes'],
		['d', 'max-width', '800px'],
		['d', 'margin', 'auto'],
		['d', 'background', '#fff'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '8px'],
		['d', 'box-shadow', '0 2px 4px rgba(0, 0, 0, 0.1)'],
		['e'],

		['s', '.changes .version'],
		['d', 'border-bottom', '2px solid #eee'],
		['d', 'padding-bottom', '20px'],
		['d', 'margin-bottom', '20px'],
		['e'],

		['s', '.changes .version:last-child'],
		['d', 'border-bottom', 'none'],
		['e'],

		['s', '.changes .version h2'],
		['s', '.changes .version h3'],
		['d', 'color', '#007BFF'],
		['d', 'margin-top', 0],
		['e'],

		['s', '.changes .version-changes'],
		['d', 'list-style-type', 'none'],
		['d', 'padding-left', 0],
		['e'],

		['s', '.changes .version-change'],
		['d', 'background-color', '#f8f9fa'],
		['d', 'margin', '10px 0'],
		['d', 'padding', '10px'],
		['d', 'border-left', '4px solid #007BFF'],
		['d', 'border-radius', '4px'],
		['e'],
	],
	'CSS::Struct code for CPAN changes.',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::CPAN::Changes->new(
	'css' => $css,
	'css_class' => 'my-changes',
);
$changes = CPAN::Changes->new(
        'preamble' => 'Revision history for perl module Foo::Bar',
);
$obj->init($changes);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.my-changes'],
		['d', 'max-width', '800px'],
		['d', 'margin', 'auto'],
		['d', 'background', '#fff'],
		['d', 'padding', '20px'],
		['d', 'border-radius', '8px'],
		['d', 'box-shadow', '0 2px 4px rgba(0, 0, 0, 0.1)'],
		['e'],

		['s', '.my-changes .version'],
		['d', 'border-bottom', '2px solid #eee'],
		['d', 'padding-bottom', '20px'],
		['d', 'margin-bottom', '20px'],
		['e'],

		['s', '.my-changes .version:last-child'],
		['d', 'border-bottom', 'none'],
		['e'],

		['s', '.my-changes .version h2'],
		['s', '.my-changes .version h3'],
		['d', 'color', '#007BFF'],
		['d', 'margin-top', 0],
		['e'],

		['s', '.my-changes .version-changes'],
		['d', 'list-style-type', 'none'],
		['d', 'padding-left', 0],
		['e'],

		['s', '.my-changes .version-change'],
		['d', 'background-color', '#f8f9fa'],
		['d', 'margin', '10px 0'],
		['d', 'padding', '10px'],
		['d', 'border-left', '4px solid #007BFF'],
		['d', 'border-radius', '4px'],
		['e'],
	],
	'CSS::Struct code for CPAN changes (explicit CSS class).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::CPAN::Changes->new(
	'css' => $css,
	'css_class' => 'my-changes',
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[],
	'CSS::Struct code for CPAN changes (without init).',
);
