use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Tags::HTML::Pager;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Pager->new(
	'css' => $css,
	'url_page_cb' => sub {
		my $page = shift;
		return 'http://example.com/?page='.$page;
	},
);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.pager a'],
		['d', 'text-decoration', 'none'],
		['e'],

		['s', '.pager-paginator'],
		['d', 'display', 'flex'],
		['d', 'flex-wrap', 'wrap'],
		['d', 'justify-content', 'center'],
		['d', 'padding-left', '130px'],
		['d', 'padding-right', '130px'],
		['d', 'float', 'both'],
		['e'],

		['s', '.pager-prev_next'],
		['d', 'display', 'flex'],
		['e'],

		['s', '.pager-paginator a'],
		['s', '.pager-paginator strong'],
		['s', '.pager-paginator span'],
		['s', '.pager-next'],
		['s', '.pager-next-disabled'],
		['s', '.pager-prev'],
		['s', '.pager-prev-disabled'],
		['d', 'display', 'flex'],
		['d', 'height', '55px'],
		['d', 'width', '55px'],
		['d', 'justify-content', 'center'],
		['d', 'align-items', 'center'],
		['d', 'border', '1px solid black'],
		['d', 'margin-left', '-1px'],
		['e'],

		['s', '.pager-prev'],
		['s', '.pager-next'],
		['d', 'display', 'inline-flex'],
		['d', 'align-items', 'center'],
		['d', 'justify-content', 'center'],
		['e'],

		['s', '.pager-paginator a:hover'],
		['s', '.pager-prev_next a:hover'],
		['d', 'color', 'white'],
		['d', 'background-color', 'black'],
		['e'],

		['s', '.pager-paginator a'],
		['d', 'color', 'black'],
		['e'],

		['s', '.pager-paginator-selected'],
		['d', 'background-color', 'black'],
		['d', 'color', 'white'],
		['e'],
	],
	'Pager CSS code (1 page, defaults).',
);
