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
	skip_all 'Imager is not installed' unless can_load( modules => { Imager => 0 } );
}

use Clay::XS qw(sizing_fixed);
use MIME::Base64 qw(encode_base64);
use InputTest;
use Term::Fabulous::Layout;
use Term::Fabulous::Termbox qw(TB_HI_BLACK);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Image;

my $CIRCLE = "$FindBin::Bin/../examples/images/rainbow_circle.png";

# A PNG of the given pixels: one array of [r, g, b, a] per row.
sub png (@rows) {
	my $image = Imager->new( xsize => scalar @{ $rows[0] }, ysize => scalar @rows, channels => 4 );
	$image->setsamples( y => $_, data => [ map { @$_ } @{ $rows[$_] } ], type => '8bit' ) foreach 0 .. $#rows;
	$image->write( data => \my $bytes, type => 'png' ) or die $image->errstr;
	return $bytes;
}

# One line per pixel row of the widget: '#' for a pixel, '.' for none.
sub pixel_rows ($image) {
	my @rows;
	foreach my $y ( 0 .. $image->rows - 1 ) {
		my @cells = map { $image->cell( $_, $y ) } 0 .. $image->columns - 1;
		push @rows, join( '', map { defined $_ && $_->[0] eq "\x{2580}" ? '#' : '.' } @cells ), join( '', map { defined $_ && ( $_->[0] eq "\x{2584}" || defined $_->[2] ) ? '#' : '.' } @cells );
	}
	return \@rows;
}

sub sized ( $columns, $rows ) {
	return { sizing => { width => sizing_fixed($columns), height => sizing_fixed($rows) } };
}

my $RED = [ 255, 0, 0, 255 ];

subtest 'pixels, two per cell' => sub {
	my $bytes = png( [ $RED, [ 0, 0, 0, 0 ] ], [ [ 0, 255, 0, 255 ], [ 0, 0, 0, 0 ] ], [ [ 0, 0, 0, 0 ], [ 255, 255, 255, 128 ] ], [ [ 0, 0, 255, 255 ], [ 0, 0, 0, 255 ] ] );
	my $image = Term::Fabulous::Widget::Image->new( data => $bytes );
	my $root  = Term::Fabulous::Widget::Box->new( background_color => [ 0, 0, 100, 255 ] );
	$root->add_child($image);
	layout_ui($root);

	is [ $image->image_width, $image->image_height, $image->columns, $image->rows ], [ 2, 4, 2, 2 ],                     'the natural size: a column per pixel, a row per two';
	is $image->cell( 0, 0 ),                                                         [ "\x{2580}", 0xFF0000, 0x00FF00 ], 'upper pixel in an upper half block, lower one as its background';
	is $image->cell( 1, 0 ),                                                         undef,                              'transparent pixels leave the cell unset';
	is $image->cell( 0, 1 ),                                                         [ "\x{2584}", 0x0000FF, undef ],    'a lower pixel alone is a lower half block';
	my $mixed = ( 128 << 16 ) | ( 128 << 8 ) | int( ( 255 * 128 + 100 * 127 ) / 255 + 0.5 );
	is $image->cell( 1, 1 ), [ "\x{2580}", $mixed, TB_HI_BLACK ], 'a translucent pixel is mixed with the background below, black stays black';
};

subtest 'fit' => sub {
	my $bytes = png( map { [ ($RED) x 4 ] } 1 .. 4 );

	my $contain = Term::Fabulous::Widget::Image->new( data => $bytes, layout => sized( 8, 2 ), fit => 'contain' );
	my $stretch = Term::Fabulous::Widget::Image->new( data => $bytes, layout => sized( 8, 2 ), fit => 'stretch' );
	my $none    = Term::Fabulous::Widget::Image->new( data => $bytes, layout => sized( 6, 3 ) );
	my $cut     = Term::Fabulous::Widget::Image->new( data => $bytes, layout => sized( 2, 1 ), fit => 'none' );
	my $ui      = layout_ui( $contain, $stretch, $none, $cut );

	is pixel_rows($contain),          [ ('..####..') x 4 ],                   'contain scales to fit and centers';
	is pixel_rows($stretch),          [ ('########') x 4 ],                   'stretch fills the widget';
	is pixel_rows($none),             [ '......', ('.####.') x 4, '......' ], 'none, the default, keeps the natural size and centers';
	is pixel_rows($cut),              [ '##', '##' ],                         'none cuts a larger image on every side';
	is $contain->fit('stretch'),      'stretch',                              'fit is an accessor';
	is pixel_rows( shown($contain) ), [ ('########') x 4 ],                   'and repaints';
	like dies { $contain->fit('cover') }, qr/fit must be one of contain, none, stretch/, 'an unknown fit dies';
};

