package PDF::Cairo::Layout;

=encoding utf8

=cut

use 5.016;
use utf8;
use strict;
use warnings;
use Cairo;
use Pango;
use PDF::Cairo::Box;

our $VERSION = "1.05";
$VERSION = eval $VERSION;
=head1 NAME

PDF::Cairo::Layout - wrapper for Pango layouts

=head1 SYNOPSIS

Simplified interface for rendering L<Pango> layouts with markup in
L<Cairo>. All of the method arguments are in standard Cairo units; you
only use 'Pango units' (1/1024pt) inside markup tags (specifically,
size, rise, and letter_spacing). Methods that do not return an explicit
value return $self so they can be chained.

    use PDF::Cairo qw(cm);
    use PDF::Cairo::Layout;
    $pdf = PDF::Cairo->new(
        file => "output.pdf",
        paper => "a4",
        landscape => 1,
    );
    $layout = PDF::Cairo::Layout->new($pdf);
    $markup = qq(<big><b>big bold text</b></big>\n);
    $markup .= qq(<span font='Ms Mincho 32' lang='ja'>日本語</span>);
    $layout->markup($markup);
    $layout->width(cm(8))->indent(16);
    $pdf->move(cm(3), cm(5));
    $layout->show;

=head1 MARKUP

The Pango markup format supports the following HTML-like tags: <b>,
<big>, <i>, <s>, <span>, <sub>, <sup>, <small>, <tt>, and <u>. Span
tags are the primary way to markup text, with the others used as
shortcuts for common styles.

To set the font, you can either use the C<font> attribute with a
space-separated list of family, point size, style, variant, weight,
and stretch (all of which are optional), or set them individually with
the C<face>, C<size>, C<style>, C<weight>, C<variant>, and C<stretch>
attributes. Both of these methods are quirky and unpredictable, and
your best bet is to select a quoted string from the output of
F<pango-list>, add a size in points to the end, and use that as the
argument to C<font>.

Size is either integers in 1/1024pt, or one of: xx-small, x-small,
small, medium, large, x-large, xx-large, smaller, larger. Style is
either normal or italic. Weight is either a numeric weight or one of:
ultralight, light, normal, bold, ultrabold, heavy. Variant is either
normal or smallcaps. Stretch is one of: ultracondensed,
extracondensed, condensed, semicondensed, normal, semiexpanded,
expanded, extraexpanded, ultraexpanded.

Additional attributes include color (name or hex string), bgcolor,
alpha (1-65536 or percentage string), bgalpha, underline (none,
single, double, low, error), underline_color, rise (1/1024pt),
strikethrough (true, false), strikethrough_color, lang, and
letter_spacing (1/1024pt).

Newlines are used to indicate line breaks.

Full documentation on the markup language can be found at:

https://developer.gnome.org/pango/unstable/PangoMarkupFormat.html

=head1 DESCRIPTION

=cut

our (
	@ISA,
	@EXPORT,
	@EXPORT_OK,
	%EXPORT_TAGS,
);
BEGIN {
	require Exporter;
	@ISA = qw(Exporter);
	@EXPORT = qw();
	@EXPORT_OK = qw();
	%EXPORT_TAGS = (all => \@EXPORT_OK);
}

=head2 Methods

=over 4

=item B<new> $pdf_cairo_ref, %options

=over 4

=item alignment => 'left|center|right'

=item ellipsize => 'none|start|middle|end'

=item height => $height

=item indent => $indent

=item justify => 1|0

=item size => [$width, $height]

=item spacing => $spacing

=item tabs => [tab1,...]

=item width => $width

=item wrap => 'word|char|word-char'

=back

Create a new layout. The first argument must be a L<PDF::Cairo>
object, in order for Pango to locate the Cairo context. Options behave
the same as the methods below, except that an array reference must be
passed for size and tabs.

=cut

sub new {
	my $class = shift;
	my $pcref = shift;
	my %options = @_;
	my $self = {
		_context => $pcref->{context},
	};
	$self->{_layout} = Pango::Cairo::create_layout($pcref->{context});
	bless($self, $class);
	foreach my $key (sort keys %options) {
		if (ref $options{$key} eq 'ARRAY') {
			$self->$key(@{$options{$key}});
		}else{
			$self->$key($options{$key});
		}
	}
	return $self;
}

=item B<alignment> ['left|center|right']

Sets/gets the paragraph alignment for the current layout.

=cut

sub alignment {
	my $self = shift;
	my $alignment = shift;
	if (defined $alignment) {
		$self->{_layout}->set_alignment($alignment);
	}else{
		return $self->{_layout}->get_alignment;
	}
	return $self;
}

=item B<baseline>

Returns the Y offset from the top of the current layout to the baseline
of the first line of text. Negative.

=cut

sub baseline {
	my $self = shift;
	return -1 * $self->{_layout}->get_baseline / 1024;
}

=item B<ellipsize> ['none|start|middle|end']

Get/set the ellipsis settings for the current layout.

=cut

