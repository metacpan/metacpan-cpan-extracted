#!perl

use strict;
use warnings;

use Test::More tests => 29;

use_ok( 'Str::Filter', ':ALL' );

ok( my $leading_ws = '   whitespace', 'set leading whitespace' );
ok( my $trailing_ws = 'whitespace  ', 'set trailing whitespace' );
ok( my $middle_ws = 'white   space', 'set middle whitespace' );
ok( my $nonascii = "white\xe0space", 'set nonascii' );
ok( my $controls = "whitespace", 'set control chars' );
ok( my $html = '<h1>whitespace</h1>', 'set html' );
ok( my $pipes = 'white|space', 'set pipe delim text' );
ok( my $brackets = 'white]]space', 'set closing brackets' );

ok( filter_leading_whitespace($leading_ws), 'filter_leading_whitespace()' );

like( $leading_ws, qr/\Awhitespace\Z/, 'leading whitespace filtered' );

ok( filter_trailing_whitespace($trailing_ws), 'filter_trailing_whitespace()' );

like( $trailing_ws, qr/\Awhitespace\Z/, 'trailing whitespace filtered' );

ok( filter_collapse_whitespace($middle_ws), 'filter_collapse_whitesapce()' );

like( $middle_ws, qr/\Awhite\sspace\Z/, 'whitespace collapsed' );

ok( filter_ascii_only($nonascii), 'filter_ascii_only()' );

like( $nonascii, qr/\Awhitespace\Z/, 'non-ascii characters filtered' );

ok( filter_control_characters($controls), 'filter_control_characters()' );

like( $controls, qr/\Awhitespace\Z/, 'control characters filtered' );

ok( filter_escape_pipes($pipes), 'filter_escape_pipes()' );

like( $pipes, qr/white\\|space/, 'pipes escaped' );

ok( filter_end_brackets($brackets), 'filter_end_brackets()' );

like( $brackets, qr/\Awhitespace\Z/, 'brackets filtered' );

ok( filter_html($html), 'filter_html()' );

like( $html, qr/\Awhitespace\Z/, 'html filtered' );

# this one is to test for style tags
ok( my $html_w_style = q|
<a href='http://www.website.org/animals/detail.php?AnimalID=242615'>See Dash's Homepage</a><br>Go to <a href='http://www.website.org'>our official website</a><br><br><font color=red>You can fill out an adoption application online on our official website.</font><br><br>Shelly<br><br>Okay....so I'm not a cat! I'm a purebred Weimerner. <style type="text/css">blah { color: blue; }</style>I'm highly active but would be great with just a little training.
|, 'set html_w_style' );

like ( $html_w_style, qr/<style/, 'now you see it' );

ok( filter_style_tags($html_w_style), 'filter_style_tags()' );

unlike ( $html_w_style, qr/<style/, "now you don't" );
