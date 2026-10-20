package Term::Fabulous::Text::Marks;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

class Term::Fabulous::Text::Marks :strict(params) {
	use List::Util qw(first uniqnum);
	use Term::Fabulous::Check qw(describe non_negative_integer string);
	use Term::Fabulous::Text::Style qw(compose_styles resolve_style style);

	# The name the error messages start with: the widget class the marks
	# belong to.
	field $owner :param;
	field $text :param = '';

	field @spans;    # [ start, end, style hash ], in the order given
	field @highlights;    # the same, painted over the spans
	field @links;    # [ start, end, target ], by start, none overlapping

	# Counts the changes of the text, the spans and the links; highlights
	# are not content, so marking what a search found leaves it alone.
	field $content_revision = 0;

	ADJUST :params ( :$spans = [], :$links = [] ) {
		$owner = string( 'Term::Fabulous::Text::Marks', owner => $owner );
		$text  = string( $owner,                        text  => $text );
		@spans = $self->check_spans( span => $spans );
		die "$owner: links must be an array reference of [start, end, target], got " . describe($links) unless ref $links eq 'ARRAY';
		foreach my $link (@$links) {
			die "$owner: a link is [start, end, target], got " . describe($link) unless ref $link eq 'ARRAY' && @$link == 3;
			$self->_insert_link( @{$link}[ 2, 0, 1 ] );
		}
	}

	method text () {
		return $text;
	}

	# A new text drops every mark: they pointed into the old one.
	method set_text ($new) {
		$text = string( $owner, text => $new );
		( @spans, @highlights, @links ) = ();
		$content_revision++;
		return $self;
	}

	method content_revision () {
		return $content_revision;
	}

	method has_marks () {
		return @spans || @highlights || @links ? 1 : 0;
	}

	# ---------------------------------------------------------------------
	# Spans and highlights
	# ---------------------------------------------------------------------

	method spans () {
		return _copies(@spans);
	}

	method set_spans ($given) {
		@spans = $self->check_spans( span => $given );
		$content_revision++;
		return $self;
	}