sub ellipsize {
	my $self = shift;
	my $ellipsize = shift;
	if (defined $ellipsize) {
		$self->{_layout}->set_ellipsize($ellipsize);
	}else{
		return $self->{_layout}->get_ellipsize;
	}
	return $self;
}

=item B<height> [$height]

Sets/gets the height of the current layout. If negative, instead
sets the number of lines per paragraph to display, ellipsizing
the others. If zero, render exactly one line.

=cut

sub height {
	my $self = shift;
	my $height = shift;
	my %options = @_;
	if (defined $height) {
		if ($height < 0) {
			$self->{_layout}->set_height($height);
		}else{
			$self->{_layout}->set_height($height * 1024);
		}
	}else{
		my $tmp = $self->{_layout}->get_height / 1024;
		return $tmp < 0 ? $tmp : $tmp / 1024;
	}
	return $self;
}

=item B<indent> [$indent]

Sets/gets the indentation for the current layout. If negative,
produces a hanging indent.

=cut

sub indent {
	my $self = shift;
	my $indent = shift;
	if (defined $indent) {
		$self->{_layout}->set_indent($indent * 1024);
	}else{
		return $self->{_layout}->get_indent / 1024;
	}
	return $self;
}

=item B<ink>

Returns the ink extents of the current layout as a L<PDF::Cairo::Box>
object.

Note that a trailing newline in the markup will count as extra "ink".

=cut

sub ink {
	my $self = shift;
	my ($ink, $logical) = $self->{_layout}->get_pixel_extents;
	return PDF::Cairo::Box->new(
		x => $ink->{x},
		y => -$ink->{y} - $ink->{height},
		width => $ink->{width},
		height => $ink->{height},
	);
}

=item B<justify> [1|0]

Get/set the justification for the current layout.

=cut

sub justify {
	my $self = shift;
	my $justify = shift;
	if (defined $justify) {
		$self->{_layout}->set_justify($justify);
	}else{
		return $self->{_layout}->get_justify;
	}
	return $self;
}

=item B<markup> $text

Set the contents of the current layout to $text, which will be
parsed for Pango markup tags.

=cut

sub markup {
	my $self = shift;
	my $text = shift;
	$self->{_layout}->set_markup($text);
	return $self;
}

=item B<path>

Add the outlines of the glyphs in the current layout to the current path.

=cut

sub path {
	my $self = shift;
	Pango::Cairo::layout_path($self->{_context}, $self->{_layout});
	return $self;
}

=item B<show>

Render layout with the upper-left corner starting at the current position.

=cut

sub show {
	my $self = shift;
	Pango::Cairo::update_layout($self->{_context}, $self->{_layout});
	Pango::Cairo::show_layout($self->{_context}, $self->{_layout});
	return $self;
}

=item B<size> [$width, $height]

Sets/gets the width and height of the current layout.

=cut

sub size {
	my $self = shift;
	if (@_ == 2) {
		$self->width(shift);
		$self->height(shift);
	}else{
		return ($self->width, $self->height);
	}
	return $self;
}

=item B<spacing> $spacing

Get/set the inter-line spacing for the current layout.

=cut

sub spacing {
	my $self = shift;
	my $spacing = shift;
	if (defined $spacing) {
		$self->{_layout}->set_spacing($spacing * 1024);
	}else{
		return $self->{_layout}->get_spacing;
	}
	return $self;
}

=item B<tabs> [tab1,...]

Sets/gets the tabs for the current layout. Defaults to the width of
eight space characters in the current font.

=cut

sub tabs {
	my $self = shift;
	my @tabs;
	if (@_ > 0) {
		my @tabarray;
		foreach (@_) {
			push(@tabarray, 0, $_ * 1024, 'left');
		}
		my $tmp = Pango::TabArray->new_with_positions(@tabarray);
		$self->{_layout}->set_tabs($tmp);
	}else{
		my @tabarray = $self->{_layout}->get_tabs->get_tabs;
		my @tabs;
		foreach my $tab (0..@tabarray/2) {
			push(@tabs, $tabarray[$tab * 2] / 1024);
		}
		return @tabs;
	}
	return $self;
}

=item B<width> [$width]

Sets/gets the wrap width of the current layout. If set to -1, no width
is set (default).

=cut

sub width {
	my $self = shift;
	my $width = shift;
	if (defined $width) {
		if ($width == -1) {
			$self->{_layout}->set_width($width);
		}else{
			$self->{_layout}->set_width($width * 1024);
		}
	}else{
		return $self->{_layout}->get_width / 1024;
	}
	return $self;
}

=item B<wrap> ['word|char|word-char']

Sets/gets the word-wrap settings for the current layout.

=cut

sub wrap {
	my $self = shift;
	my $wrap = shift;
	if (defined $wrap) {
		$self->{_layout}->set_wrap($wrap);
	}else{
		return $self->{_layout}->get_wrap;
	}
	return $self;
}

=back

=head1 AUTHOR

J Greely, C<< <jgreely at cpan.org> >>

=head1 SEE ALSO

L<Pango>, L<Pango::Layout>, 
L<Pango Markup Format|https://developer.gnome.org/pango/unstable/PangoMarkupFormat.html>

=cut

1;
