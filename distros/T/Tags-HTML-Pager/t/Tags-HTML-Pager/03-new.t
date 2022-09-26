use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Pager;
use Tags::Output::Raw;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Pager->new(
	'url_page_cb' => sub {
		my $page = shift;
		return 'http://example.com/?page='.$page;
	},
);
isa_ok($obj, 'Tags::HTML::Pager');

# Test.
$obj = Tags::HTML::Pager->new(
	'tags' => Tags::Output::Raw->new,
	'url_page_cb' => sub {
		my $page = shift;
		return 'http://example.com/?page='.$page;
	},
);
isa_ok($obj, 'Tags::HTML::Pager');

# Test.
eval {
	Tags::HTML::Pager->new;
};
is(
	$EVAL_ERROR,
	"Missing 'url_page_cb' parameter.\n",
	"Missing 'url_page_cb' parameter.",
);
clean();

# Test.
eval {
	Tags::HTML::Pager->new(
		'tags' => 'foo',
		'url_page_cb' => sub {},
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Missing required parameter 'tags'.",
);
clean();

# Test.
eval {
	Tags::HTML::Pager->new(
		'url_page_cb' => sub {},
		'tags' => Tags::HTML::Pager->new(
			'url_page_cb' => sub {},
			'tags' => Tags::Output::Raw->new,
		),
	);
};
is(
	$EVAL_ERROR,
	"Parameter 'tags' must be a 'Tags::Output::*' class.\n",
	"Bad 'Tags::Output' instance.",
);
clean();

# Test.
eval {
	Tags::HTML::Pager->new(
		'flag_prev_next' => 0,
		'flag_paginator' => 0,
		'url_page_cb' => sub {
			my $page = shift;
			return 'http://example.com/?page='.$page;
		},
	);
};
is($EVAL_ERROR, "Both paginator styles disabled.\n",
	'Both paginator styles disabled.');
clean();

# Test.
eval {
	Tags::HTML::Pager->new(
		'css_pager' => undef,
		'url_page_cb' => sub {
			my $page = shift;
			return 'http://example.com/?page='.$page;
	},
	);
};
is($EVAL_ERROR, "Parameter 'css_pager' is required.\n",
	"Parameter 'css_pager' is required.");
clean();
