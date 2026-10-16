package Term::Fabulous::Widget::Tabs::Line;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Display;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Tabs::Line
	:isa(Term::Fabulous::Widget::Display)
	:strict(params)
{
	use Clay::XS qw(sizing_grow);
	use Scalar::Util qw(blessed);
	use Term::Fabulous::Enum::BorderStyle;
	use Term::Fabulous::Render::Geometry qw(cell_rect);

	# On its own, the line draws with the theme's tabs looks.
	method theme_family :common () {
		return 'tabs';
	}

	# The bar the line belongs to, if any.
	method bar () {
		my $parent = $self->parent;
		return blessed $parent && $parent->isa('Term::Fabulous::Widget::Tabs::Bar') ? $parent : undef;
	}

	method _is_horizontal () {
		my $bar = $self->bar;
		return !defined $bar || $bar->is_horizontal;
	}

	# One cell thick, as long as the bar.
	method natural_size () {
		return $self->_is_horizontal ? ( sizing_grow(), 1 ) : ( 1, sizing_grow() );
	}

	# The first and the last cell of a tab along the line, as the frame
	# being drawn lays it out; nothing when the tab is not laid out.
	method _span ($tab) {
		my $ui  = $self->ui               // return ();
		my $box = $ui->bounding_box($tab) // return ();
		my ( $x0, $y0, $x1, $y1 ) = cell_rect($box);
		my ( $origin_x, $origin_y ) = $self->content_origin;
		return $self->_is_horizontal ? ( $x0 - $origin_x, $x1 - 1 - $origin_x ) : ( $y0 - $origin_y, $y1 - 1 - $origin_y );
	}

	# The tabs' places, states and the side change the picture without
	# touching this widget; the bar marks it changed for everything else.
	method paint_key :override () {
		my $bar = $self->bar // return $self->SUPER::paint_key;
		return ( $self->SUPER::paint_key, $bar->side, map { ( join( ',', $self->_span($_) ), $_->is_active, $_->is_focused, $_->is_enabled ) } $bar->buttons );
	}

	# The glyph where the arms meet, in the line's style.
	sub _joint ( $style, @arms ) {
		return Term::Fabulous::Enum::BorderStyle->junction( map { $_ => $style } @arms );
	}

	method paint () {
		my $bar        = $self->bar;
		my $horizontal = $self->_is_horizontal;
		my $length     = $horizontal  ? $self->columns   : $self->rows;
		my $style      = defined $bar ? $bar->line_style : $self->look('line.style');
		my $line_attr  = $self->color_attr( defined $bar ? $bar->line_color : $self->look('line.color') );
		my ( $start, $end ) = $horizontal ? qw(left right) : qw(up down);

		my @glyphs = ( _joint( $style, $start, $end ) ) x $length;
		my @attrs  = ($line_attr) x $length;
		my @open;    # the cells of the active tab's opening, left as they are

		if ( defined $bar ) {
			my ( $toward, $away ) = ( $bar->toward_page, $bar->away_from_page );
			if ( $bar->page_border && $length >= 2 ) {
				$glyphs[0]  = _joint( $style, $toward, $end );
				$glyphs[-1] = _joint( $style, $toward, $start );
			}
			my $put = sub ( $at, $glyph, $attr ) {
				return if $at < 0 || $at >= $length;
				$glyphs[$at] = $glyph;
				$attrs[$at]  = $attr;
			};
			foreach my $tab ( $bar->buttons ) {
				my ( $from, $to ) = $self->_span($tab) or next;
				next if $to < $from;
				unless ( $tab->is_active ) {
					my $tee = _joint( $style, $away, $start, $end );
					$put->( $_, $tee, $line_attr ) foreach $from, $to;
					next;
				}
				my $attr
					= !$tab->is_enabled ? $self->color_attr( $bar->disabled_color )
					: $tab->is_focused  ? $self->color_attr( $bar->focus_border_color ) // $line_attr
					:                     $line_attr;
				$put->( $from, _joint( $style, $away, $start ), $attr );
				$put->( $to,   _joint( $style, $away, $end ),   $attr );
				$open[$_] = 1 foreach grep { $_ >= 0 && $_ < $length } $from + 1 .. $to - 1;
			}
		}

		foreach my $at ( grep { !$open[$_] } 0 .. $length - 1 ) {
			my ( $x, $y ) = $horizontal ? ( $at, 0 ) : ( 0, $at );
			$self->put_attrs( $x, $y, $glyphs[$at], $attrs[$at], undef );
		}
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Tabs::Line - The line that joins the tabs of a
bar with the page

=head1 SYNOPSIS

	# Created by Term::Fabulous::Widget::Tabs::Bar; not used directly.

=head1 DESCRIPTION

Used internally by L<Term::Fabulous::Widget::Tabs::Bar>. The line is
the bar's edge toward the page: one cell thick and as long as the bar,
drawn in the bar's C<line_style> and C<line_color>. Where the sides of
a tab meet it, it shows the joints of the style: a T under a closed
tab, whose bottom it is, and corners at the active tab, whose opening
it leaves free so that the tab and the page are one shape. With the
bar's C<page_border>, its ends are the corners of the page's border.

The line reads where the tabs lie from the layout of the frame being
drawn (L<Term::Fabulous/bounding_box, scroll_state, scroll_to>), so it
follows them whatever sizes and alignment the bar gives them. It is a
L<Term::Fabulous::Widget::Display> and paints again when a tab moved,
became active, got or lost the focus, or the bar changed its look.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Tabs::Bar>,
L<Term::Fabulous::Enum::BorderStyle/junction>.

=cut
