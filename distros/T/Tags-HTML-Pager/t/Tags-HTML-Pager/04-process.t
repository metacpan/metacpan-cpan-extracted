use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Pager;
use Tags::Output::Structure;
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $tags = Tags::Output::Structure->new;
my $obj = Tags::HTML::Pager->new(
	'tags' => $tags,
	'url_page_cb' => sub {
		my $page = shift;
		return 'http://example.com/?page='.$page;
	},
);
$obj->process({
	'actual_page' => 1,
	'pages_num' => 1,
});
my $ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'pager'],
		['b', 'p'],
		['a', 'class', 'pager-paginator'],
		['b', 'strong'],
		['a', 'class', 'pager-paginator-selected'],
		['d', '1'],
		['e', 'strong'],
		['e', 'p'],
		['e', 'div'],
	],
	'Pager HTML code (1 page).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Pager->new(
	'flag_prev_next' => 1,
	'flag_paginator' => 0,
	'tags' => $tags,
	'url_page_cb' => sub {
		my $page = shift;
		return 'http://example.com/?page='.$page;
	},
);
$obj->process({
	'actual_page' => 1,
	'pages_num' => 1,
});
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[],
	'Pager HTML code (1 page, paginator off, prev_next on).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Pager->new(
	'flag_prev_next' => 1,
	'flag_paginator' => 0,
	'tags' => $tags,
	'url_page_cb' => sub {
		my $page = shift;
		return 'http://example.com/?page='.$page;
	},
);
$obj->process({
	'actual_page' => 1,
	'pages_num' => 2,
});
$ret_ar = $tags->flush(1);
is_deeply(
	$ret_ar,
	[
		['b', 'div'],
		['a', 'class', 'pager'],
		['b', 'p'],
		['a', 'class', 'pager-prev_next'],
		['b', 'span'],
		['a', 'class', 'pager-prev-disabled'],
		['d', decode_utf8('←')],
		['e', 'span'],
		['b', 'a'],
		['a', 'class', 'pager-next'],
		['a', 'href', 'http://example.com/?page=2'],
		['d', decode_utf8('→')],
		['e', 'a'],
		['e', 'p'],
		['e', 'div'],
	],
	'Pager HTML code (2 pages, paginator off, prev_next on).',
);

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Pager->new(
	'tags' => $tags,
	'url_page_cb' => sub {
		my $page = shift;
		return 'http://example.com/?page='.$page;
	},
);
eval {
	$obj->process;
};
is($EVAL_ERROR, "Pages data structure is missing.\n",
	"Pages data structure is missing.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Pager->new(
	'tags' => $tags,
	'url_page_cb' => sub {
		my $page = shift;
		return 'http://example.com/?page='.$page;
	},
);
eval {
	$obj->process({
		'pages_num' => 1,
	});
};
is($EVAL_ERROR, "Missing 'actual_page' parameter in pages data structure.\n",
	"Missing 'actual_page' parameter in pages data structure.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Pager->new(
	'tags' => $tags,
	'url_page_cb' => sub {
		my $page = shift;
		return 'http://example.com/?page='.$page;
	},
);
eval {
	$obj->process({
		'actual_page' => 1,
	});
};
is($EVAL_ERROR, "Missing 'pages_num' parameter in pages data structure.\n",
	"Missing 'pages_num' parameter in pages data structure.");
clean();

# Test.
$tags = Tags::Output::Structure->new;
$obj = Tags::HTML::Pager->new(
	'tags' => $tags,
	'url_page_cb' => sub {
		my $page = shift;
		return 'http://example.com/?page='.$page;
	},
);
eval {
	$obj->process({
		'actual_page' => 10,
		'pages_num' => 1,
	});
};
is($EVAL_ERROR, "Parameter 'actual_page' is greater than parameter 'pages_num'.\n",
	"Parameter 'actual_page' is greater than parameter 'pages_num'.");
clean();
