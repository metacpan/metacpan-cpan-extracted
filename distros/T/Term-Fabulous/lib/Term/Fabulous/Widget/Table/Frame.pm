package Term::Fabulous::Widget::Table::Frame;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw(framed);

use Clay::UI::Enum::Result;
use Clay::XS qw(sizing_fixed sizing_grow);
use Scalar::Util qw(weaken);
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;

# A table in a frame of its own (a table's own frame scrolls with its
# rows), drawn in the accent while the table has the focus.
sub framed ( $table, $rows, $min_rows = $rows ) {
	die "Term::Fabulous::Widget::Table::Frame: min_rows $min_rows is more than rows $rows" if $min_rows > $rows;
	my $frame = $min_rows == $rows ? _fixed_frame( $table, $rows ) : _shrinking_frame( $table, $rows, $min_rows );
	weaken( my $weak_frame = $frame );
	weaken( my $weak_table = $table );
	$table->on( OnFocus => sub ($event) { $weak_frame->border_color( $weak_frame->family_look( input => 'accent' ) ) if $event->target == $weak_table; return Clay::UI::Enum::Result->CONTINUE } );
	$table->on( OnBlur  => sub ($event) { $weak_frame->reset_look('border_color') if $event->target == $weak_table;                                    return Clay::UI::Enum::Result->CONTINUE } );
	return $frame;
}

sub _fixed_frame ( $table, $rows ) {
	my $frame = Term::Fabulous::Widget::Box->new( bordered => 1, layout => { sizing => { width => sizing_grow(), height => sizing_fixed( $rows + 2 ) } } );
	$frame->add_child($table);
	return $frame;
}

# A frame that wants $rows but gives up rows down to $min_rows when its
# parent has no room. Clay sizes a frame by its content, and shrinks it
# only down to the content's minimum. So the table has a strut next to
# it: an empty column that wants $rows but clips its own content (a
# scroll box pinned at the top, which takes no minimum from what it
# holds) and so shrinks down to $min_rows.
sub _shrinking_frame ( $table, $rows, $min_rows ) {
	my $frame = Term::Fabulous::Widget::Box->new( bordered => 1, layout => { sizing => { width => sizing_grow(), height => sizing_grow( $min_rows + 2, $rows + 2 ) } } );
	my $strut = Term::Fabulous::Widget::ScrollBox->new(
		id           => $table->id . '/strut',
		scrollbar    => 0,
		vertical     => 1,
		child_offset => { x      => 0, y => 0 },
		layout       => { sizing => { width => sizing_fixed(0), height => sizing_grow( $min_rows, $rows ) } },
	);
	$strut->add_child( Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(0), height => sizing_fixed($rows) } } ) );
	$frame->add_child( $table, $strut );
	return $frame;
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Table::Frame - A frame around a table that shows its focus

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Table::Frame qw(framed);

	my $list = Term::Fabulous::Widget::Table->new( id => 'files', header => 0, border => 'none', ... );
	$dialog->add_child( framed( $list, 10 ) );

=head1 DESCRIPTION

The widgets that show a list in a L<Term::Fabulous::Widget::Table>
(the file dialog, the color picker and the theme editor's value dialog)
put the table in a frame of its own, because a table's own frame
scrolls with its rows. This module makes that frame. It is internal to
Term::Fabulous and not meant to be used directly.

=head1 FUNCTIONS

=head2 framed

	my $frame = framed( $table, $rows );
	my $frame = framed( $table, $rows, $min_rows );

Returns a bordered L<Term::Fabulous::Widget::Box> as wide as its
parent allows and C<$rows + 2> cells high, with C<$table> as its only
child. C<$rows> counts the lines the table shows, its header lines
included (a header with a C<header_line> is two). The table should
grow to fill the frame and have no frame of its own
(C<< border => 'none' >>).

With C<$min_rows> fewer than C<$rows>, the frame gives up rows before
the widgets around it do when its parent has no room for all of them,
down to C<$min_rows + 2> cells. It then also holds an empty column of
no width next to the table, which keeps the frame C<$rows + 2> cells
high however few rows the table has (Clay sizes a box by its content).
The table's id with C</strut> is the id of that column. More
C<$min_rows> than C<$rows> dies.

While the table has the focus, the frame's border is drawn in the
theme's C<input.accent>; when the table loses it, the border goes back
to its theme color.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Table>, L<Term::Fabulous::Widget::Box>.

=cut
