# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
	use_ok( 'SDLx::Widget' );
	use_ok( 'SDLx::Widget::Menu' );
	use_ok( 'SDLx::Widget::Textbox' );

}

