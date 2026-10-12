use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/lib";

use Module::Load::Conditional qw(can_load);

BEGIN {
	skip_all 'Imager and Imager::File::SIXEL are not installed' unless can_load( modules => { Imager => 0, 'Imager::File::SIXEL' => 0 } );
}

use Clay::XS qw(sizing_fixed CLAY_ATTACH_TO_PARENT CLAY_ATTACH_POINT_LEFT_TOP);
use InputTest;
use Term::Fabulous;
use Term::Fabulous::Layout;
use Term::Fabulous::Static;
use Term::Fabulous::Terminal::Memory;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Sixel;

my $CIRCLE = "$FindBin::Bin/../examples/images/rainbow_circle.png";
my $RED    = [ 255, 0, 0, 255 ];

# A PNG of $width x $height pixels in one color.
sub png ( $width, $height, $rgba ) {
	my $image = Imager->new( xsize => $width, ysize => $height, channels => 4 );
	$image->box( filled => 1, color => Imager::Color->new(@$rgba) );
	$image->write( data => \my $bytes, type => 'png' ) or die $image->errstr;
	return $bytes;
}

sub sized ( $columns, $rows ) {
	return { sizing => { width => sizing_fixed($columns), height => sizing_fixed($rows) } };
}

# The widgets in a root box on a 20x10 memory terminal whose cells are 2x4
# pixels, drawn once; returns the terminal.
sub sixel_terminal (@widgets) {
	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child(@widgets);
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 20, height => 10, sixel_cell_size => [ 2, 4 ] );
	Term::Fabulous->new( root => $root, width => 20, height => 10, terminal => $terminal )->step;
	return $terminal;
}

