package Term::Fabulous::Screenshot::Render::PNG;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

# Draws a Term::Fabulous::Screenshot::Scene into a PNG with Imager. Text is
# drawn with installed fonts that fontconfig finds: the monospace font for
# everything it has, and for any other character the first installed font
# that has it.
class Term::Fabulous::Screenshot::Render::PNG :strict(params) {
	use Carp qw(croak);
	use Imager;
	use List::Util qw(max min);
	use Term::Fabulous::Screenshot::Scene;

	# Corners of rounded rectangles and joints of lines are polygons with
	# this many segments per quarter circle.
	use constant CORNER_SEGMENTS => 8;

	# The fontconfig pattern of the main font; fallback fonts are searched
	# for every character it lacks.
	field $font_family :param = 'monospace';

	field %font_file_by_style;    # regular, bold, italic, bold_italic
	field %font_by_file;
	field %fallback_file_by_character;

	# The PNG data of the scene.
	method render ($scene) {
		my $layout = $scene->layout;
		my $image  = Imager->new( xsize => $layout->{image_width}, ysize => $layout->{image_height}, channels => 4 );
		$image->box( filled => 1, color => Imager::Color->new( 0, 0, 0, 0 ) );

		$self->_draw_window( $image, $scene );
		$image->box( filled => 1, color => _color( $_->{color} ), _box_bounds($_) ) foreach $scene->backgrounds;
		foreach my $shape ( $scene->shapes ) {
			if ( $shape->{type} eq 'rect' ) {
				$image->box( filled => 1, color => _color( $shape->{color} ), _box_bounds($shape) );
			}
			elsif ( $shape->{type} eq 'circle' ) {
				$image->circle( x => $shape->{cx}, y => $shape->{cy}, r => $shape->{r}, color => _color( $shape->{color} ), aa => 1, filled => 1 );
			}
			else {
				_draw_polyline( $image, $shape );
			}
		}
		$self->_draw_text( $image, $scene, $_ ) foreach $scene->texts;
		$image->box( filled => 1, color => _color( $_->{color} ), _box_bounds($_) ) foreach $scene->lines;

		# The terminal draws sixel pictures over the cells.
		_draw_picture( $image, $_ ) foreach $scene->pictures;

		$image->write( data => \my $png, type => 'png' ) or croak 'Term::Fabulous::Screenshot::Render::PNG: ' . $image->errstr;
		return $png;
	}

	sub _color ( $rgb, $alpha = 255 ) {
		return Imager::Color->new( ( $rgb >> 16 ) & 0xFF, ( $rgb >> 8 ) & 0xFF, $rgb & 0xFF, $alpha );
	}

	sub _box_bounds ($rect) {
		return ( xmin => $rect->{x}, ymin => $rect->{y}, xmax => $rect->{x} + $rect->{width} - 1, ymax => $rect->{y} + $rect->{height} - 1 );
	}

	# A sixel picture stretched to its box, over what is drawn there.
	sub _draw_picture ( $image, $picture ) {
		my $source = Imager->new( data => $picture->{png}, type => 'png' ) or croak 'Term::Fabulous::Screenshot::Render::PNG: cannot read a picture: ' . Imager->errstr;
		my $scaled = $source->scale( xpixels => $picture->{width}, ypixels => $picture->{height}, type => 'nonprop' ) or croak 'Term::Fabulous::Screenshot::Render::PNG: ' . $source->errstr;
		$image->compose( src => $scaled, tx => $picture->{x}, ty => $picture->{y} ) or croak 'Term::Fabulous::Screenshot::Render::PNG: ' . $image->errstr;
		return;
	}

