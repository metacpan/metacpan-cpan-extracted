package Term::Fabulous::Render::Frame;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

class Term::Fabulous::Render::Frame :strict(params) {
	use Clay::XS qw(
		CLAY_RENDER_COMMAND_TYPE_NONE
		CLAY_RENDER_COMMAND_TYPE_RECTANGLE
		CLAY_RENDER_COMMAND_TYPE_BORDER
		CLAY_RENDER_COMMAND_TYPE_TEXT
		CLAY_RENDER_COMMAND_TYPE_IMAGE
		CLAY_RENDER_COMMAND_TYPE_SCISSOR_START
		CLAY_RENDER_COMMAND_TYPE_SCISSOR_END
		CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START
		CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END
		CLAY_RENDER_COMMAND_TYPE_CUSTOM
	);
	use List::Util qw(any);
	use Scalar::Util qw(looks_like_number refaddr);
	use Term::Fabulous::Render::Geometry qw(cell_rect intersect_cell_rects rects_overlap);

	my %command_type_name = (
		CLAY_RENDER_COMMAND_TYPE_NONE()                => 'NONE',
		CLAY_RENDER_COMMAND_TYPE_RECTANGLE()           => 'RECTANGLE',
		CLAY_RENDER_COMMAND_TYPE_BORDER()              => 'BORDER',
		CLAY_RENDER_COMMAND_TYPE_TEXT()                => 'TEXT',
		CLAY_RENDER_COMMAND_TYPE_IMAGE()               => 'IMAGE',
		CLAY_RENDER_COMMAND_TYPE_SCISSOR_START()       => 'SCISSOR_START',
		CLAY_RENDER_COMMAND_TYPE_SCISSOR_END()         => 'SCISSOR_END',
		CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START() => 'OVERLAY_COLOR_START',
		CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END()   => 'OVERLAY_COLOR_END',
		CLAY_RENDER_COMMAND_TYPE_CUSTOM()              => 'CUSTOM',
	);

	field $width  :param :reader;
	field $height :param :reader;

	# In paint order; for each command, the cells it may paint into and the
	# non-empty rects it does paint. The painted rects are worked out on the
	# first question about them: a frame without canvases that no pointer
	# report hit-tests never needs them.
	field @_commands;
	field @_clip_rects;
	field $_painted_rects;

	ADJUST :params ( :$commands ) {
		die "Term::Fabulous::Render::Frame: commands must be an array reference of render commands, got " . ( defined $commands ? "'$commands'" : 'undef' )
			unless ref $commands eq 'ARRAY';
		_check_size( width  => $width );
		_check_size( height => $height );

		@_commands   = _with_custom_backgrounds(@$commands);
		@_clip_rects = $self->_replay_scissors;
	}

	method _all_painted_rects () {
		return $_painted_rects //= [ map { [ _painted_rects( $_commands[$_], $_clip_rects[$_] ) ] } 0 .. $#_commands ];
	}

	sub _check_size ( $name, $value ) {
		die "Term::Fabulous::Render::Frame: $name must be a number of at least 0, got " . ( defined $value ? "'$value'" : 'undef' )
			unless looks_like_number($value) && $value >= 0;
		return;
	}

	# Clay carries a custom element's background in the custom command
	# itself, without a rectangle of its own; a rectangle painted before
	# the custom command puts the background below the custom content.
	sub _with_custom_backgrounds (@commands) {
		return map { ( _custom_background($_), $_ ) } @commands;
	}

