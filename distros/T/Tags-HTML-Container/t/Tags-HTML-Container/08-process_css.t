use strict;
use warnings;

use CSS::Struct::Output::Structure;
use English;
use Error::Pure::Utils qw(clean);
use Tags::HTML::Container;
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Test.
my $css = CSS::Struct::Output::Structure->new;
my $obj = Tags::HTML::Container->new(
	'css' => $css,
);
$obj->process_css;
my $ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.container'],
		['d', 'display', 'flex'],
		['d', 'align-items', 'center'],
		['d', 'justify-content', 'center'],
		['d', 'height', '100vh'],
		['e'],
	],
	'Container CSS code (center-center).',
);

# Test.
$obj = Tags::HTML::Container->new(
	'css' => $css,
	'horiz_align' => 'left',
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.container'],
		['d', 'display', 'flex'],
		['d', 'align-items', 'center'],
		['d', 'justify-content', 'left'],
		['d', 'height', '100vh'],
		['e'],
	],
	'Container CSS code (left-center).',
);

# Test.
$obj = Tags::HTML::Container->new(
	'css' => $css,
	'horiz_align' => 'right',
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.container'],
		['d', 'display', 'flex'],
		['d', 'align-items', 'center'],
		['d', 'justify-content', 'right'],
		['d', 'height', '100vh'],
		['e'],
	],
	'Container CSS code (right-center).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Container->new(
	'css' => $css,
	'vert_align' => 'top',
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.container'],
		['d', 'display', 'flex'],
		['d', 'align-items', 'flex-start'],
		['d', 'justify-content', 'center'],
		['d', 'height', '100vh'],
		['e'],
	],
	'Container CSS code (center-top).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Container->new(
	'css' => $css,
	'vert_align' => 'base',
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.container'],
		['d', 'display', 'flex'],
		['d', 'align-items', 'baseline'],
		['d', 'justify-content', 'center'],
		['d', 'height', '100vh'],
		['e'],
	],
	'Container CSS code (center-base).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Container->new(
	'css' => $css,
	'vert_align' => 'fit',
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.container'],
		['d', 'display', 'flex'],
		['d', 'align-items', 'stretch'],
		['d', 'justify-content', 'center'],
		['d', 'height', '100vh'],
		['e'],
	],
	'Container CSS code (center-fit).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Container->new(
	'css' => $css,
	'vert_align' => 'bottom',
);
$obj->process_css;
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.container'],
		['d', 'display', 'flex'],
		['d', 'align-items', 'flex-end'],
		['d', 'justify-content', 'center'],
		['d', 'height', '100vh'],
		['e'],
	],
	'Container CSS code (center-bottom).',
);

# Test.
$css = CSS::Struct::Output::Structure->new;
$obj = Tags::HTML::Container->new(
	'css' => $css,
	'vert_align' => 'bottom',
);
$obj->process_css(sub {
	my $self = shift;

	$self->{'css'}->put(
		['s', '.foo'],
		['d', 'display', 'flex'],
		['e'],
	);

	return;
});
$ret_ar = $css->flush(1);
is_deeply(
	$ret_ar,
	[
		['s', '.container'],
		['d', 'display', 'flex'],
		['d', 'align-items', 'flex-end'],
		['d', 'justify-content', 'center'],
		['d', 'height', '100vh'],
		['e'],
		['s', '.foo'],
		['d', 'display', 'flex'],
		['e'],
	],
	'Container CSS code (center-bottom + css callback).',
);

# Test.
$obj = Tags::HTML::Container->new;
eval {
	$obj->process_css;
};
is($EVAL_ERROR, "Parameter 'css' isn't defined.\n",
	"Parameter 'css' isn't defined.");
clean();