	# The window: a shadow (blurred on a layer of its own), the rounded
	# body with a faint outline, the title bar, its buttons and the title.
	method _draw_window ( $image, $scene ) {
		my $layout = $scene->layout;
		my $theme  = $scene->theme;
		my $scale  = $scene->scale;
		my ( $x, $y, $width, $height ) = @$layout{qw(window_x window_y window_width window_height)};
		my $radius = $theme->corner_radius * $scale;

		my $shadow = Imager->new( xsize => $image->getwidth, ysize => $image->getheight, channels => 4 );
		$shadow->box( filled => 1, color => Imager::Color->new( 0, 0, 0, 0 ) );
		$shadow->polygon(
			points => _rounded_rect( $x, $y + $theme->shadow_offset * $scale, $width, $height, $radius ),
			color  => Imager::Color->new( 0, 0, 0, int( 255 * $theme->shadow_opacity + 0.5 ) ), aa => 1
		);
		$shadow->filter( type => 'gaussian', stddev => $theme->shadow_blur * $scale ) or croak 'Term::Fabulous::Screenshot::Render::PNG: ' . $shadow->errstr;
		$image->compose( src => $shadow ) or croak 'Term::Fabulous::Screenshot::Render::PNG: ' . $image->errstr;

		my $outline = Term::Fabulous::Screenshot::Scene::mix_colors( $theme->default_background, $theme->outline_color, $theme->outline_opacity );
		my $inset   = $scale;
		$image->polygon( points => _rounded_rect( $x,          $y,          $width,              $height,              $radius ),          color => _color($outline),                     aa => 1 );
		$image->polygon( points => _rounded_rect( $x + $inset, $y + $inset, $width - 2 * $inset, $height - 2 * $inset, $radius - $inset ), color => _color( $theme->default_background ), aa => 1 );

		my $bar_height = $theme->title_bar_height * $scale;
		$image->polygon(
			points => _rounded_rect( $x + $inset, $y + $inset, $width - 2 * $inset, $bar_height - $inset, $radius - $inset, 'top' ),
			color  => _color( $theme->title_bar_color ),
			aa     => 1,
		);

		my $center_y = $y + $bar_height / 2;
		my $button_x = $x + $theme->button_spacing * $scale;
		foreach my $color ( @{ $theme->button_colors } ) {
			$image->circle( x => $button_x, y => $center_y, r => $theme->button_radius * $scale, color => _color($color), aa => 1, filled => 1 );
			$button_x += $theme->button_spacing * $scale;
		}

		return unless length $scene->shown_title;
		my $font = $self->_font( $self->_main_font_file('regular') );
		my $size = $theme->title_font_size * $scale;
		my $box  = $font->bounding_box( string => _as_characters( $scene->shown_title ), size => $size, canon => 1 );
		$image->string(
			font   => $font,
			string => _as_characters( $scene->shown_title ),
			x      => $x + ( $width - $box->advance_width ) / 2,
			y      => $center_y + ( $box->global_ascent + $box->global_descent ) / 2,    # the descent is negative
			size   => $size,
			color  => _color( $theme->title_color ),
			aa     => 1,
		);
		return;
	}

	# The outline of a rectangle with rounded corners (only the top two
	# with $corners 'top') as polygon points.
	sub _rounded_rect ( $x, $y, $width, $height, $radius, $corners = 'all' ) {
		$radius = max( 0, min( $radius, $width / 2, $height / 2 ) );
		my $bottom_radius = $corners eq 'top' ? 0 : $radius;
		my @points;
		my $corner = sub ( $center_x, $center_y, $corner_radius, $from_degrees ) {
			foreach my $step ( 0 .. CORNER_SEGMENTS ) {
				my $angle = ( $from_degrees + 90 * $step / CORNER_SEGMENTS ) * atan2( 1, 1 ) / 45;
				push @points, [ $center_x + $corner_radius * cos($angle), $center_y + $corner_radius * sin($angle) ];
			}
		};
		$corner->( $x + $width - $radius,        $y + $radius,                  $radius,        270 );
		$corner->( $x + $width - $bottom_radius, $y + $height - $bottom_radius, $bottom_radius, 0 );
		$corner->( $x + $bottom_radius,          $y + $height - $bottom_radius, $bottom_radius, 90 );
		$corner->( $x + $radius,                 $y + $radius,                  $radius,        180 );
		return \@points;
	}

	# A thick line: one quadrilateral per segment and a round joint between
	# segments.
	sub _draw_polyline ( $image, $line ) {
		my @points = @{ $line->{points} };
		my $half   = $line->{width} / 2;
		my $color  = _color( $line->{color} );
		for ( my $index = 0; $index + 3 < @points; $index += 2 ) {
			my ( $x1, $y1, $x2, $y2 ) = @points[ $index .. $index + 3 ];
			my $length = sqrt( ( $x2 - $x1 )**2 + ( $y2 - $y1 )**2 ) or next;
			my ( $nx, $ny ) = ( -( $y2 - $y1 ) / $length * $half, ( $x2 - $x1 ) / $length * $half );
			$image->polygon( points => [ [ $x1 + $nx, $y1 + $ny ], [ $x2 + $nx, $y2 + $ny ], [ $x2 - $nx, $y2 - $ny ], [ $x1 - $nx, $y1 - $ny ] ], color => $color, aa => 1 );
			$image->circle( x => $x2, y => $y2, r => $half, color => $color, aa => 1, filled => 1 ) if $index + 5 < @points;
		}
		return;
	}

	# Every glyph at the left edge of its cell (a single glyph centered in
	# its cells), with the main font in the run's weight, or with a font
	# that has the character.
	method _draw_text ( $image, $scene, $text ) {
		my $style = $text->{bold} && $text->{italic} ? 'bold_italic' : $text->{bold} ? 'bold' : $text->{italic} ? 'italic' : 'regular';
		my $size  = $scene->font_size;
		my $color = _color( $text->{color} );
		foreach my $placed ( @{ $text->{glyphs} } ) {
			my ( $x, $glyph ) = @$placed;
			next if $glyph eq ' ';
			my $font = $self->_font_for( $glyph, $style );
			if ( $text->{anchor} eq 'middle' ) {
				my $box = $font->bounding_box( string => _as_characters($glyph), size => $size, canon => 1 );
				$x += ( $text->{width} - $box->advance_width ) / 2;
			}
			$image->string( font => $font, string => _as_characters($glyph), x => $x, y => $text->{y}, size => $size, color => $color, aa => 1 )
				or croak 'Term::Fabulous::Screenshot::Render::PNG: drawing ' . _describe($glyph) . ' failed: ' . $image->errstr;
		}
		return;
	}

