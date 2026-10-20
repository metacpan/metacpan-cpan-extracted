package Term::Fabulous::Document;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Text;

our $VERSION = '0.05';

# The marker of a list item: a text a search passes over, since the
# bullets and numbers of a list are not content.
class Term::Fabulous::Document::Marker :isa(Term::Fabulous::Widget::Text) :strict(params) {

	method search_texts :override () {
		return ();
	}
}

class Term::Fabulous::Document :strict(params) {
	use Clay::UI::Role::Layout::HasParent qw(is_widget);
	use Clay::XS qw(sizing_fixed sizing_grow CLAY_LEFT_TO_RIGHT CLAY_TOP_TO_BOTTOM);
	use List::Util qw(first);
	use Scalar::Util qw(blessed refaddr weaken);
	use Term::Fabulous::Check qw(boolean describe non_negative_integer positive_integer string);
	use Term::Fabulous::Document::Look;
	use Term::Fabulous::Role::Searchable qw(searchables_in);
	use Term::Fabulous::Text::Markup qw(parse_markup);
	use Term::Fabulous::Unicode qw(string_columns);
	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Widget::CodeBlock;
	use Term::Fabulous::Widget::Divider;

	my @OPTIONS = qw(gap indent flush quote rows section anchor);
	my %OPTION  = map { $_ => 1 } @OPTIONS;

	field $source :param :reader = undef;
	field $look   :param :reader = 'Term::Fabulous::Document::Look';

	# The items, how the view lays each out ({ gap, indent, flush, quote,
	# rows }), and what a factory needs to know of the item before the
	# next one ({ kind, indent, position }).
	field @items;
	field @options;
	field @facts;
	field %index_of;    # refaddr of an item => its index

	field @sections;    # [ item index, level, title ]
	field @anchors;    # [ name, item index ]
	field @code_blocks;    # the code blocks the factories made

	# The view that shows the document, weak; one at a time.
	field $view;

	ADJUST {
		$source = string( $self, source => $source ) if defined $source;
		die "Term::Fabulous::Document: look must be the name of a loaded Term::Fabulous::Document::Look class, got " . describe($look)
			unless defined $look && !ref $look && length $look && $look->isa('Term::Fabulous::Document::Look');
	}

	# ---------------------------------------------------------------------
	# Items
	# ---------------------------------------------------------------------

