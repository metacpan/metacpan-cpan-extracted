package PDF::Writer::mock;

use strict;
use warnings;

our $VERSION = '0.03';

our @mock;

my @methods = qw(
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
);

my $x;
sub new {
    return bless \$x, shift;
}

foreach my $method (@methods) {
    no strict 'refs';
    *$method = sub {
        my $self = shift;
        push @mock, [ $method, @_ ];
        return 1;
    };
}

sub mock_reset { @mock = (); }
sub mock_retrieve { @mock }

1;
__END__
