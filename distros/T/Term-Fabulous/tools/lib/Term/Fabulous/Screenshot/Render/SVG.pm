package Term::Fabulous::Screenshot::Render::SVG;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Carp qw(croak);
use Exporter qw(import);
use MIME::Base64 qw(encode_base64);

our @EXPORT_OK = qw(render_svg);

# Draws a Term::Fabulous::Screenshot::Scene as an SVG document (a
# character string). The image is self-contained: no external fonts or
# files, so it shows the same in an <img> element, where browsers load
# nothing an SVG refers to.

sub render_svg ($scene) {
	my $layout = $scene->layout;
	my $theme  = $scene->theme;
	my ( $width, $height ) = @$layout{qw(image_width image_height)};

	my @svg = (
		sprintf(
			'<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" role="img" aria-label="%s">', _n($width), _n($height), _n($width), _n($height), _escape( $scene->title )
		),
		sprintf( '<title>%s</title>', _escape( $scene->title ) ),
		_style($scene),
		_definitions($scene),
		_window($scene),
		'<g shape-rendering="crispEdges">',
		( map { _rect( $_, $_->{color} ) } $scene->backgrounds ),
		( map { _rect( $_, $_->{color} ) } grep { $_->{type} eq 'rect' } $scene->shapes ),
		'</g>',
		( map { _polyline($_) } grep { $_->{type} eq 'polyline' } $scene->shapes ),
		( map { _circle($_) } grep { $_->{type} eq 'circle' } $scene->shapes ),
		'<g class="terminal">',
		( map { _text( $_, $scene ) } $scene->texts ),
		'</g>',
		'<g shape-rendering="crispEdges">',
		( map { _rect( $_, $_->{color} ) } $scene->lines ),
		'</g>',
		( map { _image($_) } $scene->pictures ),
		'</svg>',
	);
	return join( "\n", @svg ) . "\n";
}

sub _style ($scene) {
	my $theme = $scene->theme;
	return join "\n",
		'<style>',
		sprintf( '.terminal text { font-family: %s; font-size: %spx; white-space: pre; }', $theme->font_family, _n( $scene->font_size ) ),
		'.terminal .b { font-weight: bold; }',
		'.terminal .i { font-style: italic; }',
		sprintf( '.title { font-family: %s; font-size: %spx; }', $theme->font_family, _n( $theme->title_font_size * $scene->scale ) ),
		'</style>';
}

sub _definitions ($scene) {
	my $layout = $scene->layout;
	my $theme  = $scene->theme;
	my $scale  = $scene->scale;
	return join "\n",
		'<defs>',
		sprintf(
		'<filter id="shadow" x="-10%%" y="-10%%" width="120%%" height="130%%"><feDropShadow dx="0" dy="%s" stdDeviation="%s" flood-color="#000000" flood-opacity="%s"/></filter>',
		_n( $theme->shadow_offset * $scale ), _n( $theme->shadow_blur * $scale ), _n( $theme->shadow_opacity )
		),
		sprintf(
		'<clipPath id="window"><rect x="%s" y="%s" width="%s" height="%s" rx="%s"/></clipPath>',
		map { _n($_) } @$layout{qw(window_x window_y window_width window_height)}, $theme->corner_radius * $scale
		),
		'</defs>';
}

# The window: a rounded rectangle with a shadow, the title bar with the
# three buttons and the title, and a faint outline.
sub _window ($scene) {
	my $layout = $scene->layout;
	my $theme  = $scene->theme;
	my $scale  = $scene->scale;
	my ( $x, $y, $width, $height ) = @$layout{qw(window_x window_y window_width window_height)};
	my $radius     = $theme->corner_radius * $scale;
	my $bar_height = $theme->title_bar_height * $scale;
	my $center_y   = $y + $bar_height / 2;

	my @parts = (
		sprintf( '<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s" filter="url(#shadow)"/>', map( { _n($_) } $x, $y, $width, $height, $radius ), _color( $theme->default_background ) ),
		sprintf( '<rect x="%s" y="%s" width="%s" height="%s" fill="%s" clip-path="url(#window)"/>', map( { _n($_) } $x, $y, $width, $bar_height ), _color( $theme->title_bar_color ) ),
	);
	my $button_x = $x + ( $theme->button_spacing ) * $scale;
	foreach my $color ( @{ $theme->button_colors } ) {
		push @parts, sprintf( '<circle cx="%s" cy="%s" r="%s" fill="%s"/>', _n($button_x), _n($center_y), _n( $theme->button_radius * $scale ), _color($color) );
		$button_x += $theme->button_spacing * $scale;
	}
	push @parts,
		sprintf(
		'<text class="title" x="%s" y="%s" text-anchor="middle" dominant-baseline="central" fill="%s">%s</text>',
		_n( $x + $width / 2 ), _n($center_y), _color( $theme->title_color ), _escape( $scene->shown_title )
		) if length $scene->shown_title;
	push @parts,
		sprintf(
		'<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="none" stroke="%s" stroke-opacity="%s" stroke-width="%s"/>',
		map( { _n($_) } $x + 0.5 * $scale, $y + 0.5 * $scale, $width - $scale, $height - $scale, $radius ),
		_color( $theme->outline_color ), _n( $theme->outline_opacity ), _n($scale)
		);
	return join "\n", @parts;
}