	method add ( $widget, %given ) {
		die "Term::Fabulous::Document: add needs a widget, got " . describe($widget)
			unless is_widget($widget);
		my $known = $index_of{ refaddr $widget };
		die "Term::Fabulous::Document: the widget is item $known of the document already" if defined $known;
		die "Term::Fabulous::Document: add needs a widget without a parent; this one is a child of " . ref( $widget->parent ) if defined $widget->parent;
		my @unknown = sort grep { !$OPTION{$_} } keys %given;
		die "Term::Fabulous::Document: unknown option(s) @unknown (known: @OPTIONS)" if @unknown;

		my %option = (
			gap    => non_negative_integer( $self, gap    => $given{gap}    // 1 ),
			indent => non_negative_integer( $self, indent => $given{indent} // 0 ),
			flush  => boolean( $self, flush => $given{flush} // 0 ),
			quote  => non_negative_integer( $self, quote => $given{quote} // 0 ),
			rows   => defined $given{rows} ? non_negative_integer( $self, rows => $given{rows} ) : undef,
		);
		my $index   = scalar @items;
		my $section = defined $given{section} ? $self->_checked_section_option( $given{section} )        : undef;
		my $anchor  = defined $given{anchor}  ? _normalized( string( $self, anchor => $given{anchor} ) ) : undef;

		push @items,   $widget;
		push @options, \%option;
		push @facts, { kind => 'widget', indent => $option{indent}, position => 1 };
		push @sections, [ $index,  @$section ] if defined $section;
		push @anchors,  [ $anchor, $index ] if defined $anchor && length $anchor;
		$index_of{ refaddr $widget } = $index;
		return $widget;
	}

	method _checked_section_option ($section) {
		die "Term::Fabulous::Document: section must be [ level, title ], got " . describe($section) unless ref $section eq 'ARRAY' && @$section == 2;
		my ( $level, $title ) = @$section;
		die "Term::Fabulous::Document: a section level is an integer from 1 to 6, got " . describe($level) unless defined $level && !ref $level && $level =~ /\A[1-6]\z/;
		return [ $level + 0, string( $self, 'section title', $title ) ];
	}

	method items () {
		return @items;
	}

	method count () {
		return scalar @items;
	}

	method item ($index) {
		return $items[ $self->_checked_index( item => $index ) ];
	}

	method options_of ($index) {
		return { %{ $options[ $self->_checked_index( options_of => $index ) ] } };
	}

	# What made the item: the name of the factory, or widget for an item
	# given to add.
	method kind_of ($index) {
		return $facts[ $self->_checked_index( kind_of => $index ) ]{kind};
	}

	method index_of ($widget) {
		return blessed $widget ? $index_of{ refaddr $widget } : undef;
	}

	method code_blocks () {
		return @code_blocks;
	}

	# The index of an item of the document, or a death that says why not.
	method _checked_index ( $method, $index ) {
		die "Term::Fabulous::Document: $method needs an index, got " . describe($index) unless defined $index && !ref $index && $index =~ /\A[0-9]+\z/;
		die "Term::Fabulous::Document: item $index does not exist, the document has " . scalar(@items) . " items" unless $index < @items;
		return $index;
	}

	# The texts of an item, the item itself first, in tree order: where
	# its links are.
	method texts ($index) {
		my $item = $self->item($index);
		return grep { $_->isa('Term::Fabulous::Widget::Text') } $item->subtree;
	}

	method searchables ($index) {
		return searchables_in( $self->item($index) );
	}

	# ---------------------------------------------------------------------
	# The view that shows the document
	# ---------------------------------------------------------------------

	method shown_by () {
		return $view;
	}

	# For Term::Fabulous::Widget::DocumentView: the items are children of
	# the slots of one view, so a second view cannot show them too.
	method _attach_view ($new) {
		if ( defined $view && refaddr($view) != refaddr($new) ) {
			my $id = $view->can('id') ? $view->id : undef;
			die "Term::Fabulous::Document: the document is shown by the " . ref($view) . ( defined $id ? " '$id'" : '' ) . " already; a document is shown by one view at a time";
		}
		$view = $new;
		weaken $view;
		return;
	}

	method _detach_view ($old) {
		$view = undef if defined $view && refaddr($view) == refaddr($old);
		return;
	}

	# ---------------------------------------------------------------------
	# Factories: the common items, made from text and marks
	# ---------------------------------------------------------------------

	method heading ( $level, $content, %options ) {
		die "Term::Fabulous::Document: a heading level is an integer from 1 to 6, got " . describe($level) unless defined $level && !ref $level && $level =~ /\A[1-6]\z/;
		my $text   = $self->_text( heading => $content, $self->_style_of("heading$level") );
		my $widget = $level == 1 ? _stack( $text, Term::Fabulous::Widget::Divider->new ) : $text;
		return $self->_add_made( heading => $widget, 1, flush => 1, section => [ $level, $text->text ], %options );
	}

	method paragraph ( $content, %options ) {
		return $self->_add_made( paragraph => $self->_text( paragraph => $content ), 1, %options );
	}

	method term ( $content, %options ) {
		my $text = $self->_text( term => $content, $self->_style_of('term') );
		return $self->_add_made( term => $text, 1, anchor => $text->text, %options );
	}

	# A row of two columns: the marker in a column of its own, so that the
	# lines of the text start after it, a hanging indent done by the
	# layout; then the text.
	method list_item ( $marker, $content, %options ) {
		$marker = string( $self, marker => $marker );
		die "Term::Fabulous::Document: an item needs a marker" unless length $marker;
		my $columns  = string_columns($marker);
		my $width    = positive_integer( $self, marker_width => delete $options{marker_width} // $columns + 1 );
		my $position = positive_integer( $self, position     => delete $options{position}     // 1 );
		die "Term::Fabulous::Document: marker_width $width leaves no space after the marker '$marker' ($columns columns)" if $width <= $columns;

		my $mark   = Term::Fabulous::Document::Marker->new( text => $marker, spans => [ [ 0, length $marker, $self->_style_of('marker') ] ] );
		my $column = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed($width) } } );
		$column->add_child($mark);
		my $row = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_LEFT_TO_RIGHT, sizing => { width => sizing_grow() } } );
		$row->add_child( $column, $self->_text( item => $content ) );
		return $self->_add_made( item => $row, $position, %options );
	}

	method code ( $code, %options ) {
		my $language = delete $options{language};
		my $block    = Term::Fabulous::Widget::CodeBlock->new(
			code       => string( $self, code => $code ),
			look_class => $look,
			layout     => { sizing => { width => sizing_grow() } },
			defined $language ? ( language => $language ) : (),
		);
		push @code_blocks, $block;
		return $self->_add_made( code => $block, 1, %options );
	}

	method rule (%options) {
		return $self->_add_made( rule => Term::Fabulous::Widget::Divider->new, 1, %options );
	}

	sub _stack (@children) {
		my $box = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() } } );
		$box->add_child(@children);
		return $box;
	}

	# Adds what a factory made, with the blank rows the factory rules give
	# unless the caller gives them, and records what the next factory needs.
	method _add_made ( $kind, $widget, $position, %options ) {
		my $indent = $options{indent} // 0;
		$options{gap} //= $self->_gap_before( $kind, $indent, $position );
		$self->add( $widget, %options );
		$facts[-1] = { kind => $kind, indent => $indent, position => $position };
		return $widget;
	}

	# No blank row between the items of a list, nor before the first item
	# of a list nested in the item above it, nor between a term and its
	# definition (anything indented deeper than the term); one otherwise.
	method _gap_before ( $kind, $indent, $position ) {
		my $previous = $facts[-1] // return 1;
		return 0 if $kind eq 'item' && $previous->{kind} eq 'item' && ( $position > 1 || $indent > $previous->{indent} );
		return 0 if $kind ne 'term' && $previous->{kind} eq 'term' && $indent > $previous->{indent};
		return 1;
	}

	method _style_of ($kind) {
		return $look->token_style($kind);
	}

	# A text from a string, { text => ..., marks => [ [ start, end, kind,
	# link ], ... ] } or { markup => ... }, with the base styles over the
	# whole text below the styles of its marks.
	method _text ( $what, $content, @base ) {
		my ( $text, $spans, $links );
		if ( !ref $content ) {
			( $text, $spans, $links ) = ( string( $self, $what, $content ), [], [] );
		}
		elsif ( ref $content eq 'HASH' && exists $content->{markup} ) {
			die "Term::Fabulous::Document: markup cannot be given together with text or marks" if keys %$content > 1;
			( $text, $spans, $links ) = parse_markup( string( $self, "$what markup", $content->{markup} ) );
		}
		elsif ( ref $content eq 'HASH' ) {
			my @unknown = sort grep { $_ ne 'text' && $_ ne 'marks' } keys %$content;
			die "Term::Fabulous::Document: a $what does not know @unknown (known: text, marks, markup)" if @unknown;
			$text = string( $self, "$what text", $content->{text} // '' );
			( $spans, $links ) = $self->_spans_and_links( $what, $content->{marks} // [] );
		}
		else {
			die "Term::Fabulous::Document: a $what needs a string, { text => ..., marks => [...] } or { markup => ... }, got " . describe($content);
		}
		my $length = length $text;
		return Term::Fabulous::Widget::Text->new( text => $text, spans => [ ( map { [ 0, $length, $_ ] } @base ), @$spans ], links => $links );
	}

	# Marks as spans in the styles of their kinds, and links.
	method _spans_and_links ( $what, $marks ) {
		die "Term::Fabulous::Document: the marks of a $what must be an array reference, got " . describe($marks) unless ref $marks eq 'ARRAY';
		my ( @spans, @links );
		foreach my $mark (@$marks) {
			die "Term::Fabulous::Document: a mark is [ start, end, kind ] or [ start, end, 'link', target ], got " . describe($mark) unless ref $mark eq 'ARRAY' && ( @$mark == 3 || @$mark == 4 );
			my ( $start, $end, $kind, $target ) = @$mark;
			if ( defined $kind && !ref $kind && $kind eq 'link' ) {
				push @links, [ $start, $end, $target ];
				next;
			}
			die "Term::Fabulous::Document: only a mark of kind link has a target" if @$mark == 4;
			push @spans, [ $start, $end, $self->_style_of($kind) ];
		}
		return ( \@spans, \@links );
	}

	# ---------------------------------------------------------------------
	# Sections
	# ---------------------------------------------------------------------

	method sections () {
		return map { { item => $_->[0], level => $_->[1], title => $_->[2] } } @sections;
	}

	method section_count () {
		return scalar @sections;
	}

	# A section number, as section_at returns it, or a death that says why
	# not.
	method _checked_section ( $method, $number ) {
		die "Term::Fabulous::Document: $method needs a section number, got " . describe($number) unless defined $number && !ref $number && $number =~ /\A[0-9]+\z/;
		die "Term::Fabulous::Document: section $number does not exist, the document has " . scalar(@sections) . " sections" unless $number < @sections;
		return $number;
	}

	method item_of_section ($number) {
		return $sections[ $self->_checked_section( item_of_section => $number ) ][0];
	}

	method level_of_section ($number) {
		return $sections[ $self->_checked_section( level_of_section => $number ) ][1];
	}

	method title_of_section ($number) {
		return $sections[ $self->_checked_section( title_of_section => $number ) ][2];
	}

	# The number of the section the item is in: the last section that
	# starts at or before it. undef for items before the first section.
	method section_at ($index) {
		$index = $self->_checked_index( section_at => $index );
		my ( $low, $high ) = ( 0, $#sections );
		return undef if $high < 0 || $sections[0][0] > $index;
		while ( $low < $high ) {
			my $middle = int( ( $low + $high + 1 ) / 2 );
			if   ( $sections[$middle][0] <= $index ) { $low  = $middle }
			else                                     { $high = $middle - 1 }
		}
		return $low;
	}

	sub _normalized ($text) {
		return join ' ', split ' ', $text;
	}

	# The item a link to the section leads to. Sections come before
	# anchors, exact matches before matches that ignore case, and those
	# before a title or anchor that starts with the name as a word
	# ("open" finds "open FILEHANDLE,EXPR" in perlfunc).
	method find_section ($name) {
		die "Term::Fabulous::Document: find_section needs a section name, got " . describe($name) unless defined $name && !ref $name;
		my $wanted = _normalized($name);
		return undef unless length $wanted;

		my @targets = ( ( map { [ _normalized( $_->[2] ), $_->[0] ] } @sections ), @anchors );
		my @rules   = (
			sub ($text) { $text eq $wanted },
			sub ($text) { fc($text) eq fc($wanted) },
			sub ($text) { $text =~ /\A\Q$wanted\E(?!\w)/ },
			sub ($text) { $text =~ /\A\Q$wanted\E(?!\w)/i },
		);
		foreach my $rule (@rules) {
			my $found = first { $rule->( $_->[0] ) } @targets;
			return $found->[1] if defined $found;
		}
		return undef;
	}

	# ---------------------------------------------------------------------
	# Searching
	# ---------------------------------------------------------------------

	# Every occurrence of the text in the texts the searchable widgets of
	# the items show (Term::Fabulous::Role::Searchable), as [ item index,
	# widget, key, start, end ], in the order of the document. A query
	# without capital letters ignores case.
	method find_text ($query) {
		die "Term::Fabulous::Document: find_text needs a string, got " . describe($query) unless defined $query && !ref $query;
		return () unless length $query;
		my $pattern = $query =~ /\p{Lu}/ ? qr/\Q$query\E/ : qr/\Q$query\E/i;

		my @matches;
		foreach my $index ( 0 .. $#items ) {
			foreach my $widget ( searchables_in( $items[$index] ) ) {
				foreach my $entry ( $widget->search_texts ) {
					my ( $key, $text ) = @$entry;
					push @matches, [ $index, $widget, $key, $-[0], $+[0] ] while $text =~ /$pattern/g;
				}
			}
		}
		return @matches;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Document - A document: a list of widgets with the
sections and the layout a document view shows them with

=head1 SYNOPSIS

	use Term::Fabulous::Document;
	use Term::Fabulous::Widget::DocumentView;
	use Term::Fabulous::Widget::Table;

	my $document = Term::Fabulous::Document->new( source => 'snapback.md' );
	$document->heading( 1, 'snapback' );
	$document->paragraph( { text => 'Copies files to a backup disk.', marks => [ [ 0, 6, 'bold' ] ] } );
	$document->heading( 2, 'Usage' );
	$document->code( "snapback ~/Documents /mnt/backup", language => 'shell' );
	$document->list_item( "\x{2022}", { text => 'Keeps the last 14 backups.', marks => [ [ 15, 17, 'code' ] ] } );
	$document->paragraph( { markup => 'See [link=faq.md]the FAQ[/].' } );

	# Any widget is an item: a table, a picture, a form.
	$document->add( Term::Fabulous::Widget::Table->new( id => 'releases', columns => [...], rows => [...] ) );

	my $view = Term::Fabulous::Widget::DocumentView->new( id => 'manual', document => $document );

=head1 DESCRIPTION

A document is what a L<Term::Fabulous::Widget::DocumentView> shows: an
ordered list of I<items>, each a widget, with a few options that say
how the view lays the item out, and the I<sections> and I<anchors> that
links lead to. A parser makes one from a file: it calls the
L</FACTORIES> for the common items, headings, paragraphs, list items,
terms, code and rules, and L</add> for any other widget. The document
knows nothing of the screen; it can be made and inspected without a
terminal.

An item is any widget without a parent: a L<Term::Fabulous::Widget::Text>,
a box of several widgets, a L<table|Term::Fabulous::Widget::Table>, a
form with buttons. The view searches the texts of every item through
L<Term::Fabulous::Role::Searchable>, selects and follows the links of
every L<Term::Fabulous::Widget::Text> in them, and lets the user reach
their interactive widgets with Tab.

Every item belongs to the document while the document exists, and is
shown by one view at a time: the view wraps each item in a box of its
own (see L<Term::Fabulous::Widget::DocumentView/How items are shown>).

Worked examples are in L<Term::Fabulous::Cookbook::Documents> and
L<Term::Fabulous::Cookbook::DocumentTechniques>:
L<Term::Fabulous::Cookbook::Documents/Show a document built in Perl (Document, factories, marks)>
builds a document with the factories,
L<Term::Fabulous::Cookbook::Documents/Turn Markdown into a document (Markdent)> is a reader, and
L<Term::Fabulous::Cookbook::DocumentTechniques/Put any widget into a document (a table and a picture)> adds
widgets of other kinds.

=head2 Item options

L</add> and every factory take these options, which the view applies
when it shows the item:

=over

=item C<gap>

The blank rows above the item, a non-negative integer. Default: 1 for
L</add>; the factories choose (see L</FACTORIES>). The first item of a
document never has blank rows above it.

=item C<indent>

Columns by which the item is indented, on top of the view's own
L<indent|Term::Fabulous::Widget::DocumentView/indent>. Default: 0.

=item C<flush>

A boolean: the item ignores the view's indent and starts at the left
edge (plus its own C<indent>). Default: 0; headings are flush.

=item C<quote>

The number of block quotes the item is in, a non-negative integer. The
view draws a bar on its left for each. Default: 0.

=item C<rows>

The rows the item takes, when it is known before the item is laid out
and the item's own estimate is not good enough. Default: none; the view
asks the widget (L<Term::Fabulous::Widget/estimated_rows>). A wrong
number does no harm beyond a scrollbar that jumps a little when the
item comes into view.

=item C<section>

C<[ $level, $title ]>: the item starts a section, with a level from 1
to 6 and a title. Sections make the table of contents and the section
of L<Term::Fabulous::Event::ViewChange>, and L</find_section> finds
them. Headings start sections.

=item C<anchor>

A name links can lead to (L</find_section>), such as the text of a
term.

=back

An unknown option and an invalid value die.

=head1 CONSTRUCTOR

=head2 new

	my $document = Term::Fabulous::Document->new( source => $path, look => 'My::Look' );

Creates an empty document. Both parameters are optional:

=over

=item C<source>

A string: where the document came from, a file name for instance, for
the program to show or to resolve relative links with. Default: none.

=item C<look>

The name of a loaded L<Term::Fabulous::Document::Look> class, whose
kinds the factories style marks with, and whose C<code_block> and
C<clipped> styles code blocks paint with. Default:
C<Term::Fabulous::Document::Look>. A reader with mark kinds of its own
names a subclass (see L<Term::Fabulous::Document::Look/Changing and adding kinds>).

=back

=head1 FACTORIES

Each factory makes an item, adds it with the given L</Item options>,
and returns the widget. A text is given as one of:

=over

=item * a string, the plain text;

=item * C<< { text => $text, marks => [ [ $start, $end, $kind ], [ $start, $end, 'link', $target ], ... ] } >>:
the text and its I<marks>, ranges of character offsets (the start and
the offset after the end) with a kind of the document's look (C<bold>,
C<italic>, C<code>, C<file>, ...; see L<Term::Fabulous::Document::Look/KINDS>)
or C<link> with a target, any defined value that
L<LinkActivate|Term::Fabulous::Event::LinkActivate> hands back;

=item * C<< { markup => $markup } >>: markup as
L<Term::Fabulous::Text::Markup> reads it, styles and links included.
Its tags are style strings and palette tokens, not the kinds of the
look: C<[bold]> and C<[link=faq.md]> work, C<[code]> dies.

=back

Marks may overlap, links may not. A kind the look does not know, a mark
past the text and an invalid shape die. The styles are palette tokens
of the theme (L<Term::Fabulous::Document::Look/token_style>), so a
theme switch recolors the document without any work.

Unless the C<gap> option says otherwise, a factory puts one blank row
above its item, with two exceptions: none between the items of a list
(a list item whose C<position> is above 1, right after another list
item), nor before the first item of a list nested in the list item
above it (indented deeper); and
none between a term and the item after it, if that item is not a term
and is indented deeper than the term, its definition.

=head2 heading

	my $widget = $document->heading( $level, $text, %options );

A heading of level 1 to 6, in the style of its level (C<heading1> to
C<heading6>); a first-level heading has a horizontal rule under it. It
is C<flush>, and starts a section with its text as the title. Returns
the Text, or for level 1 a L<Term::Fabulous::Widget::Box> that holds
the Text and a L<Term::Fabulous::Widget::Divider>.

=head2 paragraph

	my $text = $document->paragraph( $text, %options );

A paragraph: a L<Term::Fabulous::Widget::Text> that the view wraps to
its width.

=head2 term

	my $text = $document->term( $text, %options );

The term of a definition list, in the C<term> style, with its text as an
anchor. Give the paragraph that defines it a deeper C<indent>, and it
follows the term without a blank row.

=head2 list_item

	my $row = $document->list_item( $marker, $text, marker_width => 3, position => 1, %options );

An item of a list: the marker (a bullet or a number, in the C<marker>
style, which a search passes over) in a column of its own, and the
text, whose lines all start after the marker. C<marker_width> is the
columns from the start of the marker to the start of the text, at least
one more than the marker takes (the default); give all items of a list
the same width so that their texts line up. C<position> counts the
items of a list from 1 (the default); an item with position 1 starts a
new list, with a blank row above. A nested list is a list with a
deeper C<indent>: the parent's C<indent> plus its C<marker_width>.

=head2 code

	my $block = $document->code( $code, language => 'perl', %options );

A L<Term::Fabulous::Widget::CodeBlock>: code that keeps its lines and
never wraps, in the document look's C<code_block> style. The optional
C<language> goes to the view's
L<highlighter|Term::Fabulous::Widget::DocumentView/highlighter>.

=head2 rule

	my $divider = $document->rule(%options);

A horizontal rule, a L<Term::Fabulous::Widget::Divider> across the view.

=head1 METHODS

=head2 add

	my $widget = $document->add( $widget, %options );

Adds a widget as the next item, with the L</Item options>, and returns
it. The widget must be an element or a text without a parent, and not
an item already; anything else dies. Items can be added while a view
shows the document: the view shows them from its next frame.

=head2 items, count, item

	my @widgets = $document->items;
	my $count   = $document->count;
	my $widget  = $document->item($index);

The items, their number, and the item with an index from 0. An index
that is no item dies.

=head2 options_of

	my $options = $document->options_of($index);    # { gap, indent, flush, quote, rows }

How the view lays the item out, as a new hash.

=head2 kind_of

	my $kind = $document->kind_of($index);    # 'heading', 'paragraph', 'term', 'item', 'code', 'rule' or 'widget'

What made an item: the factory (C<item> for L</list_item>), or C<widget>
for an item given to L</add>.

=head2 index_of

	my $index = $document->index_of($widget);    # or undef

The index of an item, or C<undef> for a widget that is no item (one
inside an item, say).

=head2 texts, searchables

	my @texts       = $document->texts($index);
	my @searchables = $document->searchables($index);

The L<Term::Fabulous::Widget::Text> widgets of an item, the item itself
included, in tree order (where its links are), and the widgets of the
item that answer a search (L<Term::Fabulous::Role::Searchable/searchables_in>).
The marker of a list item is one of its texts: a
C<Term::Fabulous::Document::Marker>, a Text that a search passes over,
since bullets and numbers are not content.

=head2 code_blocks

	my @blocks = $document->code_blocks;

The code blocks the L</code> factory made, which the view gives its
highlighter.

=head2 sections, section_count

	foreach my $section ( $document->sections ) {
		say '  ' x ( $section->{level} - 1 ), $section->{title};    # a table of contents
	}

The sections in the order of the document, each as a new hash with the
C<item> index it starts at, its C<level> and its C<title>, and their
number.
L<Term::Fabulous::Cookbook::DocumentTechniques/Show a table of contents beside the document (sections, KDL)>
lists them beside the document.

=head2 item_of_section, level_of_section, title_of_section

	my $index = $document->item_of_section(3);

The item a section starts at, its level and its title, by the number of
the section from 0. A number that is no section dies.

=head2 section_at

	my $number = $document->section_at($index);    # or undef

The number of the section an item is in: the last section that starts
at or before it. C<undef> for an item before the first section.

=head2 find_section

	my $index = $document->find_section('Methods');    # or undef

The item a link to a section leads to. The name is compared, with
whitespace squeezed, in four rounds: exactly, then ignoring case, then
as a title or anchor that starts with the name as a word (C<open> finds
C<open FILEHANDLE,EXPR>), then the same ignoring case. In each round
the titles of the sections come before the anchors, so an anchor that
matches exactly wins over a title that matches only when case is
ignored. C<undef> when nothing matches or the name is empty.
L<Term::Fabulous::Cookbook::Documents/Follow links: jump to sections, open other pages, go back (LinkActivate)>
uses it to follow a link to a section.

=head2 find_text

	foreach my $match ( $document->find_text('needle') ) {
		my ( $index, $widget, $key, $start, $end ) = @$match;
	}

Every occurrence of the text in the texts the searchable widgets of the
items show, in the order of the document: the item, the widget that
shows the text, the text's key (see
L<Term::Fabulous::Role::Searchable/search_texts>) and the offsets of
the match. A query without capital letters ignores case; it is text,
not a pattern. Matches do not overlap. The view's
L<search|Term::Fabulous::Widget::DocumentView/search> builds on it; see
L<Term::Fabulous::Cookbook::Documents/Search a document and show the reader's position (search, ViewChange)>.

=head2 source, look

The values of the constructor parameters.

=head2 shown_by

	my $view = $document->shown_by;    # or undef

The view that shows the document. A document is shown by one view at a
time; giving it to a second one dies.

=head1 SEE ALSO

L<Term::Fabulous::Widget::DocumentView>, L<Term::Fabulous::Document::Look>,
L<Term::Fabulous::Role::Searchable>, L<Term::Fabulous::Cookbook::Documents>,
L<Term::Fabulous::Cookbook::DocumentTechniques>.

=cut
