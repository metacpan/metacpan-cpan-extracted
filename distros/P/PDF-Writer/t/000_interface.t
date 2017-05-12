use strict;
use warnings;

use Test::More tests => 3;

use_ok( 'PDF::Writer', 'mock' );
can_ok( 'PDF::Writer', 'new' );

my $mock = PDF::Writer->new;
my @methods = qw{
    open close save
    begin_page end_page
    open_image close_image
    image_height image_width place_image
    save_state restore_state
    font font_size find_font
    show_boxed show_xy
    circle rect
    color
    move
    linewidth line
    fill stroke fill_stroke
    stringify
    parameter info
    add_weblink add_bookmark
};

can_ok( $mock, @methods );
