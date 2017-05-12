#!perl

use strict;
use warnings;

use Test::More tests => 10;

use_ok( 'Str::Filter', ':ALL' );

is( filter_leading_whitespace(),  undef, 'filter_leading_whitespace()' );
is( filter_trailing_whitespace(), undef, 'filter_trailing_whitespace()' );
is( filter_collapse_whitespace(), undef, 'filter_collapse_whitespace()' );
is( filter_control_characters(),  undef, 'filter_control_characters()' );
is( filter_ascii_only(),          undef, 'filter_ascii_only()' );
is( filter_escape_pipes(),        undef, 'filter_escape_pipes()' );
is( filter_end_brackets(),        undef, 'filter_end_brackets()' );
is( filter_html(),                undef, 'filter_html()' );
is( filter_style_tags(),          undef, 'filter_style_tags()' );
