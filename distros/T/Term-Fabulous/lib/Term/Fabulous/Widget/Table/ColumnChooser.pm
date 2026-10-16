package Term::Fabulous::Widget::Table::ColumnChooser;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::Checkbox;
use Term::Fabulous::Widget::Text;

class Term::Fabulous::Widget::Table::ColumnChooser :isa(Term::Fabulous::Widget::Box) :strict(params) {
	use Clay::UI::Enum::Result;
	use Clay::XS qw(CLAY_TOP_TO_BOTTOM CLAY_ATTACH_TO_PARENT CLAY_ATTACH_POINT_RIGHT_TOP);
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Enum::BorderStyle;

	# The highest z_index Clay has: the chooser belongs to the focused
	# table and floats over everything.
	use constant Z_INDEX => 32767;

	# [ key, title, visible ] per column, in order.
	field $columns     :param;
	field $on_toggle   :param;    # sub ( $key, $visible )
	field $on_close    :param;    # sub ()
	field $text_color  :param = [ 220, 223, 228, 255 ];
	field $muted_color :param = [ 140, 146, 158, 255 ];
	field @_boxes;

	ADJUST {
		die "Term::Fabulous::Widget::Table::ColumnChooser: columns must be an array reference of [ key, title, visible ]"
			unless ref $columns eq 'ARRAY' && !grep { ref $_ ne 'ARRAY' || @$_ != 3 } @$columns;
		die "Term::Fabulous::Widget::Table::ColumnChooser: on_toggle and on_close must be code references"
			unless ref $on_toggle eq 'CODE' && ref $on_close eq 'CODE';

		$self->layout( { layout_direction => CLAY_TOP_TO_BOTTOM, padding => { left => 1, right => 1 } } );
		$self->floating( { attach_to => CLAY_ATTACH_TO_PARENT, attach_points => { element => CLAY_ATTACH_POINT_RIGHT_TOP, parent => CLAY_ATTACH_POINT_RIGHT_TOP }, z_index => Z_INDEX } );
		$self->add_child( Term::Fabulous::Widget::Text->new( text => 'Columns', text_color => $text_color, bold => 1 ) );
		foreach my $entry (@$columns) {
			my ( $key, $title, $visible ) = @$entry;
			my $box = Term::Fabulous::Widget::Checkbox->new( label => $title, checked => $visible, text_color => $text_color );
			$box->on( Change => sub ($event) { $on_toggle->( $key, $event->value ); return } );
			push @_boxes, $box;
		}
		$self->add_child( @_boxes, Term::Fabulous::Widget::Text->new( text => 'Esc closes', text_color => $muted_color ) );

		weaken( my $weak_self = $self );
		$self->on(
			KeyPress => sub ($event) {
				my $name = $event->main_key_name // return Clay::UI::Enum::Result->CONTINUE;
				return Clay::UI::Enum::Result->CONTINUE unless $name eq 'Escape';
				$on_close->();
				return;
			}
		);

		# Closes once the focus has left it; the new focus is only known after
		# the OnBlur, so the check waits for the frame.
		$self->on(
			OnBlur => sub ($event) {
				my $ui = $weak_self ? $weak_self->ui : undef;
				$ui->after_draw( sub { $weak_self->_close_unless_focused if $weak_self } ) if defined $ui && $ui->can('after_draw');
				return Clay::UI::Enum::Result->CONTINUE;
			}
		);
	}

	method checkboxes () {
		return @_boxes;
	}

	method focus_first () {
		my $ui = $self->ui // return;
		$ui->interaction->set_focused_widget( $_boxes[0] ) if @_boxes;
		return;
	}

	method _close_unless_focused () {
		my $ui = $self->ui // return;
		return if $ui->interaction->has_focus_within($self);
		$on_close->();
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Table::ColumnChooser - The list where the user picks the columns of a table

=head1 DESCRIPTION

A box that floats over the top right corner of a
L<Term::Fabulous::Widget::Table> with a check box for every column:
checking or unchecking one (C<Space>, C<Enter> or a click) shows or
hides the column at once. C<Tab> and C<Shift+Tab> move between the
check boxes. C<Escape> closes it, and so does moving the focus out of
it (C<Tab> past the last check box, a click elsewhere). The table opens it (see
L<Term::Fabulous::Widget::Table/open_column_chooser>) and focuses its
first check box. The user opens it with C<c> on the column titles or a
right click on a title.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/cookbook-table-columns.svg" alt="A staff table with the column chooser open over its top right corner: City unchecked, E-mail checked, and the status line with the columns to save"></p>

=end html

It shows the title C<Columns>, one check box per column (labeled with
the column's title, or its key when the title is empty) and the hint
C<Esc closes>. The table draws it on its C<group_background_color> with
a round frame in its C<text_color>, and fires
L<Term::Fabulous::Event::ColumnsChange> for every column the user shows
or hides. See
L<Term::Fabulous::Manual::Tables/Choosing the visible columns> and the
recipe
L<Term::Fabulous::Cookbook::Tables/Let the user choose the visible columns (column chooser)>.

=head1 CONSTRUCTOR

	my $chooser = Term::Fabulous::Widget::Table::ColumnChooser->new(
		columns   => [ [ name => 'Name', 1 ], [ email => 'E-mail', 0 ] ],
		on_toggle => sub ( $key, $visible ) { ... },
		on_close  => sub () { ... },
	);

The table makes the chooser itself. It is a
L<Term::Fabulous::Widget::Box> that floats over the top right corner of
its parent; the parameters of a Box (colors, border) work too. Unknown
parameters die.

=over

=item C<columns>

Required. An array reference with one C<[ $key, $title, $visible ]>
entry per column, in order.

=item C<on_toggle>

Required. A code reference, called with the column key and the new
state (1 shown, 0 hidden) when the user checks or unchecks a box.

=item C<on_close>

Required. A code reference, called when the user presses C<Escape> or
the focus leaves the chooser. It must remove the chooser.

=item C<text_color>

The color of the title and the check boxes. Default:
C<[220, 223, 228, 255]>; the table passes its C<text_color>.

=item C<muted_color>

The color of the closing hint. Default: C<[140, 146, 158, 255]>; the
table passes its C<muted_color>.

=back

=head1 METHODS

=head2 checkboxes

The L<Term::Fabulous::Widget::Checkbox> widgets, one per column.

=head2 focus_first

Gives the focus to the first check box.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Widget::Table/In the column chooser>.

=cut