subtest 'sources' => sub {
	open my $fh, '<:raw', $CIRCLE or die "$CIRCLE: $!";
	my $bytes = do { local $/; <$fh> };
	close $fh;
	my $base64 = encode_base64( $bytes, '' );
	( my $base64url = $base64 ) =~ tr{+/=}{-_}d;

	my %source = (
		file      => $CIRCLE,
		data      => $bytes,
		base64    => $base64,
		base64url => $base64url,
		data_url  => "data:image/png;base64,$base64",
		percent   => 'data:image/png,' . join( '', map { sprintf '%%%02X', ord } split //, $bytes ),
	);
	foreach my $name ( sort keys %source ) {
		my $kind  = { base64url => 'base64', percent => 'data_url' }->{$name} // $name;
		my $image = Term::Fabulous::Widget::Image->new( $kind => $source{$name} );
		is [ $image->image_width, $image->image_height, $image->$kind ], [ 16, 16, $source{$name} ], "$name";
	}

	my $image = Term::Fabulous::Widget::Image->new( file => $CIRCLE );
	is $image->base64($base64),          $base64,            'a writer loads another source';
	is [ $image->file, $image->base64 ], [ undef, $base64 ], 'and replaces the old one';
	$image->base64(undef);
	is [ $image->base64, $image->image_width, $image->natural_size ], [ undef, undef, 0, 0 ], 'undef removes the image';
};

subtest 'invalid sources' => sub {
	like dies { Term::Fabulous::Widget::Image->new( file     => $CIRCLE, base64 => 'aGk=' ) }, qr/give at most one of file, data, base64 and data_url, got file base64/, 'two sources';
	like dies { Term::Fabulous::Widget::Image->new( file     => "$CIRCLE.missing" ) },         qr/cannot read an image from the file '\Q$CIRCLE\E\.missing'/,            'a missing file';
	like dies { Term::Fabulous::Widget::Image->new( data     => 'not an image' ) },            qr/cannot read an image from the data given/,                             'bytes of no image format';
	like dies { Term::Fabulous::Widget::Image->new( data     => "\x{263A}" ) },                qr/data must be a byte string/,                                           'characters';
	like dies { Term::Fabulous::Widget::Image->new( base64   => 'a' ) },                       qr/base64 must be base64 or base64url text/,                              'a truncated base64 text';
	like dies { Term::Fabulous::Widget::Image->new( base64   => 'a*b=' ) },                    qr/base64 must be base64 or base64url text/,                              'a foreign character';
	like dies { Term::Fabulous::Widget::Image->new( data_url => 'image.png' ) },               qr/data_url must be a data URL/,                                          'no data URL';
	like dies { Term::Fabulous::Widget::Image->new( file     => [] ) },                        qr/file must be a string/,                                                'a reference';

	my $image = Term::Fabulous::Widget::Image->new( file => $CIRCLE );
	ok dies { $image->data('not an image') }, 'a writer dies on a bad source';
	is [ $image->file, $image->image_width ], [ $CIRCLE, 16 ], 'and keeps the old image';
};

subtest 'layout properties' => sub {
	my $image = Term::Fabulous::Layout->new( string => qq{use Term::Fabulous::Widget::Image as Image\nImage { file "$CIRCLE"; fit "stretch"; }} )->build;
	is [ $image->file, $image->fit, $image->image_width ], [ $CIRCLE, 'stretch', 16 ], 'file and fit';
};

done_testing;
