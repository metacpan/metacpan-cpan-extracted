package My::Markdown;

# Reads Markdown with Markdent and turns it into a Term::Fabulous::Document,
# for the recipes of Term::Fabulous::Cookbook::Documents and
# Term::Fabulous::Cookbook::DocumentTechniques. Headings,
# paragraphs, list items, block quotes, code blocks and horizontal rules
# become items through the factories of the document, with bold, italic
# and struck-through text, code and links as marks. A table becomes a
# Term::Fabulous::Widget::Table, a picture alone in its paragraph a
# Term::Fabulous::Widget::Image with its caption. HTML is left out.

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

class My::Markdown {
	use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM);
	use File::Basename qw(dirname);
	use File::Spec;
	use HTML::Entities qw(decode_entities);
	use List::Util qw(min);
	use Markdent::Handler::CaptureEvents;
	use Markdent::Parser;
	use Term::Fabulous::Document;
	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Widget::Image;
	use Term::Fabulous::Widget::Table;
	use Term::Fabulous::Widget::Text;

	use constant {
		BULLET_WIDTH   => 2,    # a bullet and a space
		NUMBER_WIDTH   => 4,    # room for "99. "
		PICTURE_ROWS   => 8,    # the height of a picture in the document
		PICTURE_COLUMN => 32,    # and its width
	};

	# The mark kind of each piece of inline markup Markdent reports
	my %MARK_KIND = ( strong => 'bold', emphasis => 'italic', strikethrough => 'strike', code => 'code', link => 'link' );

	field $document  :param;    # the document the items go into
	field $directory :param = '.';    # where the pictures of the source are
	field $page_size :param = 0;    # the rows of a table page; 0 shows a table whole

	field $open;    # the item whose text is being collected: { factory, arguments, options, text, marks, unfinished, pictures }
	field @lists;    # the lists the reader is in, outermost first: { numbered, position, indent, marker_width }
	field $quote = 0;    # how many block quotes the reader is in
	field $table;    # the table being read: { header => [ cells ], rows => [ [ cells ] ], in_header }
	field $tables = 0;    # the tables read so far, for their ids

	# A document from Markdown text. page_size gives the tables pages of
	# that many rows.
	method parse :common ( $source, %options ) {
		my $events = Markdent::Handler::CaptureEvents->new;
		Markdent::Parser->new( dialects => [ 'GitHub', 'Theory' ], handler => $events )->parse( markdown => $source );
		my $document = Term::Fabulous::Document->new( defined $options{source} ? ( source => $options{source} ) : () );
		$class->new( document => $document, map { exists $options{$_} ? ( $_ => $options{$_} ) : () } qw(directory page_size) )->_read( $events->captured_events->events );
		return $document;
	}

	method parse_file :common ( $path, %options ) {
		open my $handle, '<:encoding(UTF-8)', $path or die "My::Markdown: cannot read $path: $!\n";
		my $source = do { local $/; <$handle> };
		close $handle;
		return $class->parse( $source, %options, source => $path, directory => dirname($path) );
	}

	# Every event becomes a call of the method named after it; the inline
	# markup that becomes a mark is handled in one place. Events without
	# a method (HTML, the document itself) are skipped.
	method _read (@events) {
		foreach my $event (@events) {
			my $kind = $MARK_KIND{ lc $event->name };
			if ( defined $kind && $event->is_start ) {
				$self->_start_mark( $kind, $kind eq 'link' ? $event->uri : undef );
			}
			elsif ( defined $kind ) {
				$self->_end_mark;
			}
			elsif ( my $method = $self->can( '_' . $event->event_name ) ) {
				$self->$method($event);
			}
		}
		$self->_close_item;
		return;
	}

	# ---------------------------------------------------------------------
	# Items
	# ---------------------------------------------------------------------

	method _start_header ($event) {
		return $self->_open_item( heading => [ $event->level ] );
	}

	method _end_header ($event) {
		return $self->_close_item;
	}

	# The first paragraph of a list item is the text of the item; a later
	# one starts under it.
	method _start_paragraph ($event) {
		return if $open && $open->{factory} eq 'list_item';
		return $self->_open_item( paragraph => [] );
	}

	method _end_paragraph ($event) {
		return $self->_close_item;
	}

	method _start_unordered_list ($event) {
		return $self->_enter_list(0);
	}

	method _start_ordered_list ($event) {
		return $self->_enter_list(1);
	}

	method _end_unordered_list ($event) {
		return $self->_leave_list;
	}

	method _end_ordered_list ($event) {
		return $self->_leave_list;
	}

	method _start_list_item ($event) {
		my $list     = $lists[-1];
		my $position = ++$list->{position};
		return $self->_open_item(
			list_item    => [ $list->{numbered} ? "$position." : "\x{2022}" ],
			marker_width => $list->{marker_width},
			position     => $position,
			indent       => $list->{indent},
		);
	}

	# The text of a tight item has no paragraph around it, so the item is
	# still open here.
	method _end_list_item ($event) {
		return $self->_close_item;
	}

	method _start_blockquote ($event) {
		$self->_close_item;
		$quote++;
		return;
	}

	method _end_blockquote ($event) {
		$self->_close_item;
		$quote--;
		return;
	}

	# A fenced code block, with the word after the opening fence as its
	# language
	method _code_block ($event) {
		my $language = $event->language;
		$self->_close_item;
		$document->code( $event->code =~ s/\n\z//r, $self->_placed, defined $language && length $language ? ( language => $language ) : () );
		return;
	}

	# An indented code block
	method _preformatted ($event) {
		$self->_close_item;
		$document->code( $event->text =~ s/\n\z//r, $self->_placed );
		return;
	}

	method _horizontal_rule ($event) {
		$self->_close_item;
		$document->rule( $self->_placed );
		return;
	}

	# A nested list starts where the text of its parent item starts.
	method _enter_list ($numbered) {
		$self->_close_item;
		push @lists, { numbered => $numbered, position => 0, indent => $self->_indent, marker_width => $numbered ? NUMBER_WIDTH : BULLET_WIDTH };
		return;
	}

	method _leave_list () {
		$self->_close_item;
		pop @lists;
		return;
	}

	# Where the text after the marker of the current list item starts: the
	# indent of everything inside the item that is not its first paragraph.
	method _indent () {
		return 0 unless @lists;
		return $lists[-1]{indent} + $lists[-1]{marker_width};
	}

	# The options of an item at the place the reader is: its indent and
	# the quotes it is in.
	method _placed () {
		return ( indent => $self->_indent, quote => $quote );
	}

	# Starts collecting the text and marks of an item that a factory of the
	# document makes once its text is complete.
	method _open_item ( $factory, $arguments, %options ) {
		$self->_close_item;
		$open = { factory => $factory, arguments => $arguments, options => { $self->_placed, %options }, text => '', marks => [], unfinished => [], pictures => [] };
		return;
	}

	# Blank space at the end of the text is dropped, and a mark that
	# covered it ends with the text. A paragraph that holds nothing but a
	# picture becomes the picture.
	method _close_item () {
		return unless $open;
		my $item = $open;
		$open = undef;
		my $text     = $item->{text} =~ s/\s+\z//r;
		my @pictures = @{ $item->{pictures} };
		return $self->_add_picture( $pictures[0], $item->{options} ) if $item->{factory} eq 'paragraph' && @pictures == 1 && $text eq $pictures[0]{alt};
		my @marks   = map { [ $_->{start}, min( $_->{end}, length $text ), $_->{kind}, defined $_->{link} ? ( $_->{link} ) : () ] } $item->{marks}->@*;
		my $factory = $item->{factory};
		$document->$factory( @{ $item->{arguments} }, { text => $text, marks => [ grep { $_->[0] < $_->[1] } @marks ] }, %{ $item->{options} } );
		return;
	}

	# A picture with its caption under it, the alternative text, which a
	# search finds.
	method _add_picture ( $picture, $options ) {
		my $figure = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() } } );
		$figure->add_child(
			Term::Fabulous::Widget::Image->new(
				file => File::Spec->rel2abs( $picture->{uri}, $directory ), fit => 'contain', layout => { sizing => { width => sizing_fixed(PICTURE_COLUMN), height => sizing_fixed(PICTURE_ROWS) } }
			),
			Term::Fabulous::Widget::Text->new( text => $picture->{alt}, italic => 1 ),
		);
		$document->add( $figure, %$options );
		return;
	}

	# ---------------------------------------------------------------------
	# Tables: the cells are collected as plain text, and the table becomes
	# a Table widget with a column per cell of its header
	# ---------------------------------------------------------------------

	method _start_table ($event) {
		$self->_close_item;
		$table = { header => [], rows => [] };
		return;
	}

	method _start_table_header ($event) {
		$table->{in_header} = 1;
		return;
	}

	method _end_table_header ($event) {
		$table->{in_header} = 0;
		return;
	}

	method _start_table_row ($event) {
		push @{ $table->{ $table->{in_header} ? 'header' : 'rows' } }, [];
		return;
	}

	method _start_table_cell ($event) {
		$open = { factory => 'cell', text => '', marks => [], unfinished => [], pictures => [] };
		return;
	}

	method _end_table_cell ($event) {
		my $row = $table->{ $table->{in_header} ? 'header' : 'rows' }[-1];
		push @$row, $open->{text} =~ s/\A\s+|\s+\z//gr;
		$open = undef;
		return;
	}

	method _end_table ($event) {
		my $header  = @{ $table->{header} } ? $table->{header}[0] : shift @{ $table->{rows} };
		my @rows    = @{ $table->{rows} };
		my @columns = map { { key => "c$_", title => $header->[$_] } } 0 .. $#$header;
		my $id      = 0;
		my @data    = map {
			my $row = $_;
			+{ id => ++$id, map { ( "c$_" => $row->[$_] // '' ) } 0 .. $#$header }
		} @rows;
		$document->add(
			Term::Fabulous::Widget::Table->new(
				id        => 'table-' . ++$tables,
				columns   => \@columns,
				rows      => \@data,
				page_size => $page_size,
				layout    => { sizing => { width => sizing_grow() } },
			),
			$self->_placed
		);
		$table = undef;
		return;
	}

	# ---------------------------------------------------------------------
	# Text and marks
	# ---------------------------------------------------------------------

	# The text of an item arrives in pieces, between the events of its
	# marks. A line end is a space: the view wraps the text itself.
	method _text ($event) {
		return $self->_append( $event->text =~ s/\s*\n\s*/ /gr );
	}

	method _line_break ($event) {
		return $self->_append(' ');
	}

	method _html_entity ($event) {
		return $self->_append( decode_entities( '&' . $event->entity . ';' ) );
	}

	# A bare address is a link whose text is the address.
	method _auto_link ($event) {
		$self->_start_mark( link => $event->uri );
		$self->_append( $event->uri );
		return $self->_end_mark;
	}

	# A picture in the text shows its alternative text, in italics; alone
	# in a paragraph it becomes the picture itself (see _close_item).
	method _image ($event) {
		my $item = $self->_item_being_collected;
		push @{ $item->{pictures} }, { alt => $event->alt_text, uri => $event->uri };
		$self->_start_mark('italic');
		$self->_append( $event->alt_text );
		return $self->_end_mark;
	}

	method _append ($text) {
		my $item = $self->_item_being_collected;
		$text =~ s/\A\s+// unless length $item->{text};
		$item->{text} .= $text;
		return;
	}

	# A mark starts at the end of the text collected so far and ends at the
	# end of the text when its end event comes.
	method _start_mark ( $kind, $link = undef ) {
		my $item = $self->_item_being_collected;
		push $item->{unfinished}->@*, { kind => $kind, start => length $item->{text}, link => $link };
		return;
	}

	method _end_mark () {
		my $item = $self->_item_being_collected;
		my $mark = pop $item->{unfinished}->@*;
		push $item->{marks}->@*, { %$mark, end => length $item->{text} };
		return;
	}

	method _item_being_collected () {
		return $open // die "My::Markdown: text outside of an item\n";
	}
}

1;