	# Imager treats strings without Perl's UTF-8 flag as Latin-1 bytes.
	sub _as_characters ($text) {
		my $copy = $text;
		utf8::upgrade($copy);
		return $copy;
	}

	method _font_for ( $glyph, $style ) {
		my $main = $self->_font( $self->_main_font_file($style) );
		return $main if _font_has( $main, $glyph );
		return $self->_font( $self->_fallback_file($glyph) );
	}

	sub _font_has ( $font, $glyph ) {
		my @has = $font->has_chars( string => _as_characters($glyph) );
		return @has && !grep { !$_ } @has;
	}

	method _font ($file) {
		return $font_by_file{$file} //= Imager::Font->new( file => $file, type => 'ft2' ) // croak "Term::Fabulous::Screenshot::Render::PNG: cannot load the font $file: " . Imager->errstr;
	}

	method _main_font_file ($style) {
		my %pattern_suffix = ( regular => '', bold => ':weight=bold', italic => ':slant=italic', bold_italic => ':weight=bold:slant=italic' );
		return $font_file_by_style{$style} //= _fontconfig( 'fc-match', '-f', '%{file}', $font_family . $pattern_suffix{$style} )
			|| croak "Term::Fabulous::Screenshot::Render::PNG: fontconfig found no font for '$font_family'";
	}

	# The first installed font that has every character of the cluster,
	# monospace fonts first. Color fonts are skipped: Imager draws only
	# outlines.
	method _fallback_file ($glyph) {
		return $fallback_file_by_character{$glyph} if exists $fallback_file_by_character{$glyph};

		my $charset = join ' ', map { sprintf '%x', ord } split //, $glyph;
		my @files;
		foreach my $spacing ( ':spacing=mono', '' ) {
			push @files, split /\n/, _fontconfig( 'fc-list', '-f', '%{file}\n', ":charset=$charset$spacing" );
		}
		my %seen;
		foreach my $file ( grep { !$seen{$_}++ && !/color/i } @files ) {
			next unless _font_has( $self->_font($file), $glyph );
			return $fallback_file_by_character{$glyph} = $file;
		}
		croak "Term::Fabulous::Screenshot::Render::PNG: no installed font can draw "
			. _describe($glyph)
			. "; install one that can (for example from the Noto family, or a monochrome emoji font for emoji), or render SVG instead";
	}

	sub _fontconfig (@command) {
		open my $pipe, '-|', @command or croak "Term::Fabulous::Screenshot::Render::PNG: cannot run $command[0] (fontconfig is needed for PNG output): $!";
		local $/;
		my $output = <$pipe> // '';
		close $pipe;
		croak "Term::Fabulous::Screenshot::Render::PNG: $command[0] failed with exit status " . ( $? >> 8 ) if $? && $? != -1;
		return $output;
	}

	sub _describe ($glyph) {
		return sprintf "'%s' (%s)", $glyph, join ' ', map { sprintf 'U+%04X', ord } split //, $glyph;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::Render::PNG - Draw a screenshot as PNG

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::Render::PNG;

	my $png = Term::Fabulous::Screenshot::Render::PNG->new->render($scene);

=head1 DESCRIPTION

Maintainer tool, not installed. Draws a
L<Term::Fabulous::Screenshot::Scene> into a PNG image with L<Imager>,
which needs PNG support (L<Imager::File::PNG>) and FreeType
(L<Imager::Font::FT2>). Render the scene at scale 2 for sharp images on
high-resolution screens.

Fonts are found with fontconfig (C<fc-match>, C<fc-list>). Text uses the
main monospace font in the run's weight and slant; a character that
font lacks is drawn with the first installed font that has it,
monospace fonts first. Color fonts (such as Noto Color Emoji) are
skipped, since Imager draws only glyph outlines; emoji therefore need a
monochrome emoji font. When no installed font has a character,
rendering dies and names it, rather than producing an image with a
missing glyph.

Characters are placed cell by cell, without text shaping: scripts that
need shaping (Thai vowel marks, for example) look better in SVG, where
the viewer's browser shapes them.

Sixel pictures are stretched to the cells they cover and drawn over
everything else, their transparent pixels showing what is below.

=head1 CONSTRUCTOR

=head2 new

	my $renderer = Term::Fabulous::Screenshot::Render::PNG->new( font_family => 'DejaVu Sans Mono' );

C<font_family> is the fontconfig pattern of the main font. Default:
C<monospace>.

=head1 METHODS

=head2 render

	my $png = $renderer->render($scene);

The PNG file's bytes.

=cut