	# The background rectangle of a custom command: the command's box in
	# its background color. Nothing for other commands and for a custom
	# command without a visible background, as Clay emits no rectangle for
	# a background with alpha 0 either.
	sub _custom_background ($command) {
		return () unless $command->{commandType} == CLAY_RENDER_COMMAND_TYPE_CUSTOM;
		my $data = $command->{renderData};
		return () unless ( $data->{backgroundColor}{a} // 0 ) > 0;
		return { %$command, commandType => CLAY_RENDER_COMMAND_TYPE_RECTANGLE, renderData => { backgroundColor => $data->{backgroundColor}, cornerRadius => $data->{cornerRadius} } };
	}

	# Everything between a SCISSOR_START and its SCISSOR_END is clipped to
	# the start's box, narrowed to the scissor around it and the viewport.
	method _replay_scissors () {
		my @open = ( [ 0, 0, $width, $height ] );
		my @clip_rects;
		foreach my $command (@_commands) {
			my $type = $command->{commandType};
			die sprintf( "Term::Fabulous::Render::Frame: unhandled render command type %s", $command_type_name{$type} // $type )
				unless _is_handled($type);
			push @clip_rects, $open[-1];
			push @open,       intersect_cell_rects( $open[-1], [ cell_rect( $command->{boundingBox} ) ] ) if $type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_START;
			next unless $type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_END;
			die "Term::Fabulous::Render::Frame: scissor end without an open scissor" if @open == 1;
			pop @open;
		}
		return @clip_rects;
	}

	sub _is_handled ($type) {
		return
			   $type == CLAY_RENDER_COMMAND_TYPE_RECTANGLE
			|| $type == CLAY_RENDER_COMMAND_TYPE_BORDER
			|| $type == CLAY_RENDER_COMMAND_TYPE_TEXT
			|| $type == CLAY_RENDER_COMMAND_TYPE_CUSTOM
			|| $type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_START
			|| $type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_END;
	}

	# Rectangles, text and canvases paint their box, a border the one-cell
	# edges of its sides with a positive width, a scissor nothing; all of it
	# only inside the clip rect.
	sub _painted_rects ( $command, $clip ) {
		my $type = $command->{commandType};
		return () if $type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_START || $type == CLAY_RENDER_COMMAND_TYPE_SCISSOR_END;

		my ( $x0, $y0, $x1, $y1 ) = cell_rect( $command->{boundingBox} );
		return () unless $x0 < $x1 && $y0 < $y1;
		return grep { rects_overlap( $_, $_ ) } intersect_cell_rects( [ $x0, $y0, $x1, $y1 ], $clip ) unless $type == CLAY_RENDER_COMMAND_TYPE_BORDER;

		my $widths = $command->{renderData}{width} // {};
		my %edge   = (
			top    => [ $x0,     $y0,     $x1,     $y0 + 1 ],
			bottom => [ $x0,     $y1 - 1, $x1,     $y1 ],
			left   => [ $x0,     $y0,     $x0 + 1, $y1 ],
			right  => [ $x1 - 1, $y0,     $x1,     $y1 ],
		);
		return grep { rects_overlap( $_, $_ ) } map { intersect_cell_rects( $edge{$_}, $clip ) } grep { ( $widths->{$_} // 0 ) > 0 } sort keys %edge;
	}

	method _check_index ($index) {
		die "Term::Fabulous::Render::Frame: no command at index " . ( defined $index ? "'$index'" : 'undef' ) . "; the frame has " . scalar(@_commands) . " commands"
			unless defined $index && $index =~ /\A[0-9]+\z/ && $index <= $#_commands;
		return;
	}

	method commands () {
		return @_commands;
	}

	method command_count () {
		return scalar @_commands;
	}

	method command ($index) {
		$self->_check_index($index);
		return $_commands[$index];
	}

	method clip_rect ($index) {
		$self->_check_index($index);
		return [ @{ $_clip_rects[$index] } ];
	}

	method painted_rects ($index) {
		$self->_check_index($index);
		return map { [@$_] } @{ $self->_all_painted_rects->[$index] };
	}

	method painted_after ( $index, $rect ) {
		$self->_check_index($index);
		my $painted = $self->_all_painted_rects;
		my ( $x0, $y0, $x1, $y1 ) = @$rect;

		# Called for every canvas, against every command after it: compare
		# in place rather than build intersection rects.
		foreach my $later ( @{$painted}[ $index + 1 .. $#_commands ] ) {
			foreach my $painted_rect (@$later) {
				return 1 if $painted_rect->[0] < $x1 && $x0 < $painted_rect->[2] && $painted_rect->[1] < $y1 && $y0 < $painted_rect->[3];
			}
		}
		return 0;
	}

	method painted_over ( $index, $rect ) {
		$self->_check_index($index);
		my $painted = $self->_all_painted_rects;
		return grep { rects_overlap( $_, $_ ) } map { intersect_cell_rects( $_, $rect ) } map { @$_ } @{$painted}[ $index + 1 .. $#_commands ];
	}

	# The painted lines of a text widget: for each TEXT command the widget
	# emitted, the screen row and the offset in its text of the line's
	# first character, in the order of the rows. A text that was not laid
	# out, or whose lines Clay left out below the window, has fewer lines
	# here than it has; a line without characters has none.
	method text_rows ($widget) {
		my $user_data = refaddr $widget;
		return map { [ ( cell_rect( $_->{boundingBox} ) )[1], $_->{renderData}{stringOffset} // 0 ] }
			sort { $a->{boundingBox}{y} <=> $b->{boundingBox}{y} }
			grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT && ( $_->{userData} // -1 ) == $user_data } @_commands;
	}

	method topmost_at ( $x, $y ) {
		my $painted = $self->_all_painted_rects;
		return grep {
			any { $x >= $_->[0] && $x < $_->[2] && $y >= $_->[1] && $y < $_->[3] }
				@{ $painted->[$_] }
		} reverse 0 .. $#_commands;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Render::Frame - What one frame paints, command by
command

=head1 SYNOPSIS

	use Term::Fabulous::Render::Frame;

	my $frame = Term::Fabulous::Render::Frame->new(
		commands => $ui->render,    # Clay's render commands
		width    => $ui->width,
		height   => $ui->height,
	);

	foreach my $index ( 0 .. $frame->command_count - 1 ) {
		my $command = $frame->command($index);
		my ( $x0, $y0, $x1, $y1 ) = @{ $frame->clip_rect($index) };
		...
	}

	# The commands painted at a cell, the topmost first.
	my @indices = $frame->topmost_at( 12, 3 );

=head1 DESCRIPTION

Most programs never use this module directly. L<Term::Fabulous::Render>
builds a Frame from the render commands Clay laid out, before it paints
any of them, and keeps the Frame of the last frame
(L<Term::Fabulous::Render/last_frame>). L<Term::Fabulous> hit-tests the
mouse pointer with it, and L<Term::Fabulous::Render::Canvas> uses it to
decide which canvases can keep their cells.

A Frame is read-only. It works out (the painted cells on the first call
that needs them, the rest when it is constructed):

=over

=item * the paint order

The order of Clay's commands, with one addition: Clay carries the
background of a canvas in the canvas's own command, and the frame
paints it as a rectangle right before that command.

=item * the clip rect of every command

The rectangle of cells the command may paint into: the viewport
(C<[0, 0, width, height]>), narrowed to the innermost scissor around
the command. Clay surrounds the content of a clipping element, such as
a L<scroll box|Term::Fabulous::Widget::ScrollBox>, with a C<SCISSOR_START>
and a C<SCISSOR_END> command; a scissor nested inside another is
narrowed to it. Boxes are snapped to whole cells like everywhere else
(see L<Term::Fabulous::Render::Geometry/cell_rect>).

=item * the cells every command paints

Rectangles, text and canvases paint their box, borders the one-cell
edge of every side whose Clay border width is greater than 0, and
scissors nothing; all of them only inside their clip rect.

=back

=head1 CONSTRUCTOR

=head2 new

	my $frame = Term::Fabulous::Render::Frame->new( commands => \@commands, width => 80, height => 24 );

C<commands> is an array reference of render commands in the format of
L<Clay::XS/RENDER COMMANDS>, in the order Clay emitted them; C<width>
and C<height> are the size of the viewport in cells, numbers of at
least 0. The command hashes are kept as they are, not copied.

Dies with a message starting with C<Term::Fabulous::Render::Frame:>
when an argument is invalid, when a command has a type other than
rectangle, border, text, scissor start or end and custom
(C<unhandled render command type IMAGE>; Term::Fabulous widgets produce
only these), and when a C<SCISSOR_END> has no open scissor.

=head1 METHODS

All C<$index> arguments are positions in the paint order, from 0 to
C<command_count - 1>; any other value dies.

=head2 commands

	my @commands = $frame->commands;

The render commands in paint order. The hashes are Clay's own: read
them, do not change them. Use C<< $ui->widget_for( $command->{userData} ) >>
to get the widget a command belongs to.

=head2 command_count

	my $count = $frame->command_count;

The number of commands.

=head2 command

	my $command = $frame->command($index);

One command, as in L</commands>.

=head2 width, height

	my ( $columns, $rows ) = ( $frame->width, $frame->height );

The size of the viewport the Frame was built for.

=head2 clip_rect

	my ( $x0, $y0, $x1, $y1 ) = @{ $frame->clip_rect($index) };

The rectangle of cells the command may paint into, as a new array
reference C<[x0, y0, x1, y1]>. C<x1> and C<y1> are exclusive, so the
rectangle covers the columns C<x0 .. x1 - 1> and the rows
C<y0 .. y1 - 1>. When a scissor lies outside the viewport, the
rectangle is empty (C<x1 == x0> or C<y1 == y0>). A command outside its
clip rect, such as content scrolled out of a scroll container, paints
nothing.

=head2 painted_rects

	my @rects = $frame->painted_rects($index);

The non-empty C<[x0, y0, x1, y1]> rectangles the command paints, as new
array references; none for a scissor or for a command outside its clip
rect, up to four (one per edge) for a border.

=head2 painted_after

	my $covered = $frame->painted_after( $index, [ $x0, $y0, $x1, $y1 ] );

1 when a command painted after the one at C<$index> paints into the
given rectangle, otherwise 0. A canvas that something is painted over
cannot keep its cells from the last frame.

=head2 painted_over

	my @rects = $frame->painted_over( $index, [ $x0, $y0, $x1, $y1 ] );

The parts of the given rectangle that commands painted after the one at
C<$index> paint into, as C<[x0, y0, x1, y1]> rectangles, one per
painted rectangle of those commands; they may overlap. Empty when
nothing is painted over the rectangle. A sixel picture leaves these
cells out.

=head2 text_rows

	my @rows = $frame->text_rows($text);    # ( [ $row, $first_offset ], ... )

The painted lines of a L<Term::Fabulous::Widget::Text>: for every TEXT
command the widget emitted, the screen row it was painted on and the
offset in the widget's text of the line's first character, ordered by
row. A text that was not laid out in this frame has none; one whose
lower lines Clay left out below the window has fewer than it shows;
a line without characters has none. A caller that scrolls a character
into view takes the row of the last line whose offset is not past the
character's, and treats an offset past the last line as below it.

=head2 topmost_at

	my @indices = $frame->topmost_at( $x, $y );

The indices of the commands that paint the cell C<($x, $y)>, the
topmost (the one painted last) first. Empty when nothing is painted
there.

=head1 SEE ALSO

L<Term::Fabulous::Render>, L<Term::Fabulous::Render::Geometry>,
L<Term::Fabulous::Render::Canvas>.

=cut