# The pictures of the last frame, each with its SIXEL data decoded.
sub pictures ($terminal) {
	return map {
		{ %$_, image => Imager->new( data => $_->{data}, type => 'sixel' ) // die Imager->errstr }
	} $terminal->cell_target->sixels;
}

# One line per pixel row of a picture: '#' for a painted pixel, '.' for a
# transparent one.
sub alpha_rows ($image) {
	return [
		map {
			my $y = $_;
			join '', map { ( $image->getpixel( x => $_, y => $y )->rgba )[3] ? '#' : '.' } 0 .. $image->getwidth - 1
		} 0 .. $image->getheight - 1
	];
}

subtest 'the picture over the cells' => sub {
	my $sixel     = Term::Fabulous::Widget::Sixel->new( data => png( 4, 6, $RED ) );
	my $terminal  = sixel_terminal($sixel);
	my ($picture) = pictures($terminal);

	is [ $sixel->columns, $sixel->rows ],                                     [ 2, 2 ],                                                   'the natural size: the cells its pixels cover';
	is [ @{$picture}{qw(x y columns rows)} ],                                 [ 0, 0, 2, 2 ],                                             'the picture covers them';
	is alpha_rows( $picture->{image} ),                                       [ '....', ('####') x 6, '....' ],                           'at its size, centered in the pixels of the cells';
	is [ ( $picture->{image}->getpixel( x => 0, y => 1 )->rgba )[ 0 .. 2 ] ], [ 255, 0, 0 ],                                              'in its colors';
	is [ map { $terminal->cell_target->row_text( $_, columns => 2, colors => 0, trim_trailing_whitespace => 0 ) } 0, 1 ], [ '  ', '  ' ], 'the cells below stay empty';
};

subtest 'fit' => sub {
	my $none     = Term::Fabulous::Widget::Sixel->new( data => png( 2, 4, $RED ), layout => sized( 3, 2 ) );
	my $contain  = Term::Fabulous::Widget::Sixel->new( data => png( 2, 4, $RED ), layout => sized( 3, 2 ), fit => 'contain' );
	my @pictures = pictures( sixel_terminal( $none, $contain ) );

	is alpha_rows( $pictures[0]{image} ), [ ('......') x 2, ('..##..') x 4, ('......') x 2 ], 'none keeps the natural size and centers';
	is alpha_rows( $pictures[1]{image} ), [ ('.####.') x 8 ],                                 'contain scales to fit the pixels of the cells';
};

subtest 'transparency' => sub {
	my $source = Imager->new( xsize => 2, ysize => 4, channels => 4 );
	$source->box( xmin => 0, xmax => 0, filled => 1, color => Imager::Color->new( 255, 255, 255, 128 ) );
	$source->write( data => \my $bytes, type => 'png' ) or die $source->errstr;
	my ($picture) = pictures( sixel_terminal( Term::Fabulous::Widget::Sixel->new( data => $bytes, background_color => [ 0, 0, 100, 255 ] ) ) );

	is alpha_rows( $picture->{image} ), [ ('#.') x 4 ], 'transparent pixels stay transparent';
	my @rgb = ( $picture->{image}->getpixel( x => 0, y => 0 )->rgba )[ 0 .. 2 ];
	is [ map { abs( $rgb[$_] - ( 128, 128, 178 )[$_] ) <= 2 } 0 .. 2 ], [ (T) x 3 ], 'translucent ones are mixed with the background (sixel keeps 101 levels)';
};

subtest 'covered cells are left out' => sub {
	my $sixel = Term::Fabulous::Widget::Sixel->new( data => png( 6, 8, $RED ) );
	my $cover = Term::Fabulous::Widget::Box->new(
		layout           => sized( 1, 1 ),
		background_color => [ 0, 0, 255, 255 ],
		floating         => { attach_to => CLAY_ATTACH_TO_PARENT, offset => { x => 1, y => 1 }, attach_points => { element => CLAY_ATTACH_POINT_LEFT_TOP, parent => CLAY_ATTACH_POINT_LEFT_TOP } },
	);
	my ($picture) = pictures( sixel_terminal( $sixel, $cover ) );

	is alpha_rows( $picture->{image} ), [ ('######') x 4, ('##..##') x 4 ], 'the pixels of the cell painted over it are transparent';
};

subtest 'clipped by a scroll box' => sub {
	my $sixel  = Term::Fabulous::Widget::Sixel->new( data => png( 2, 12, $RED ) );
	my $scroll = Term::Fabulous::Widget::ScrollBox->new( id => 'scroll', layout => sized( 2, 2 ) );
	$scroll->add_child($sixel);
	my ($picture) = pictures( sixel_terminal($scroll) );

	is [ @{$picture}{qw(columns rows)}, $picture->{image}->getheight ], [ 1, 2, 8 ], 'only the visible cells';
};

subtest 'a notice without sixel' => sub {
	my $sixel = Term::Fabulous::Widget::Sixel->new( file => $CIRCLE );
	my $ui    = layout_ui($sixel);
	is [ map { row_text( $sixel, $_ ) } 0 .. $sixel->rows - 1 ], [ map { sprintf '%-27s', $_ } 'Sixel needs a terminal that', 'shows sixel graphics and', 'reports the size of its', 'cells.' ],
		'on a terminal without sixel';
	is [ $sixel->file, $sixel->image_width ], [ $CIRCLE, 16 ], 'the picture is read all the same';

	my $static = Term::Fabulous::Static->new( root => Term::Fabulous::Widget::Sixel->new( file => $CIRCLE ), width => 40 );
	is( ( $static->render_lines( colors => 0 ) )[0], 'Sixel needs a terminal that', 'in static output' );
};

subtest 'layout properties' => sub {
	my $sixel = Term::Fabulous::Layout->new( string => qq{use Term::Fabulous::Widget::Sixel as Sixel\nSixel { file "$CIRCLE"; fit "contain"; }} )->build;
	is [ ref $sixel, $sixel->file, $sixel->fit ], [ 'Term::Fabulous::Widget::Sixel', $CIRCLE, 'contain' ], 'the properties of Image';
};

done_testing;