sub _rect ( $rect, $color ) {
	return sprintf '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>', ( map { _n($_) } @$rect{qw(x y width height)} ), _color($color);
}

sub _polyline ($line) {
	return sprintf '<polyline points="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linejoin="round"/>', join( ' ', map { _n($_) } @{ $line->{points} } ),
		_color( $line->{color} ), _n( $line->{width} );
}

sub _circle ($circle) {
	return sprintf '<circle cx="%s" cy="%s" r="%s" fill="%s"/>', ( map { _n($_) } @$circle{qw(cx cy r)} ), _color( $circle->{color} );
}

# A run is stretched to exactly the width of its cells (textLength), so
# the columns line up with any monospace font; a single glyph is centered
# in its cells.
sub _text ( $text, $scene ) {
	my @classes = ( $text->{bold} ? 'b' : (), $text->{italic} ? 'i' : () );
	my $class   = @classes ? sprintf( ' class="%s"', join ' ', @classes ) : '';
	my $fill    = _color( $text->{color} );
	if ( $text->{anchor} eq 'middle' ) {
		return sprintf '<text x="%s" y="%s" text-anchor="middle"%s fill="%s">%s</text>', _n( $text->{x} + $text->{width} / 2 ), _n( $text->{y} ), $class, $fill, _escape( $text->{text} );
	}
	return sprintf '<text x="%s" y="%s" textLength="%s"%s fill="%s">%s</text>', _n( $text->{x} ), _n( $text->{y} ), _n( $text->{width} ), $class, $fill, _escape( $text->{text} );
}

# The picture is embedded as a data URL: an SVG shown in an <img>
# element may load nothing else.
sub _image ($picture) {
	return sprintf '<image x="%s" y="%s" width="%s" height="%s" preserveAspectRatio="none" href="data:image/png;base64,%s"/>', ( map { _n($_) } @$picture{qw(x y width height)} ),
		encode_base64( $picture->{png}, '' );
}

sub _color ($rgb) {
	return sprintf '#%06x', $rgb;
}

# Numbers without trailing zeros, so the same scene always gives the same
# bytes.
sub _n ($number) {
	my $text = sprintf '%.3f', $number;
	$text =~ s/\.?0+\z//;
	return $text eq '-0' ? '0' : $text;
}

# XML has no way to write control characters other than tab and line
# breaks; text with one cannot be shown.
sub _escape ($text) {
	croak sprintf 'Term::Fabulous::Screenshot::Render::SVG: cannot write the control character U+%04X in SVG', ord $1
		if $text =~ /([\x00-\x08\x0B\x0C\x0E-\x1F\x{FFFE}\x{FFFF}])/;
	return $text =~ s/&/&amp;/gr =~ s/</&lt;/gr =~ s/>/&gt;/gr =~ s/"/&quot;/gr;
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::Render::SVG - Draw a screenshot as SVG

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::Render::SVG qw(render_svg);

	my $svg = render_svg($scene);    # a character string; write it as UTF-8

=head1 DESCRIPTION

Maintainer tool, not installed. Draws a
L<Term::Fabulous::Screenshot::Scene> as a standalone SVG document. The
SVG needs no external files or fonts, so it shows in an C<< <img> >>
element (as on MetaCPAN and GitHub), where browsers load nothing an SVG
refers to.

Text uses the viewer's monospace fonts (the theme's C<font_family>).
Runs of text are stretched to the exact width of their cells with
C<textLength>, and other glyphs are centered in their cells, so columns
line up whatever font the viewer has. Box drawing and block characters
are shapes, not text. Background and line rectangles use
C<shape-rendering="crispEdges">, so adjacent cells join without seams.
Sixel pictures are C<< <image> >> elements over everything else, with
the PNG data embedded, stretched to the cells they cover.

The output is deterministic: the same scene gives the same bytes.

=head1 FUNCTIONS

=head2 render_svg

	my $svg = render_svg($scene);

The SVG document, a character string ending in a newline.

=cut
