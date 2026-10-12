use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Clay::XS qw(sizing_fixed sizing_grow);
use Term::Fabulous::Event::Mouse;
use Term::Fabulous::Static;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::PixelCanvas;

sub image {
	my ( $columns, $rows ) = @_;
	my $image = Term::Fabulous::Widget::PixelCanvas->new;
	$image->fit_to( $columns, $rows );
	return $image;
}

# One line per pixel row: '#' for a set pixel, '.' for an unset one.
sub pixels {
	my ($image) = @_;
	return [
		map {
			my $y = $_;
			join '', map { defined $image->pixel( $_, $y ) ? '#' : '.' } 0 .. $image->pixel_width - 1
		} 0 .. $image->pixel_height - 1
	];
}

subtest 'two pixels per cell' => sub {
	my $image = image( 3, 2 );
	is [ $image->pixel_width, $image->pixel_height ], [ 3, 4 ], 'columns wide, twice the rows high';

	ref_is $image->set_pixel( 0, 0, 0xFF0000 ), $image, 'set_pixel returns the image';
	is $image->cell( 0, 0 ), [ "\x{2580}", 0xFF0000, undef ], 'a top pixel: upper half block over no background';
	$image->set_pixel( 0, 1, 0x0000FF );
	is $image->cell( 0, 0 ), [ "\x{2580}", 0xFF0000, 0x0000FF ], 'both pixels: top color over bottom color';
	is [ $image->pixel( 0, 0 ), $image->pixel( 0, 1 ) ], [ 0xFF0000, 0x0000FF ], 'pixels read back';

	$image->unset_pixel( 0, 0 );
	is $image->cell( 0, 0 ), [ "\x{2584}", 0x0000FF, undef ], 'only a bottom pixel: lower half block';
	$image->set_pixel( 0, 1, undef );
	is $image->cell( 0, 0 ), undef, 'no pixels: the cell is unset';

	$image->set_pixel( 2.9, 3.5, 1 )->set_pixel( 3, 0, 1 )->set_pixel( 0, -1, 1 );
	is pixels($image), [ '...', '...', '...', '..#' ], 'coordinates round down, pixels outside are dropped';
};

subtest 'cell writes replace pixels' => sub {
	my $image = image( 2, 1 );
	$image->set_pixel( 0, 0, 1 )->set_pixel( 0, 1, 2 );
	$image->put( 0, 0, 'A' );
	is [ $image->pixel( 0, 0 ), $image->pixel( 0, 1 ) ], [ undef, undef ], 'text shows no pixels';
	$image->set_pixel( 0, 1, 3 );
	is $image->cell( 0, 0 ), [ "\x{2584}", 3, undef ], 'a pixel replaces the text';
};

subtest 'shapes' => sub {
	my $image = image( 6, 3 );
	$image->fill_rect( -1, 1, 3, 2, 1 );
	is pixels($image), [ '......', '##....', '##....', '......', '......', '......' ], 'fill_rect is clipped to the image';

	$image->clear->draw_rect( 1, 1, 4, 4, 1 );
	is pixels($image), [ '......', '.####.', '.#..#.', '.#..#.', '.####.', '......' ], 'draw_rect draws the outline';

	$image->clear->draw_line( 0, 0, 5, 2, 1 );
	is pixels($image), [ '##....', '..##..', '....##', ('......') x 3 ], 'draw_line from end point to end point';

	$image->clear->draw_circle( 2, 2, 2, 1 );
	is pixels($image), [ '.###..', '#...#.', '#...#.', '#...#.', '.###..', '......' ], 'draw_circle draws the outline';

	$image->clear->draw_line( -1e6, -1e6 + 2, 1e6, 1e6 + 2, 1 );
	is pixels($image), [ '......', '......', '#.....', '.#....', '..#...', '...#..' ], 'a line far longer than the canvas draws the part inside it';
	$image->clear->draw_circle( 3, 1e5 + 2, 1e5, 1 );
	is pixels($image), [ ('......') x 2, '######', ('......') x 3 ], 'so does a circle far larger than the canvas';
	$image->clear->draw_circle( -50, 3, 40, 1 );
	is pixels($image), [ ('......') x 6 ], 'a circle beside the canvas draws nothing';
	like dies { $image->draw_circle( 1, 1, -1, 1 ) },       qr/radius must not be negative/, 'a negative radius dies';
	like dies { $image->draw_line( 0, 0, 9**9**9, 0, 1 ) }, qr/x must be a finite number/,   'an infinite end point dies';
};

subtest 'pixel_at maps the pointer to the pixels of its cell' => sub {
	my $root  = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, padding => { left => 2, top => 1 } } );
	my $image = Term::Fabulous::Widget::PixelCanvas->new( bordered => 1, layout => { sizing => { width => sizing_fixed(6), height => sizing_fixed(4) } } );
	$root->add_child($image);
	my $ui = Term::Fabulous::Static->new( root => $root, width => 10, height => 6 );

	my $mouse = sub { Term::Fabulous::Event::Mouse->new( key => 0, x => $_[0], y => $_[1] ) };
	is [ $image->pixel_at( $mouse->( 3, 2 ) ) ], [], 'nothing before the first frame';

	$ui->draw;
	is [ $image->content_origin ],               [ 3, 2 ], 'the content box starts inside the border';
	is [ $image->pixel_at( $mouse->( 3, 2 ) ) ], [ 0, 0 ], 'the first cell';
	is [ $image->pixel_at( $mouse->( 6, 3 ) ) ], [ 3, 2 ], 'the upper pixel of the cell';
	is [ $image->pixel_at( $mouse->( 2, 2 ) ) ], [],       'on the border';
	is [ $image->pixel_at( $mouse->( 7, 2 ) ) ], [],       'right of the image';
};

done_testing;
