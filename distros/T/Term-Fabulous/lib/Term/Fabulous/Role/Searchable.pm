package Term::Fabulous::Role::Searchable;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Exporter 'import';
our @EXPORT_OK = qw(searchables_in nested_part nested_search_texts nested_search_revision nested_highlight_text nested_clear_text_highlights nested_reveal_text);

use Scalar::Util qw(blessed);
use Term::Fabulous::Check qw(describe);

# The widgets of a subtree that answer a search: a widget that does the
# role answers for everything inside it; the children of any other
# widget are looked at in layout order.
sub searchables_in ($widget) {
	return () unless blessed $widget;
	return $widget if $widget->DOES(__PACKAGE__);
	return () unless $widget->can('layout_children');
	return map { searchables_in($_) } @{ $widget->layout_children };
}

# A widget that holds other searchable widgets (the pages of a Tabs, the
# body of an accordion item) answers for them with keys of two parts:
# the index of the inner widget and that widget's own key.
sub nested_search_texts ($widgets) {
	return map {
		my $index = $_;
		map { [ [ $index, $_->[0] ], $_->[1] ] } $widgets->[$index]->search_texts
	} 0 .. $#$widgets;
}

# The inner widget a nested key names, and its own key; no widget when
# the index is past the widgets that exist now.
sub _nested ( $what, $widgets, $key ) {
	die "Term::Fabulous::Role::Searchable: $what needs a key of [ index, key ], got " . describe($key)
		unless ref $key eq 'ARRAY' && @$key == 2 && defined $key->[0] && !ref $key->[0] && $key->[0] =~ /\A[0-9]+\z/;
	return ( $widgets->[ $key->[0] ], $key->[1] );
}

sub nested_part ( $widgets, $key ) {
	my ($widget) = _nested( nested_part => $widgets, $key );
	return $widget;
}

# The revision names the widget at the index too: after the widgets
# changed, an old key may lead to another widget, whose own revision
# starts like any other.
sub nested_search_revision ( $widgets, $key ) {
	my ( $widget, $inner ) = _nested( nested_search_revision => $widgets, $key );
	return 'gone' unless defined $widget;
	return $widget->search_serial . ':' . $widget->search_revision($inner);
}

sub nested_highlight_text ( $widgets, $key, $ranges ) {
	my ( $widget, $inner ) = _nested( nested_highlight_text => $widgets, $key );
	$widget->highlight_text( $inner, $ranges ) if defined $widget;
	return;
}

sub nested_clear_text_highlights ($widgets) {
	$_->clear_text_highlights foreach @$widgets;
	return;
}

sub nested_reveal_text ( $widgets, $key, $offset ) {
	my ( $widget, $inner ) = _nested( nested_reveal_text => $widgets, $key );
	return [ undef, undef ] unless defined $widget;
	return $widget->reveal_text( $inner, $offset );
}

use Object::Pad 0.825;

