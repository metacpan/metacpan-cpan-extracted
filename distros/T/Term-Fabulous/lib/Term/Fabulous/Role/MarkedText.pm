package Term::Fabulous::Role::MarkedText;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Role::Searchable;

role Term::Fabulous::Role::MarkedText
	:does(Term::Fabulous::Role::Searchable)
{

	# The Term::Fabulous::Text::Marks of the text the widget shows.
	method text_marks;

	# Called after the marks changed: $is_content is true for the spans,
	# false for the highlights, which are not content.
	method marks_changed;

	method spans (@new) {
		return $self->text_marks->spans unless @new;
		$self->text_marks->set_spans( $new[0] );
		$self->marks_changed(1);
		return $self->text_marks->spans;
	}

	method stylize ( $style, $start = 0, $end = undef ) {
		$self->text_marks->add_span( $style, $start, $end );
		$self->marks_changed(1);
		return $self;
	}

	method clear_spans () {
		$self->text_marks->set_spans( [] );
		$self->marks_changed(1);
		return $self;
	}

	method highlights (@new) {
		return $self->text_marks->highlights unless @new;
		$self->text_marks->set_highlights( $new[0] );
		$self->marks_changed(0);
		return $self->text_marks->highlights;
	}

	method clear_highlights () {
		$self->text_marks->set_highlights( [] );
		$self->marks_changed(0);
		return $self;
	}

	method content_revision () {
		return $self->text_marks->content_revision;
	}

	# Searching (Term::Fabulous::Role::Searchable): the one text, whose
	# key is undef.

	method search_texts () {
		return ( [ undef, $self->text_marks->text ] );
	}

	method search_revision ($key) {
		return $self->content_revision;
	}

	method highlight_text ( $key, $ranges ) {
		$self->highlights($ranges);
		return;
	}

	method clear_text_highlights () {
		$self->clear_highlights;
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Role::MarkedText - The spans and highlights of a widget
that shows one text

=head1 SYNOPSIS

	use Object::Pad 0.825;
	use Term::Fabulous::Role::MarkedText;
	use Term::Fabulous::Text::Marks;
	use Term::Fabulous::Widget::Display;

	class My::Banner :isa(Term::Fabulous::Widget::Display) :does(Term::Fabulous::Role::MarkedText) {
		field $marks;

		ADJUST :params ( :$text = '' ) {
			$marks = Term::Fabulous::Text::Marks->new( owner => ref($self), text => $text );
		}

		method text_marks () { return $marks }

		method marks_changed ($is_content) {
			$self->mark_changed;    # paint again with the new runs
			return;
		}

		method reveal_text ( $key, $offset ) { return [ $self, 0 ] }
		method natural_size () { return ( length $marks->text, 1 ) }
		method paint () { ... }    # with $marks->runs( theme => $self->drawing_theme )
	}

=head1 DESCRIPTION

L<Term::Fabulous::Widget::Text> and L<Term::Fabulous::Widget::CodeBlock>
show one text each, with spans that style it and highlights that a
search paints over them. Both keep these in a
L<Term::Fabulous::Text::Marks> and present the same methods through
this role, which also answers L<Term::Fabulous::Role::Searchable> for
the one text (its key is C<undef>). A widget that composes it provides
L</text_marks>, L</marks_changed> and L</reveal_text>, which differs
from widget to widget.

The I<marks> are those of L<Term::Fabulous::Text::Marks>; this role
handles the spans and highlights; the widget handles its links itself.

=head1 REQUIRED METHODS

=head2 text_marks

	method text_marks () { return $marks }

The L<Term::Fabulous::Text::Marks> of the text the widget shows.

=head2 marks_changed

	method marks_changed ($is_content) { ... }

Called after the role changed the marks: C<$is_content> is 1 after the
spans changed, 0 after the highlights did. The widget drops what it made
from the old marks (its runs) and makes the next frame paint again (a
Text drops its runs and bumps the revision of L<Clay::UI::Revision>; a
CodeBlock, like the SYNOPSIS, calls C<mark_changed>).

=head2 reveal_text

	method reveal_text ( $key, $offset ) { ... }

The C<reveal_text> of L<Term::Fabulous::Role::Searchable/reveal_text>: a
Text returns C<[ $self, undef ]>, a CodeBlock C<[ $self, $line ]> with
the line of the offset.

=head1 PROVIDED METHODS

=head2 spans

	my $spans = $widget->spans;              # [ [ $start, $end, \%style ], ... ]
	$widget->spans( [ [ 0, 4, 'bold' ] ] );

Accessor: the spans (a copy), or replaces them and returns the new
ones. See L<Term::Fabulous::Text::Marks/set_spans> for the checks.

=head2 stylize

	$widget->stylize( 'underline', 7, 17 );
	$widget->stylize('dim');                 # the whole text

Appends a span from C<$start> (default 0) up to C<$end> (default the end
of the text). Returns the widget.

=head2 clear_spans

Removes every span. Returns the widget.

=head2 highlights

	my $highlights = $widget->highlights;
	$widget->highlights( [ [ 3, 5, 'on accent' ] ] );

Accessor for the highlights, painted over the spans; setting them does
not change L</content_revision>.

=head2 clear_highlights

Removes every highlight. Returns the widget.

=head2 content_revision

The L<Term::Fabulous::Text::Marks/content_revision>: it grows with every
change of the text, the spans (and a text's links and markup), never
with the highlights.

=head2 search_texts, search_revision, highlight_text, clear_text_highlights

The methods of L<Term::Fabulous::Role::Searchable> for the one text: its
key is C<undef>, its revision is L</content_revision>, and
C<highlight_text> sets L</highlights>. C<search_serial> comes from
L<Term::Fabulous::Role::Searchable/search_serial>.

=head1 SEE ALSO

L<Term::Fabulous::Text::Marks>, L<Term::Fabulous::Role::Searchable>,
L<Term::Fabulous::Widget::Text>, L<Term::Fabulous::Widget::CodeBlock>.

=cut
