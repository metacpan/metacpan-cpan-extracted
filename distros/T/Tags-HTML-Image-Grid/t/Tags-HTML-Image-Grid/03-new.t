use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Image::Grid;
use Tags::Output::Raw;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = Tags::HTML::Image::Grid->new;
isa_ok($obj, 'Tags::HTML::Image::Grid');

# Test.
$obj = Tags::HTML::Image::Grid->new(
	'tags' => Tags::Output::Raw->new,
);
isa_ok($obj, 'Tags::HTML::Image::Grid');

# Test.
eval {
	Tags::HTML::Image::Grid->new(
		'img_link_cb' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'img_link_cb' must be a code.\n",
	"Parameter 'img_link_cb' must be a code.");
clean();

# Test.
eval {
	Tags::HTML::Image::Grid->new(
		'img_select_cb' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'img_select_cb' must be a code.\n",
	"Parameter 'img_select_cb' must be a code.");
clean();

# Test.
eval {
	Tags::HTML::Image::Grid->new(
		'img_src_cb' => 'foo',
	);
};
is($EVAL_ERROR, "Parameter 'img_src_cb' must be a code.\n",
	"Parameter 'img_src_cb' must be a code.");
clean();
