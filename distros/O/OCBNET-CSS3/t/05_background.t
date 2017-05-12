# -*- perl -*-

use strict;
use warnings;

use Test::More tests => 65;
BEGIN { use_ok('OCBNET::CSS3') };

my $rv;

use OCBNET::CSS3::Styles::Background;
use OCBNET::CSS3::Styles::References;

# OO interface
my $css = OCBNET::CSS3::Stylesheet->new;

my $code = <<EOF;

.test-01
{
	/* css-id: test-01; */
	background: red;
}

.test-02
{
	/* css-id: test-02; */
	background: blue 20px 40px;
}

.test-03
{
	/* css-id: test-03; */
	background: blue right bottom;
}

.test-04
{
	/* css-id: test-04; */
	/* css-ref: test-03; */
	background-color: rgba(1,2,3,.5), rgb(9,6,3), green;
}

.test-05
{
	/* css-id: test-05; */
	/* css-ref: test-04; */
	background-image: url(A), url(B);
}

.test-06
{
	/* css-id: test-06; */
	/* css-ref: test-05; */
	background: url(C);
}

.test-07
{
	/* css-id: test-07; */
	/* css-ref: test-03; */
	background: rgba(1,2,3,.5), rgb(9,6,3) repeat-x, green no-repeat;
}

.test-08
{
	/* css-ref: test-07; */
	background-size: 2px;
}

.test-09
{
	/* css-ref: test-07; */
	background-size: 3px 4px;
}

EOF


$rv = $css->parse($code);

is    ($css->child(0)->style('background-color'),      'red',             'parse background-color (shorthand)');
is    ($css->child(0)->style('background-image'),      'none',            'parse background-image (default)');
is    ($css->child(0)->style('background-repeat'),     'repeat',          'parse background-repeat (default)');
is    ($css->child(0)->style('background-position-y'), 'top',             'parse background-position-y (default)');
is    ($css->child(0)->style('background-position-x'), 'left',            'parse background-position-x (default)');
is    ($css->child(0)->style('background-attachment'), 'scroll',          'parse background-attachment (default)');

is    ($css->child(1)->style('background-color'),      'blue',            'parse background-color (shorthand)');
is    ($css->child(1)->style('background-image'),      'none',            'parse background-image (default)');
is    ($css->child(1)->style('background-repeat'),     'repeat',          'parse background-repeat (default)');
is    ($css->child(1)->style('background-position-x'), '20px',            'parse background-position-x (shorthand)');
is    ($css->child(1)->style('background-position-y'), '40px',            'parse background-position-y (shorthand)');
is    ($css->child(1)->style('background-attachment'), 'scroll',          'parse background-attachment (default)');

is    ($css->child(2)->style('background-color'),      'blue',            'parse background-color (shorthand)');
is    ($css->child(2)->style('background-image'),      'none',            'parse background-image (default)');
is    ($css->child(2)->style('background-repeat'),     'repeat',          'parse background-repeat (default)');
is    ($css->child(2)->style('background-position-y'), 'bottom',          'parse background-position-y (shorthand - wrong order)');
is    ($css->child(2)->style('background-position-x'), 'right',           'parse background-position-x (shorthand - wrong order)');
is    ($css->child(2)->style('background-attachment'), 'scroll',          'parse background-attachment (default)');

is    ($css->child(3)->style('background-color'),      'rgba(1,2,3,.5)',  'parse background-color[0] (shorthand)');
is    ($css->child(3)->style('background-color', 0),   'rgba(1,2,3,.5)',  'parse background-color[0] (shorthand)');
is    ($css->child(3)->style('background-color', 1),   'rgb(9,6,3)',      'parse background-color[1] (shorthand)');
is    ($css->child(3)->style('background-color', 2),   'green',           'parse background-color[1] (shorthand)');
is    ($css->child(3)->style('background-image'),      'none',            'parse background-image (inherit from shorthand 3)');
is    ($css->child(3)->style('background-repeat'),     'repeat',          'parse background-repeat (inherit from shorthand 3)');
is    ($css->child(3)->style('background-position-y'), 'bottom',          'parse background-position-y (inherit from shorthand 3)');
is    ($css->child(3)->style('background-position-x'), 'right',           'parse background-position-x (inherit from shorthand 3)');
is    ($css->child(3)->style('background-attachment'), 'scroll',          'parse background-attachment (inherit from shorthand 3	)');

