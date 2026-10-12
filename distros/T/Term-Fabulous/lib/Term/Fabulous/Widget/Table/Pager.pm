package Term::Fabulous::Widget::Table::Pager;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Button;
use Term::Fabulous::Widget::Dropdown;
use Term::Fabulous::Widget::Text;

class Term::Fabulous::Widget::Table::Pager :isa(Term::Fabulous::Widget::Box) :strict(params) {
	use Clay::XS qw(sizing_grow sizing_fit CLAY_ALIGN_Y_CENTER CLAY_LEFT_TO_RIGHT_WRAP CLAY_LINE_SIZING_FIT CLAY_TEXT_WRAP_NONE);
	use Term::Fabulous::Check qw(color);

	# The buttons by what they do, and the texts and the page size list.
	field %button;
	field $page_text;
	field $count_text;
	field $size_label;
	field $size_list :reader;

	field $text_color   :param = [ 220, 223, 228, 255 ];
	field $muted_color  :param = [ 140, 146, 158, 255 ];
	field $button_color :param = [ 44,  49,  60,  255 ];
	field $page_sizes   :param;

	ADJUST {
		$text_color   = color( $self, text_color   => $text_color );
		$muted_color  = color( $self, muted_color  => $muted_color );
		$button_color = color( $self, button_color => $button_color );
		die "Term::Fabulous::Widget::Table::Pager: page_sizes must be an array reference of positive integers"
			unless ref $page_sizes eq 'ARRAY' && @$page_sizes && !grep { !defined || ref || !/\A[1-9][0-9]*\z/ } @$page_sizes;

		# Three groups that flow onto a second line when the table is narrow.
		$self->layout(
			{
				layout_direction => CLAY_LEFT_TO_RIGHT_WRAP,
				line_sizing      => CLAY_LINE_SIZING_FIT,
				child_gap        => 3,
				sizing           => { width => sizing_grow(), height => sizing_fit() },
			}
		);
		my %glyph = ( first => "\x{00AB}", previous => "\x{2039}", next => "\x{203A}", last => "\x{00BB}" );
		foreach my $name (qw(first previous next last)) {
			my $button = Term::Fabulous::Widget::Button->new(
				can_focus                => 0,
				background_color         => $button_color,
				disabled_color           => $muted_color,
				pressed_background_color => 'reverse',
				layout                   => { padding => { left => 1, right => 1 } },
			);
			$button->add_child( Term::Fabulous::Widget::Text->new( text => $glyph{$name}, text_color => $text_color ) );
			$button{$name} = $button;
		}
		my $text = sub ( $value, $color ) { Term::Fabulous::Widget::Text->new( text => $value, text_color => $color, wrap_mode => CLAY_TEXT_WRAP_NONE ) };
		$page_text  = $text->( '',              $text_color );
		$count_text = $text->( '',              $muted_color );
		$size_label = $text->( 'Rows per page', $muted_color );
		$size_list  = Term::Fabulous::Widget::Dropdown->new( options => [ map { [ "$_" => $_ + 0 ] } @$page_sizes ], text_color => $text_color );
		my $group = sub (@children) {
			my $box = Term::Fabulous::Widget::Box->new( layout => { child_gap => 1, child_alignment => { y => CLAY_ALIGN_Y_CENTER } } );
			$box->add_child(@children);
			return $box;
		};
		$self->add_child( $group->( @button{qw(first previous)}, $page_text, @button{qw(next last)} ), $group->( $size_label, $size_list ), $count_text );
	}

	method button ($name) {
		return $button{ $name // '' } // die "Term::Fabulous::Widget::Table::Pager: there is no button " . ( defined $name ? "'$name'" : 'undef' ) . " (known: first, previous, next, last)";
	}

	# Shows a state of the table: { page, page_count, page_size, first,
	# last, total }, first and last counting lines from 1.
	method show (%state) {
		my ( $page, $pages ) = @state{qw(page page_count)};
		_set( $page_text,  text     => "Page $page of $pages" );
		_set( $count_text, text     => $state{total}   ? "$state{first}\x{2013}$state{last} of $state{total}" : '0 of 0' );
		_set( $button{$_}, disabled => $page <= 1      ? 1 : 0 ) foreach qw(first previous);
		_set( $button{$_}, disabled => $page >= $pages ? 1 : 0 ) foreach qw(next last);
		my $listed = grep { $_ == $state{page_size} } map { $_->{value} } $size_list->options;
		$size_list->options( [ map { [ "$_" => $_ + 0 ] } sort { $a <=> $b } @$page_sizes, $state{page_size} ] ) unless $listed;
		_set( $size_list, value => $state{page_size} );
		return $self;
	}

	# Changes a property only when it differs, so a frame that changes
	# nothing makes no further frame due.
	sub _set ( $widget, $property, $value ) {
		my $current = $widget->$property;
		return if defined $current && defined $value && "$current" eq "$value";
		return if !defined $current && !defined $value;
		$widget->$property($value);
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Table::Pager - The page controls below a table

=head1 DESCRIPTION

The row below a L<Term::Fabulous::Widget::Table> with pages:

=for highlighter language=text

	« ‹ Page 2 of 7 › »   Rows per page 25 ▾   26–50 of 160

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/cookbook-table-pages.svg" alt="A table of orders on page 3 of 30, with the pager below it and the status line naming the orders on the page"></p>

=end html

Buttons for the first, previous, next and last page (disabled where they
lead nowhere; they take no focus, the table has keys for them, see
L<Term::Fabulous::Widget::Table/KEYS>), the page number, a
L<Term::Fabulous::Widget::Dropdown> with the page sizes and which lines
are shown out of how many. When the table is too narrow for one line,
the three parts flow onto more lines.

The table builds it, wires its buttons and list, keeps it up to date and
shows it while it has pages (see the table's C<pager> parameter); do
not change it. Its colors follow the table's C<text_color> and
C<muted_color>. Pages are explained in
L<Term::Fabulous::Manual::TableRows/PAGES>, and
L<Term::Fabulous::Widget::Table/pager_widget> returns the pager of a
table.

=head1 CONSTRUCTOR

=for highlighter language=perl

	my $pager = Term::Fabulous::Widget::Table::Pager->new( page_sizes => [ 10, 25, 50 ] );

The table makes its pager itself. Unknown parameters die.

=over

=item C<page_sizes>

Required. An array reference of positive integers, the choices of the
list. Anything else dies.

=item C<text_color>

The color of the page number and the button glyphs. Default:
C<[220, 223, 228, 255]>.

=item C<muted_color>

The color of the label, the count and disabled buttons. Default:
C<[140, 146, 158, 255]>.

=item C<button_color>

The background of the buttons. Default: C<[44, 49, 60, 255]>; the
table passes its theme's C<table.pager.button>.

=back

The colors take any format of L<Term::Fabulous::Color>. The pager is a
L<Term::Fabulous::Widget::Box>; its layout is set by the constructor.

=head1 METHODS

=head2 button

	my $next = $pager->button('next');    # first, previous, next, last

A button, by what it does; an unknown name dies.

=head2 size_list

The dropdown with the page sizes; its value is the page size.

=head2 show

	$pager->show( page => 2, page_count => 7, page_size => 25, first => 26, last => 50, total => 160 );

Shows a state of the table: the current page and the number of pages,
the page size, and the first and last line shown and the number of
lines (counted from 1). The first and previous buttons are disabled on
the first page, the next and last buttons on the last one. A page size
that is not in the list is added to it. Returns the pager.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Manual::TableRows/PAGES>,
L<Term::Fabulous::Cookbook::TableRows/Split many rows into pages (pager and page sizes)>.

=cut