	method add_span ( $style, $start = 0, $end = undef ) {
		push @spans, $self->_span( span => $style, $start, $end // length $text );
		$content_revision++;
		return $self;
	}

	method highlights () {
		return _copies(@highlights);
	}

	method set_highlights ($given) {
		@highlights = $self->check_spans( highlight => $given );
		return $self;
	}

	sub _copies (@ranges) {
		return [ map { [ $_->[0], $_->[1], { %{ $_->[2] } } ] } @ranges ];
	}

	# Checked copies of ranges [ start, end, style ] of the text, each
	# style normalized to a style hash of Term::Fabulous::Text::Style.
	method check_spans ( $what, $given ) {
		die "$owner: ${what}s must be an array reference of [start, end, style], got " . describe($given) unless ref $given eq 'ARRAY';
		return map {
			die "$owner: a $what is [start, end, style], got " . describe($_) unless ref $_ eq 'ARRAY' && @$_ == 3;
			$self->_span( $what, $_->[2], $_->[0], $_->[1] );
		} @$given;
	}

	method _span ( $what, $style, $start, $end ) {
		return [ $self->_checked_range( $what, $start, $end ), style($style) ];
	}

	method _checked_range ( $what, $start, $end ) {
		$start = non_negative_integer( $owner, "$what start", $start );
		$end   = non_negative_integer( $owner, "$what end",   $end );
		my $length = length $text;
		die "$owner: $what end $end lies before its start $start" if $end < $start;
		die "$owner: $what end $end lies past the text ($length characters)" if $end > $length;
		return ( $start, $end );
	}

	# ---------------------------------------------------------------------
	# Links
	# ---------------------------------------------------------------------

	method links () {
		return [ map { [@$_] } @links ];
	}

	method link_count () {
		return scalar @links;
	}

	# The index of the link the character at the offset lies in, or undef.
	method link_at ($offset) {
		$offset = non_negative_integer( $owner, offset => $offset );
		return first { $links[$_][0] <= $offset && $offset < $links[$_][1] } 0 .. $#links;
	}

	# Puts a link in its place by start and returns its index there.
	method add_link ( $target, $start = 0, $end = undef ) {
		my $position = $self->_insert_link( $target, $start, $end // length $text );
		$content_revision++;
		return $position;
	}

	method _insert_link ( $target, $start, $end ) {
		die "$owner: a link needs a target" unless defined $target;
		( $start, $end ) = $self->_checked_range( link => $start, $end );
		die "$owner: a link must not be empty, got $start to $end" if $start == $end;
		my $overlapped = first { $_->[0] < $end && $start < $_->[1] } @links;
		die "$owner: the link $start to $end overlaps the link $overlapped->[0] to $overlapped->[1]" if defined $overlapped;
		my $position = ( first { $links[$_][0] > $start } 0 .. $#links ) // scalar @links;
		splice @links, $position, 0, [ $start, $end, $target ];
		return $position;
	}

	method clear_links () {
		@links = ();
		$content_revision++;
		return $self;
	}

	# ---------------------------------------------------------------------
	# Runs
	# ---------------------------------------------------------------------

	# The text cut at every boundary of its ranges, each piece with the
	# styles that cover it stacked in order (under, then the spans, then
	# the highlights, then over) and its palette tokens resolved against
	# the theme: [ from, to, style hash ], covering the whole text. One
	# sweep over the boundaries keeps the ranges that cover the piece at
	# hand.
	method runs (%options) {
		my @unknown = grep { $_ ne 'theme' && $_ ne 'under' && $_ ne 'over' } sort keys %options;
		die "Term::Fabulous::Text::Marks: runs does not take @unknown (known: theme under over)" if @unknown;
		my $theme  = $options{theme} // die "Term::Fabulous::Text::Marks: runs needs a theme";
		my @ranges = ( @{ $options{under} // [] }, @spans, @highlights, @{ $options{over} // [] } );
		my $length = length $text;
		return [] unless $length;

		my ( %starting_at, %ending_at );
		foreach my $index ( grep { $ranges[$_][0] < $ranges[$_][1] } 0 .. $#ranges ) {
			push @{ $starting_at{ $ranges[$index][0] } }, $index;
			push @{ $ending_at{ $ranges[$index][1] } },   $index;
		}
		my @boundaries = sort { $a <=> $b } uniqnum 0, $length, keys %starting_at, keys %ending_at;

		my ( %covering, @runs );
		foreach my $index ( 1 .. $#boundaries ) {
			my ( $from, $to ) = @boundaries[ $index - 1, $index ];
			delete @covering{ @{ $ending_at{$from} // [] } };
			$covering{$_} = 1 foreach @{ $starting_at{$from} // [] };
			my $style = compose_styles( map { $ranges[$_][2] } sort { $a <=> $b } keys %covering );
			push @runs, [ $from, $to, resolve_style( $style, $theme ) ];
		}
		return \@runs;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Text::Marks - The spans, highlights and links of one text

=head1 SYNOPSIS

	use Term::Fabulous::Text::Marks;
	use Term::Fabulous::Theme;

	my $marks = Term::Fabulous::Text::Marks->new(
		owner => 'My::Widget',
		text  => 'Read the manual first.',
		spans => [ [ 0, 4, 'bold' ] ],
		links => [ [ 9, 15, 'manual' ] ],
	);
	$marks->add_span( 'italic', 16, 21 );
	$marks->set_highlights( [ [ 9, 15, 'on warning' ] ] );    # not content

	foreach my $run ( @{ $marks->runs( theme => Term::Fabulous::Theme->default ) } ) {
		my ( $from, $to, $style ) = @$run;    # a style hash, tokens resolved
	}

=head1 DESCRIPTION

The marks of one text: the I<spans> a program styles it with, the
I<highlights> a search paints over them, and the I<links>. Every range
is C<[ $start, $end, ... ]> in characters, C<$end> excluded, checked
against the text, with error messages worded alike for spans,
highlights and links; styles are style hashes of
L<Term::Fabulous::Text::Style>. Readers return copies.

The marks count the changes of their content in L</content_revision>:
the text, the spans and the links. Highlights are not content: a search
that marks what it found does not make the offsets it recorded stale.

L</runs> cuts the text where ranges start and end and stacks the styles
that cover each piece. L<Term::Fabulous::Widget::Text> and
L<Term::Fabulous::Widget::CodeBlock> keep their marks here, present them
through L<Term::Fabulous::Role::MarkedText>, and turn the runs into the
tuples their renderers paint with.

Error messages start with the C<owner>, the class of the widget the
marks belong to.

=head1 CONSTRUCTOR

=head2 new

	my $marks = Term::Fabulous::Text::Marks->new( owner => ref($self), text => $text, spans => \@spans, links => \@links );

C<owner> (required) is the name the messages start with. C<text> is the
string (default C<''>), C<spans> an array reference of
C<[ $start, $end, $style ]> and C<links> one of
C<[ $start, $end, $target ]> (both default empty). Dies as L</set_spans>
and L</add_link> do, and for C<links> that are not an array reference
(C<links must be an array reference of [start, end, target], got ...>)
or an entry that is not C<[ $start, $end, $target ]>
(C<a link is [start, end, target], got ...>). The content revision
starts at 0.

=head1 METHODS

=head2 text

	my $text = $marks->text;

The text.

=head2 set_text

	$marks->set_text($new);

Replaces the text and drops every span, highlight and link, which
pointed into the old one. Counts as a change. Returns the marks.

=head2 content_revision

	my $revision = $marks->content_revision;

A number that grows with every change of the text, the spans or the
links (also one that sets them to what they were), and never with the
highlights.

=head2 has_marks

1 when the text has any span, highlight or link, else 0.

=head2 spans

	my $spans = $marks->spans;    # [ [ $start, $end, \%style ], ... ]

A copy of the spans, in the order they stack.

=head2 set_spans

	$marks->set_spans( [ [ 0, 4, 'bold' ] ] );

Replaces the spans. Counts as a change. Returns the marks. Dies for
anything but an array reference (C<spans must be an array reference of
[start, end, style]>), for an entry that is not
C<[ $start, $end, $style ]> (C<a span is [start, end, style]>), for
offsets that are not non-negative integers, for an end before its start
(C<span end 0 lies before its start 1>) or past the text
(C<span end 3 lies past the text (2 characters)>), and for a style
L<Term::Fabulous::Text::Style/style> does not read.

=head2 add_span

	$marks->add_span( 'underline', 5, 9 );
	$marks->add_span('dim');                # the whole text

Appends a span from C<$start> (default 0) up to C<$end> (default the end
of the text), checked as by L</set_spans>. Counts as a change. Returns
the marks.

=head2 highlights

	my $highlights = $marks->highlights;

A copy of the highlights, which are painted over the spans.

=head2 set_highlights

	$marks->set_highlights( [ [ 3, 5, 'on accent' ] ] );

Replaces the highlights, checked like spans (with C<highlight> in the
messages). Not a change of the content. Returns the marks.

=head2 check_spans

	my @spans = $marks->check_spans( 'highlighter span' => $result );

Checked copies of ranges given by someone else, with the styles
normalized, in the wording of L</set_spans> with C<$what> in place of
C<span>. For ranges a widget stacks with L</runs> without keeping them
here, such as the spans of a syntax highlighter.

=head2 links

	my $links = $marks->links;    # [ [ $start, $end, $target ], ... ]

A copy of the links, ordered by their start, none overlapping another.

=head2 link_count

The number of links.

=head2 link_at

	my $index = $marks->link_at($offset);

The index of the link the character at the offset lies in, or
C<undef>. An offset that is not a non-negative integer dies.

=head2 add_link

	my $index = $marks->add_link( $target, 9, 15 );

Puts a link from C<$start> (default 0) up to C<$end> (default the end of
the text) in its place among the links and returns its index there, so
that a widget can keep track of a selected link. Counts as a change.
Dies for an undefined target (C<a link needs a target>), an empty range
(C<a link must not be empty, got 2 to 2>), a range that overlaps a link
(C<the link 10 to 14 overlaps the link 4 to 12>) and offsets as for
spans (with C<link>).

=head2 clear_links

	$marks->clear_links;

Removes every link. Counts as a change. Returns the marks.

=head2 runs

	my $runs = $marks->runs( theme => $theme, under => \@ranges, over => \@ranges );

The text cut at every start and end of a range, as
C<[ [ $from, $to, \%style ], ... ]> from 0 to the end of the text, in
order, each piece with the styles of the ranges that cover it composed
in this order (see L<Term::Fabulous::Text::Style/compose_styles>): the
C<under> ranges, the spans, the highlights, the C<over> ranges, each
list in its own order; palette tokens are resolved against C<theme>
(L<Term::Fabulous::Text::Style/resolve_style>). A piece no range covers
has the neutral style. C<under> and C<over> are optional and not checked
here: pass ranges with normalized style hashes, as L</check_spans>
returns them. A code block stacks its highlighter's spans under the
program's, a text the looks of its links over the highlights. Empty
ranges cover nothing. An empty text has no runs. The work is one sweep
over the boundaries. Dies without a C<theme> or with another option.

=head1 SEE ALSO

L<Term::Fabulous::Text::Style>, L<Term::Fabulous::Text::Markup>,
L<Term::Fabulous::Widget::Text>, L<Term::Fabulous::Widget::CodeBlock>,
L<Term::Fabulous::Role::MarkedText>.

=cut
