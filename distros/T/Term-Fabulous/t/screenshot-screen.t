use v5.32;
use warnings;
use utf8;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;
use Config;
use File::Spec;

use FindBin;
use lib "$FindBin::Bin/../tools/lib";

use Encode qw(encode);
use MIME::Base64 qw(encode_base64);
use Module::Load::Conditional qw(can_load);
use Term::Fabulous::Render::Attr qw(STYLE_FLAGS);
use Term::Fabulous::Render::Target::Grid;
use Term::Fabulous::Screenshot::Render::SVG qw(render_svg);
use Term::Fabulous::Screenshot::Scene;
use Term::Fabulous::Screenshot::Screen;
use Term::Fabulous::Screenshot::Theme;
use Term::Fabulous::Static;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Text;

# What a program prints for a row of cells [ glyph, fg, bg ], as bytes.
sub printed (@cells) {
	my $grid = Term::Fabulous::Render::Target::Grid->new;
	$grid->put_cell( $_, 0, @{ $cells[$_] } ) foreach 0 .. $#cells;
	return encode( 'UTF-8', $grid->row_text( 0, columns => scalar @cells, colors => 1 ) . "\r\n" );
}

subtest 'from_output reads every style Static writes' => sub {
	foreach my $style (STYLE_FLAGS) {
		my ( $flag, $sgr, $name ) = @$style;
		my ($cell) = Term::Fabulous::Screenshot::Screen->from_output( printed( [ 'x', $flag | 0xFF8800, 0 ] ), 1 )->row(0);
		is [ @$cell{qw(fg styles)} ], [ 0xFF8800, { $name => 1 } ], "SGR $sgr is $name";
	}

	my $root = Term::Fabulous::Widget::Box->new;
	$root->add_child( Term::Fabulous::Widget::Text->new( markup => '[italic]a[/][dim]b[/][strike]c[/][overline]d[/][conceal]e[/][blink]f[/]' ) );
	my $report = Term::Fabulous::Static->new( root => $root, width => 6, height => 1 );
	$report->draw;
	my $bytes  = encode( 'UTF-8', join '', map { "$_\r\n" } $report->render_lines( colors => 1 ) );
	my @styles = map { join ',', sort keys %{ $_->{styles} } } Term::Fabulous::Screenshot::Screen->from_output( $bytes, 6 )->row(0);
	is \@styles, [qw(italic dim strikeout overline invisible blink)], 'a report with rich text';
};

# One cell per style, 'a' for the first: white on the default background.
sub styled_scene () {
	my @flags  = map { $_->[0] } STYLE_FLAGS;
	my $screen = Term::Fabulous::Screenshot::Screen->from_output( printed( map { [ chr( ord('a') + $_ ), $flags[$_] | 0xFFFFFF, 0 ] } 0 .. $#flags ), scalar @flags );
	return Term::Fabulous::Screenshot::Scene->new( screen => $screen, theme => Term::Fabulous::Screenshot::Theme->new );
}

subtest 'the renderers draw every style' => sub {
	my $scene = styled_scene();
	my %color_of;
	foreach my $text ( $scene->texts ) {
		$color_of{ $_->[1] } = $text->{color} foreach @{ $text->{glyphs} };
	}
	my %lines;
	push @{ $lines{ int( ( $_->{x} - $scene->layout->{terminal_x} ) / $scene->cell_width ) } }, $_->{y} foreach $scene->lines;
	like render_svg($scene), qr/class="i"[^>]*>c</, 'italic text is set in italics';
	is $color_of{b}, Term::Fabulous::Screenshot::Scene::mix_colors( $scene->theme->default_background, 0xFFFFFF, 0.5 ), 'dim text is drawn at half strength';
	ok !exists $color_of{g}, 'invisible text is not drawn';
	is $color_of{e}, 0xFFFFFF, 'blink draws the text as it is';
	is {
		map { $_ => scalar @{ $lines{$_} } } keys %lines
	}, { 3 => 1, 7 => 1, 8 => 2, 9 => 1 }, 'underline, strikeout, double underline and overline are lines';
	ok $lines{9}[0] < $lines{7}[0] && $lines{7}[0] < $lines{3}[0], 'overline above strikeout above underline';
};

subtest 'sixel pictures lie over the cells' => sub {
	my $blank   = [ ' ', 1, 0, 0 ];
	my $capture = { columns => 3, rows => 2, cells => [ [ ($blank) x 3 ], [ ($blank) x 3 ] ], pictures => [ { x => 1, y => 1, columns => 2, rows => 1, png => encode_base64( 'PNG', '' ) } ] };
	my $screen  = Term::Fabulous::Screenshot::Screen->from_capture($capture);
	is [ $screen->pictures ], [ { x => 1, y => 1, columns => 2, rows => 1, png => 'PNG' } ], 'the capture holds the PNG data in base64';

	my $scene = Term::Fabulous::Screenshot::Scene->new( screen => $screen, theme => Term::Fabulous::Screenshot::Theme->new );
	my ( $x, $y ) = ( $scene->layout->{terminal_x} + $scene->cell_width, $scene->layout->{terminal_y} + $scene->cell_height );
	my ( $width, $height ) = ( 2 * $scene->cell_width, $scene->cell_height );
	like render_svg($scene), qr{<image x="$x" y="$y" width="$width" height="$height" preserveAspectRatio="none" href="data:image/png;base64,UE5H"/>\n</svg>\n\z},
		'the SVG shows it last, over the cells it covers';

	$capture->{pictures}[0]{x} = 2;
	like dies { Term::Fabulous::Screenshot::Screen->from_capture($capture) }, qr/is not inside the 3x2 screen/, 'a picture beyond the screen dies';
};

subtest 'the PNG renderer draws every style' => sub {
	skip_all 'Imager is not installed' unless can_load( modules => { Imager => 0 } );
	skip_all 'Imager was built without PNG support' unless $Imager::formats{png};
	skip_all 'Imager was built without the freetype driver' unless $Imager::formats{ft2};
	skip_all 'fontconfig (fc-match) is not installed' unless grep { -e File::Spec->catfile( $_, "fc-match$Config{_exe}" ) } File::Spec->path;
	require Term::Fabulous::Screenshot::Render::PNG;
	my $png = Term::Fabulous::Screenshot::Render::PNG->new->render( styled_scene() );
	like $png, qr/\A\x89PNG/, 'a PNG';
};

done_testing;
