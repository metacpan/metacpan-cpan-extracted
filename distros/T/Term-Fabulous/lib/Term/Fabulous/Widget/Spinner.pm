package Term::Fabulous::Widget::Spinner;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Display;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Spinner
	:isa(Term::Fabulous::Widget::Display)
	:strict(params)
{
	use List::Util ();    # max is a method elsewhere in the family
	use Term::Fabulous::Check qw(boolean describe number one_of string);
	use Term::Fabulous::Unicode qw(string_columns);

	# A ring of blocks with a gap that runs around it: the frames remove
	# one of the eight cells around the center in turn.
	my @RING_CELLS = ( [ 0, 0 ], [ 0, 1 ], [ 0, 2 ], [ 1, 2 ], [ 2, 2 ], [ 2, 1 ], [ 2, 0 ], [ 1, 0 ] );

	sub _ring_frames () {
		my @frames;
		foreach my $gap (@RING_CELLS) {
			my @rows = map { [ ("\x{2588}") x 3 ] } 1 .. 3;
			$rows[1][1] = ' ';
			$rows[ $gap->[0] ][ $gap->[1] ] = ' ';
			push @frames, join "\n", map { join '', @$_ } @rows;
		}
		return \@frames;
	}

	# The ready-made styles: frames and how long each one shows.
	my %STYLE = (
		dots   => { interval => 0.08, frames => [ map { chr } 0x280B, 0x2819, 0x2839, 0x2838, 0x283C, 0x2834, 0x2826, 0x2827, 0x2807, 0x280F ] },
		line   => { interval => 0.13, frames => [ '-',                '\\',     '|',      '/' ] },
		arc    => { interval => 0.10, frames => [ map { chr } 0x25DC, 0x25E0,   0x25DD,   0x25DE, 0x25E1, 0x25DF ] },
		circle => { interval => 0.12, frames => [ map { chr } 0x25D0, 0x25D3,   0x25D1,   0x25D2 ] },
		arrow  => { interval => 0.10, frames => [ map { chr } 0x2190, 0x2196,   0x2191,   0x2197, 0x2192, 0x2198, 0x2193, 0x2199 ] },
		box    => { interval => 0.12, frames => [ map { chr } 0x2596, 0x2598,   0x259D,   0x2597 ] },
		pulse  => { interval => 0.15, frames => [ map { chr } 0x00B7, 0x2022,   0x25CF,   0x2022 ] },
		bar    => { interval => 0.08, frames => [ map { chr } 0x2581, 0x2583,   0x2584,   0x2585, 0x2586, 0x2587, 0x2588, 0x2587, 0x2586, 0x2585, 0x2584, 0x2583 ] },
		dots3  => { interval => 0.30, frames => [ '   ',              '.  ',    '.. ',    '...' ] },
		bounce => { interval => 0.12, frames => [ '[=   ]',           '[ =  ]', '[  = ]', '[   =]', '[  = ]', '[ =  ]' ] },
		wave   => {
			interval => 0.10,
			frames   => [
				map {
					my $i = $_;
					join '', map { chr( $_ == $i ? 0x2588 : abs( $_ - $i ) == 1 ? 0x2593 : 0x2591 ) } 0 .. 4
				} 0 .. 4,
				3, 2,
				1
			]
		},
		ring => { interval => 0.10, frames => _ring_frames() },
	);

	my @LABEL_POSITIONS = qw(left right);

	field $style          :param = 'dots';
	field $frames         :param = undef;
	field $interval       :param = undef;
	field $label          :param = '';
	field $label_position :param = 'right';
	field $running        :param = 1;

	ADJUST {
		$style          = one_of( $self, style => $style, keys %STYLE );
		$frames         = $self->_checked_frames($frames);
		$interval       = $self->_checked_interval($interval);
		$label          = string( $self, label => $label );
		$label_position = one_of( $self, label_position => $label_position, @LABEL_POSITIONS );
		$running        = boolean( $self, running => $running );
	}

	method theme_family :common () {
		return 'spinner';
	}

	method themed_params :common () {
		return ( $class->SUPER::themed_params, color => [ 'color', 'normal', 'cell_color' ], label_color => [ 'label', 'normal', 'cell_color' ] );
	}

	# Frames of your own: a non-empty array of strings, copied.
	method _checked_frames ($list) {
		return undef unless defined $list;
		die ref($self) . ": frames must be an array reference of one or more strings, got " . describe($list) unless ref $list eq 'ARRAY' && @$list;
		foreach my $frame (@$list) {
			die ref($self) . ": every frame must be a string, got " . describe($frame) unless defined $frame && !ref $frame;
		}
		return [@$list];
	}

	method _checked_interval ($seconds) {
		return undef unless defined $seconds;
		$seconds = number( $self, interval => $seconds );
		die ref($self) . ": interval must be positive, got $seconds" unless $seconds > 0;
		return $seconds;
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	method _set ( $field_ref, $value ) {
		$$field_ref = $value;
		$self->mark_changed;
		return $$field_ref;
	}

	method style          (@new) { return @new ? $self->_set( \$style, one_of( $self, style => $new[0], keys %STYLE ) )                        : $style }
	method interval       (@new) { return @new ? $self->_set( \$interval, $self->_checked_interval( $new[0] ) )                                : $interval // $STYLE{$style}{interval} }
	method label          (@new) { return @new ? $self->_set( \$label, string( $self, label => $new[0] ) )                                     : $label }
	method label_position (@new) { return @new ? $self->_set( \$label_position, one_of( $self, label_position => $new[0], @LABEL_POSITIONS ) ) : $label_position }
	method running        (@new) { return @new ? $self->_set( \$running, boolean( $self, running => $new[0] ) )                                : $running }
	method color          (@new) { return @new ? $self->set_look( color => $new[0] )                                                           : $self->look_value('color') }
	method label_color    (@new) { return @new ? $self->set_look( label_color => $new[0] )                                                     : $self->look_value('label_color') }

	method frames (@new) {
		return [ ( $frames // $STYLE{$style}{frames} )->@* ] unless @new;
		$self->_set( \$frames, $self->_checked_frames( $new[0] ) );
		return $self->frames;
	}

	method start () { $self->running(1); return $self }
	method stop ()  { $self->running(0); return $self }

	method styles :common () {
		my @styles = sort keys %STYLE;
		return @styles;
	}

	# frames "-" "\\" "|" "/"
	method _parse_frames ($kid) {
		my @frames = map { $_->as_perl } $kid->args->@*;
		die ref($self) . ": layout property 'frames' takes one or more strings and no properties" if !@frames || $kid->props->@* || $kid->children->@*;
		$self->frames( \@frames );
		return;
	}

	method layout_properties :common () {
		return (
			$class->SUPER::layout_properties,
			( map { $_ => 'scalar' } qw(style interval label label_position) ),
			running => 'boolean',
			frames  => \&_parse_frames,
		);
	}

	# ---------------------------------------------------------------------
	# Painting
	# ---------------------------------------------------------------------

	# The rows of a frame, and the size every frame needs: the widest row
	# and the most rows of any frame, so the label stays in place.
	sub _rows_of ($frame) {
		return split /\n/, $frame, -1;
	}

	method _frame_size () {
		my @all = map { [ _rows_of($_) ] } $self->frames->@*;
		return (
			List::Util::max( 1, map { string_columns($_) } map { @$_ } @all ),
			List::Util::max( 1, map { scalar @$_ } @all ),
		);
	}

	method _label_columns () {
		return length $label ? string_columns($label) + 1 : 0;
	}

	method natural_size () {
		my ( $columns, $rows ) = $self->_frame_size;
		return ( $columns + $self->_label_columns, $rows );
	}

	# The frame shown now, which the paint key includes; asking for it
	# keeps the frames coming while the spinner runs.
	method frame_index () {
		my $frames = $self->frames;
		return $running ? $self->animation_frame( $self->interval, scalar @$frames ) : 0;
	}

	method paint_key :override () {
		return ( $self->SUPER::paint_key, $self->frame_index );
	}

	method paint () {
		my ( $frame_columns, $frame_rows ) = $self->_frame_size;
		my $label_columns = $self->_label_columns;
		my $frame_x       = $label_position eq 'left' ? $label_columns : 0;
		my @rows          = _rows_of( $self->frames->[ $self->frame_index ] );
		my $fg            = $self->color_attr( $self->color );
		$self->paint_text( $frame_x, $_, $rows[$_], $fg, undef, $frame_x + $frame_columns ) foreach 0 .. $#rows;
		return unless $label_columns;

		my $y = int( ( $frame_rows - 1 ) / 2 );
		$self->paint_text( $label_position eq 'left' ? 0 : $frame_columns + 1, $y, $label, $self->color_attr( $self->label_color ), undef );
		return;
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::Spinner - Show that something is going on

=head1 SYNOPSIS

	use Term::Fabulous::Widget::Spinner;

	my $spinner = Term::Fabulous::Widget::Spinner->new( label => 'Connecting' );
	$box->add_child($spinner);

	# When the work is done:
	$spinner->stop;
	$box->remove_child($spinner);

	# Other looks:
	Term::Fabulous::Widget::Spinner->new( style => 'line' );                     # - \ | /
	Term::Fabulous::Widget::Spinner->new( style => 'ring', color => '#98c379' ); # three rows
	Term::Fabulous::Widget::Spinner->new( frames => [ 'tick', 'tock' ], interval => 0.5 );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.03/screenshots/widget-spinner.svg" alt="Spinners in every style, each with its name: dots, line, arc, circle, arrow, box, pulse and bar in one cell, dots3, bounce and wave in several, and the three-row ring; a stopped one and one with frames of its own"></p>

=end html

=head1 DESCRIPTION

The picture shows every ready-made style, each with its name as the
label, a stopped spinner and one with frames of its own. The program
is F<examples/widgets/spinner.pl>.

A spinner shows that the program is busy with something whose
progress it cannot measure: connecting, waiting for a reply, loading.
It cycles through the frames of its C<style>, a few times per second,
and shows a C<label> next to them:

=for highlighter language=text

	⠋ Connecting

The styles come in three sizes. One cell: C<dots> (the default, made
of Braille patterns), C<line>, C<arc>, C<circle>, C<arrow>, C<box>,
C<pulse> and C<bar>. A few cells: C<dots3> (three dots appearing one
by one), C<bounce> and C<wave>. Three rows: C<ring>, a square ring of
blocks with a gap that runs around it. Frames of your own, including
frames of several rows, replace the style's; see L</frames>.

The spinner runs on the application's clock without a timer of its
own (see L<Term::Fabulous::Widget::Display/ANIMATION>): it asks for a
frame when its next one is due, so nothing is drawn while it stands
still, and a stopped spinner (L</stop>) shows its first frame and
costs nothing. It takes no input. Unless the C<layout> sizes it, it
is as big as its largest frame plus the label.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $spinner = Term::Fabulous::Widget::Spinner->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, the border parameters, ...)
and the ones below. All are optional; unknown parameters die.

=over

=item C<style>

The name of a ready-made style: C<dots> (the default), C<line>,
C<arc>, C<circle>, C<arrow>, C<box>, C<pulse>, C<bar>, C<dots3>,
C<bounce>, C<wave> or C<ring>. Anything else dies, naming them.
L</styles> returns the names.

=item C<frames>

An array reference of one or more strings, the frames shown in turn,
or C<undef> (the frames of C<style>). A frame of several rows has
newlines in it. Every frame is drawn in the space of the largest one,
so the label stays in place. Default: C<undef>.

=item C<interval>

A positive number of seconds each frame is shown, or C<undef> for the
style's own pace (0.08 to 0.3 seconds). Default: C<undef>.

=item C<label>

A character string shown next to the frames, in C<label_color>.
Default: C<''> (no label).

=item C<label_position>

C<right> (the default) or C<left>: on which side of the frames the
label is. Anything else dies.

=item C<running>

A boolean. Default: 1. Whether the spinner animates; 0 shows the first
frame and stands still. Stored as 1 or 0; a reference dies.

=item C<color>

The color of the frames, in any format
L<Term::Fabulous::Widget::Canvas/Colors> accepts. Default: the theme's
C<spinner.color>, C<[97, 175, 239, 255]> in the dark theme, the blue of
the input widgets' accent.

=item C<label_color>

The color of the label. Default: the theme's C<spinner.label>,
C<[220, 223, 228, 255]> in the dark theme.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Display> (C<mark_changed>, the
Box and Canvas methods), plus:

=head2 start

	$spinner->start;

Lets the spinner run. Returns the spinner.

=head2 stop

	$spinner->stop;

Stops the spinner at its first frame; a stopped spinner asks for no
frames. Returns the spinner. Remove the spinner from its parent, or
replace its label, when the work is done.

=head2 running

	my $is_running = $spinner->running;
	$spinner->running(0);

Accessor for the C<running> parameter; what L</start> and L</stop>
write. Returns 1 or 0.

=head2 style

	$spinner->style('arc');

Accessor for the C<style> parameter. Writing switches to that style's
frames unless frames of your own are set, and to its pace unless an
C<interval> is set. An unknown name dies and leaves the old style.

=head2 frames

	my $frames = $spinner->frames;    # the frames in use, a new array reference
	$spinner->frames( [ "\x{25CB}", "\x{25D4}", "\x{25D1}", "\x{25D5}", "\x{25CF}" ] );
	$spinner->frames(undef);           # back to the style's frames

Accessor. The reader returns the frames shown now, the style's or your
own, as a new array reference. Writing sets frames of your own,
checked as C<new> checks them; C<undef> returns to the style's.

=head2 interval

	my $seconds = $spinner->interval;    # 0.08 for dots
	$spinner->interval(0.2);
	$spinner->interval(undef);           # back to the style's pace

Accessor. The reader returns the seconds each frame is shown, the
style's pace unless one was set. Writing checks the value as C<new>
does.

=head2 label

	$spinner->label('Still connecting');

Accessor for the C<label> parameter; the new width takes effect at the
next frame.

=head2 label_position

	$spinner->label_position('left');

Accessor for the C<label_position> parameter.

=head2 color

	$spinner->color('#e5c07b');

Accessor for the C<color> parameter. The reader returns
C<[r, g, b, a]>. An invalid color dies and leaves the old one.

=head2 label_color

	$spinner->label_color('#ffffff');

Accessor for the C<label_color> parameter; works like L</color>.

=head2 frame_index

	my $index = $spinner->frame_index;

The index of the frame shown at this moment, from 0: by the clock
while the spinner runs, 0 while it is stopped. Read-only.

=head2 styles

	my @names = Term::Fabulous::Widget::Spinner->styles;

A class method: the names of the ready-made styles, sorted.

Every writer marks the spinner changed, so the next frame paints the
new look.

=head1 EVENTS

A spinner fires no events of its own.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<style>, C<interval>, C<label> and C<label_position> (strings and
numbers), C<running> (C<#true> / C<#false>), C<color> and
C<label_color> (color strings), and C<frames> with one or more string
arguments:

=for highlighter language=kdl

	use Term::Fabulous::Widget::Spinner as Spinner

	Spinner "busy" {
		style "arc"
		label "Loading"
		color "#98c379"
	}

	Spinner "custom" {
		frames "tick" "tock"
		interval 0.5
	}

=head1 EXAMPLES

=head2 A spinner that becomes a check mark

=for highlighter language=perl

	my $spinner = Term::Fabulous::Widget::Spinner->new( label => 'Saving' );

	sub saved () {
		$spinner->stop;
		$spinner->frames( ["\x{2713}"] );    # one frame: a check mark
		$spinner->color('#98c379');
		$spinner->label('Saved');
		return;
	}

=head2 A spinner inside a button

	my $button  = Term::Fabulous::Widget::Button->new( layout => { child_gap => 1, padding => { left => 1, right => 1 } } );
	my $spinner = Term::Fabulous::Widget::Spinner->new( style => 'line', running => 0 );
	$button->add_child( $spinner, Term::Fabulous::Widget::Text->new( text => 'Submit', text_color => '#ffffff' ) );
	$button->on( Activate => sub ($event) { $spinner->start; submit_form(); return } );

=head1 SEE ALSO

L<Term::Fabulous::Widget::Display>, L<Term::Fabulous::Widget::ProgressBar>,
L<Term::Fabulous::Manual::Feedback/SPINNERS>.

=cut