is    ($css->child(4)->style('background-color'),      'rgba(1,2,3,.5)',  'parse background-color (shorthand)');
is    ($css->child(4)->style('background-color', 0),   'rgba(1,2,3,.5)',  'parse background-color[0] (shorthand)');
is    ($css->child(4)->style('background-color', 1),   'rgb(9,6,3)',      'parse background-color[1] (shorthand)');
is    ($css->child(4)->style('background-color', 2),   'green',           'parse background-color[2] (shorthand)');
is    ($css->child(4)->style('background-image'),      'url(A)',          'parse background-image (shorthand)');
is    ($css->child(4)->style('background-image', 0),   'url(A)',          'parse background-image[0] (shorthand)');
is    ($css->child(4)->style('background-image', 1),   'url(B)',          'parse background-image[1] (shorthand)');
is    ($css->child(4)->style('background-repeat'),     'repeat',          'parse background-repeat (inherit from shorthand 3)');
is    ($css->child(4)->style('background-position-y'), 'bottom',          'parse background-position-y (inherit from shorthand 3)');
is    ($css->child(4)->style('background-position-x'), 'right',           'parse background-position-x (inherit from shorthand 3)');
is    ($css->child(4)->style('background-attachment'), 'scroll',          'parse background-attachment (inherit from shorthand 3	)');

is    ($css->child(5)->style('background-color'),      'transparent',     'parse background-color (shorthand default)');
is    ($css->child(5)->style('background-image'),      'url(C)',          'parse background-image (shorthand default)');
is    ($css->child(5)->style('background-repeat'),     'repeat',          'parse background-repeat (shorthand default)');
is    ($css->child(5)->style('background-position-y'), 'top',             'parse background-position-y (shorthand default)');
is    ($css->child(5)->style('background-position-x'), 'left',            'parse background-position-x (shorthand default)');
is    ($css->child(5)->style('background-attachment'), 'scroll',          'parse background-attachment (shorthand default)');

is    ($css->child(6)->style('background-color'),      'rgba(1,2,3,.5)',  'parse background-color (shorthand)');
is    ($css->child(6)->style('background-color', 0),   'rgba(1,2,3,.5)',  'parse background-color[0] (shorthand)');
is    ($css->child(6)->style('background-color', 1),   'rgb(9,6,3)',      'parse background-color[1] (shorthand)');
is    ($css->child(6)->style('background-color', 2),   'green',           'parse background-color[2] (shorthand)');

is    ($css->child(6)->style('background-repeat'),     'repeat',          'parse background-repeat (shorthand)');
is    ($css->child(6)->style('background-repeat', 0),  'repeat',          'parse background-repeat[0] (shorthand)');
is    ($css->child(6)->style('background-repeat', 1),  'repeat-x',        'parse background-repeat[1] (shorthand)');
is    ($css->child(6)->style('background-repeat', 2),  'no-repeat',       'parse background-repeat[2] (shorthand)');

is    ($css->child(6)->style('background-repeat'),       'repeat',        'parse background-repeat-x (shorthand)');
is    ($css->child(6)->style('background-repeat-x', 0),  'repeat',        'parse background-repeat-x[0] (shorthand)');
is    ($css->child(6)->style('background-repeat-x', 1),  'repeat',        'parse background-repeat-x[1] (shorthand)');
is    ($css->child(6)->style('background-repeat-x', 2),  0,               'parse background-repeat-x[2] (shorthand)');

is    ($css->child(6)->style('background-repeat'),       'repeat',        'parse background-repeat-x (shorthand)');
is    ($css->child(6)->style('background-repeat-y', 0),  'repeat',        'parse background-repeat-y[0] (shorthand)');
is    ($css->child(6)->style('background-repeat-y', 1),  0,               'parse background-repeat-y[1] (shorthand)');
is    ($css->child(6)->style('background-repeat-y', 2),  0,               'parse background-repeat-y[2] (shorthand)');

is    ($css->child(7)->style('background-size-x'),       '2px',           'parse background-size-y (shorthand)');
is    ($css->child(7)->style('background-size-y'),       '2px',           'parse background-size-x (shorthand)');

is    ($css->child(8)->style('background-size-x'),       '3px',           'parse background-size-x (shorthand)');
is    ($css->child(8)->style('background-size-y'),       '4px',           'parse background-size-y (shorthand)');