role Term::Fabulous::Role::Searchable {
	method search_texts;
	method search_revision;
	method highlight_text;
	method clear_text_highlights;
	method reveal_text;

	# Numbers every searchable widget for the life of the process; an
	# address could be taken again by a widget made after one was freed.
	my $last_serial = 0;

	field $search_serial :reader;

	ADJUST {
		$search_serial = ++$last_serial;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Role::Searchable - The texts of a widget, for search and highlights

=head1 SYNOPSIS

	use Term::Fabulous::Role::Searchable qw(searchables_in);

	foreach my $widget ( searchables_in($item) ) {
		foreach my $entry ( $widget->search_texts ) {
			my ( $key, $text ) = @$entry;
			next unless $text =~ /needle/;
			$widget->highlight_text( $key, [ [ $-[0], $+[0], 'on yellow' ] ] );
			my ( $shown, $row ) = @{ $widget->reveal_text( $key, $-[0] ) };
		}
	}

=head1 DESCRIPTION

A widget that composes this role can be searched: it says which texts
it shows, marks ranges of a text with a style, and brings a text into
view inside itself. L<Term::Fabulous::Widget::Text> and
L<Term::Fabulous::Widget::CodeBlock> do it for the one text each of
them holds. A widget that builds its texts only when it needs them,
such as a L<table|Term::Fabulous::Widget::Table> with cells on other
pages, does it from its own data, so that a search reaches text that
is not on the screen. L<Term::Fabulous::Widget::DocumentView> searches
its items through this role.
L<Term::Fabulous::Cookbook::Documents/Search a document and show the reader's position (search, ViewChange)>
shows a search over a document;
L<Term::Fabulous::Manual::CustomWidgets/Widgets a search finds> shows
how to make a widget of your own searchable.

The role declares the methods below, which a class that composes it
defines, and provides L</search_serial>. A widget that holds other
searchable widgets and answers for them composes
L<Term::Fabulous::Role::SearchContainer> instead, which provides the
methods.

A I<key> names one text of the widget (see L</search_texts>). Keys are
only valid together with their revision: a caller that keeps a key (a
search that remembers its matches) keeps the
L</search_revision> it read with it, and compares the two before it
uses the key again; when the revision differs, the text changed and the
caller searches again.

=head1 REQUIRED METHODS

=head2 search_texts

	my @entries = $widget->search_texts;    # ( [ $key, $text ], ... )

The texts the widget shows, in the order they appear, each with a
I<key>: any value that names that text within the widget and stays the
same while the text exists, such as C<undef> for a widget with one
text, or a row and a column for a table cell. Offsets into C<$text> are
character offsets.

=head2 search_revision

	my $revision = $widget->search_revision($key);

A value that changes whenever the text named by the key changes, so a
caller can tell whether offsets it recorded earlier still point where
they did. Comparing two values with C<ne> is enough.

=head2 highlight_text

	$widget->highlight_text( $key, [ [ $start, $end, $style ], ... ] );

Marks ranges of the text named by the key with styles (strings or hash
references as L<Term::Fabulous::Text::Style> reads them), replacing the
ranges given before for that text. The widget shows them over its own
styles whenever it shows that text, also when it builds the widget for
it later. Offsets past the text die.

=head2 clear_text_highlights

	$widget->clear_text_highlights;

Removes every highlight of every text of the widget.

=head2 reveal_text

	my ( $shown, $row ) = @{ $widget->reveal_text( $key, $offset ) };

Makes the text named by the key visible inside the widget, as far as the
widget can: a table turns to the page of the row, a tab control
activates the page. Returns an array reference of two values, each of
which may be C<undef>: the widget that shows the text (a Text inside the
widget, such as a table's cell, or the widget itself, as a Text or a
CodeBlock returns), once it exists, and the row within the widget on
which the character at the offset lies, when the widget knows it before
a layout (a code block knows its line). A caller that scrolls the widget
into view uses the row, else the text widget's painted lines, else the
widget's own box.

=head1 PROVIDED METHODS

=head2 search_serial

	my $serial = $widget->search_serial;

A number that names the widget among all searchable widgets made by the
process, given at construction and never reused, also not after the
widget is freed. L</nested_search_revision> puts it into the revisions
of the texts a container answers for, so that a key that leads to
another widget after the widgets changed reads as changed.

=head1 FUNCTIONS

=head2 searchables_in

	my @widgets = searchables_in($widget);

The widgets at or below C<$widget> that compose this role, in layout
order: C<$widget> itself if it does, else those found among its
layout children, the children of a widget that does the role not
included (it answers for them). Exported on request.

=head2 Nested keys

The functions below are the role's methods for a widget that answers
for searchable widgets inside it (its I<parts>):
C<\@widgets> are those widgets (from L</searchables_in>), and a key names
one by its index in the list and that widget's own key,
C<[ $index, $key ]>. Keys are positions, so a key still means "the same
place" after its widget was built again (a table re-applies highlights
to rebuilt cells by position). A key whose index is past the list names
no widget; a key that is not C<[ index, key ]> dies.
L<Term::Fabulous::Role::SearchContainer> provides the role's methods
with them, for L<Term::Fabulous::Widget::Tabs> and
L<Term::Fabulous::Widget::Accordion::Item>;
L<Term::Fabulous::Widget::Table> calls them for the widgets of its
custom cells. All exported on request.

=head2 nested_part

	my $widget = nested_part( \@widgets, $key );

The widget the key names, or C<undef> when its index is past the list.

=head2 nested_search_texts

	my @entries = nested_search_texts( \@widgets );    # keys [ $index, $key ]

The texts of all the widgets, in order, with nested keys.

=head2 nested_search_revision

	my $revision = nested_search_revision( \@widgets, $key );

The L</search_serial> of the widget at the index and that widget's own
revision of the text, C<"$serial:$revision">: when another widget comes
to the index (a page was removed before it), the revision changes, so a
caller that compares revisions searches again instead of using the key.
C<'gone'> for a key whose index is past the list.

=head2 nested_highlight_text

	nested_highlight_text( \@widgets, $key, \@ranges );

Highlights the text in the widget the key names; nothing for a key past
the list.

=head2 nested_clear_text_highlights

	nested_clear_text_highlights( \@widgets );

Clears the highlights of every widget.

=head2 nested_reveal_text

	my $revealed = nested_reveal_text( \@widgets, $key, $offset );

The widget's C<reveal_text>; C<[ undef, undef ]> for a key past the list.

=head1 SEE ALSO

L<Term::Fabulous::Role::SearchContainer>,
L<Term::Fabulous::Role::MarkedText>, L<Term::Fabulous::Widget::Text>,
L<Term::Fabulous::Widget::CodeBlock>, L<Term::Fabulous::Widget::Table>,
L<Term::Fabulous::Widget::Tabs>,
L<Term::Fabulous::Widget::Accordion::Item>,
L<Term::Fabulous::Widget::DocumentView>,
L<Term::Fabulous::Manual::CustomWidgets/Widgets a search finds>.

=cut
