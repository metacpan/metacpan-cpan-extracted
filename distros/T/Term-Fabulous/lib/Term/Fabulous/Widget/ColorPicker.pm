package Term::Fabulous::Widget::ColorPicker;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Box;

our $VERSION = '0.05';

# A color chooser built from other widgets: a field for the color as
# text, a sample of it, sliders for its channels (RGB or HSL, switched by
# a segmented control), an optional alpha slider and an optional list of
# named swatches. The parts' own events stop at them; the picker fires
# its own Change and Submit.
class Term::Fabulous::Widget::ColorPicker
	:isa(Term::Fabulous::Widget::Box)
	:strict(params)
{
	use Clay::XS qw(sizing_fixed sizing_grow CLAY_TOP_TO_BOTTOM);
	use Feature::Compat::Try;
	use List::Util qw(first max min);
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Check qw(boolean color describe one_of optional positive_integer string);
	use Term::Fabulous::Color;
	use Term::Fabulous::Event::Change;
	use Term::Fabulous::Event::Submit;
	use Term::Fabulous::Unicode qw(string_columns);
	use Term::Fabulous::Widget::SegmentedControl;
	use Term::Fabulous::Widget::Slider;
	use Term::Fabulous::Widget::Table;
	use Term::Fabulous::Widget::Table::Frame qw(framed);
	use Term::Fabulous::Widget::Text;
	use Term::Fabulous::Widget::TextField;

	use constant SAMPLE         => "\x{2588}" x 3;    # full blocks in the swatch's color
	use constant FIELD_WIDTH    => 22;    # the field shrinks to FIELD_MINIMUM on a narrow screen
	use constant FIELD_MINIMUM  => 10;
	use constant LABEL_MINIMUM  => 20;    # the swatch labels keep up to this many columns
	use constant LIST_FURNITURE => 2 + 6 + 1 + 1;    # the frame's borders, the sample column, the gap after it, the scrollbar
	use constant SAMPLE_WIDTH   => 6;

	# The three channel sliders of each mode: their labels and maximums.
	my %CHANNELS_OF_MODE = (
		rgb => [ [ R => 255 ], [ G => 255 ], [ B => 255 ] ],
		hsl => [ [ H => 359 ], [ S => 100 ], [ L => 100 ] ],
	);

	my $pickers_built = 0;    # for the ids of pickers built without one

	field $alpha     :param = 1;
	field $sliders   :param = 'rgb';
	field $list_rows :param = 12;

	field $chosen;    # the spec chosen now: a swatch's value or a color, or undef
	field $_rgba;    # the color of $chosen as [r, g, b, a], or undef
	field @_swatches;    # { value, label, rgba }, in order

	field $_field;
	field $_sample;
	field $_switch;
	field @_channel_sliders;
	field @_channel_labels;
	field $_alpha_slider;
	field $_alpha_row;
	field $_column;
	field $_list;
	field $_frame;

	ADJUST :params ( :$value = undef, :$swatches = undef ) {
		$alpha     = boolean( $self, alpha => $alpha );
		$sliders   = one_of( $self, sliders => $sliders, keys %CHANNELS_OF_MODE );
		$list_rows = positive_integer( $self, list_rows => $list_rows );
		@_swatches = $self->_parsed_swatches($swatches);

		my $layout = $self->layout;
		$self->layout( { child_gap => 2, %$layout, sizing => { width => sizing_grow(), %{ $layout->{sizing} // {} } } } );
		$self->add_child( $self->_swatch_list ) if @_swatches;
		$self->add_child( $self->_editor );
		$self->_use_sliders;
		$self->_show_value($value);
	}

	# ---------------------------------------------------------------------
	# Parameters
	# ---------------------------------------------------------------------

	# Swatches as { value, label, rgba }: a value (a non-empty string,
	# unique), a label (the value when left out) and a color (none when
	# left out).
	method _parsed_swatches ($swatches) {
		return () unless defined $swatches;
		die ref($self) . ": swatches must be an array reference, got " . describe($swatches) unless ref $swatches eq 'ARRAY';
		my ( @parsed, %seen );
		foreach my $swatch (@$swatches) {
			die ref($self) . ": a swatch must be an array reference [ value, label, color ], got " . describe($swatch) unless ref $swatch eq 'ARRAY' && @$swatch >= 1 && @$swatch <= 3;
			my ( $spec, $label, $rgba ) = @$swatch;
			die ref($self) . ": the value of a swatch must be a non-empty string, got " . describe($spec) unless defined $spec && !ref $spec && length $spec;
			die ref($self) . ": two swatches have the value '$spec'" if $seen{$spec}++;
			push @parsed,
				{
				value => $spec,
				label => optional( \&string, $self, "the label of the swatch '$spec'" => $label ) // $spec,
				rgba  => optional( \&color,  $self, "the color of the swatch '$spec'" => $rgba ),
				};
		}
		return @parsed;
	}

	method _swatch_of ($spec) {
		return undef unless defined $spec;
		return first { $_->{value} eq $spec } @_swatches;
	}

	# ---------------------------------------------------------------------
	# The parts
	# ---------------------------------------------------------------------

	method _swatch_list () {
		my %rgba_of = map { $_->{value} => $_->{rgba} } @_swatches;
		$_list = Term::Fabulous::Widget::Table->new(
			id           => ( $self->id // 'color-picker-' . ++$pickers_built ) . '/list',
			row_id       => 'value',
			selection    => 'single',
			header       => 0,
			border       => 'none',
			column_lines => 'none',
			columns      => [
				{ key => 'sample', width => 'fixed(6)', cell_style => sub ($cell) { my $rgba = $rgba_of{ $cell->{row}{value} }; return defined $rgba ? { text_color => $rgba } : {} } },
				{ key => 'label',  width => 'grow' },
			],
			rows   => [ map { { value => $_->{value}, label => $_->{label}, sample => defined $_->{rgba} ? SAMPLE : '' } } @_swatches ],
			layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
		);
		$_list->on( CursorMove  => sub ( $self, $event ) { $self->_swatch_chosen( $event->row_id ) if defined $event->row_id; return }, owner => $self );
		$_list->on( RowActivate => sub ( $self, $event ) { $self->_swatch_submitted( $event->row_id );                        return }, owner => $self );
		$_frame = framed( $_list, $list_rows );
		my $layout = $_frame->layout;
		$_frame->layout( { %$layout, sizing => { %{ $layout->{sizing} }, width => sizing_grow( $self->_list_minimum_width ) } } );
		return $_frame;
	}

	# Wide enough for the swatch labels (up to LABEL_MINIMUM columns), so
	# that a narrow screen shrinks the field and the sliders first.
	method _list_minimum_width () {
		my $longest = max map { string_columns( $_->{label} ) } @_swatches;
		return LIST_FURNITURE + min( $longest, LABEL_MINIMUM );
	}

	# The field and the sample, the RGB/HSL switch, the channel sliders and
	# the alpha slider.
	method _editor () {
		weaken( my $weak_self = $self );    # for the validator, which the field keeps
		$_column = Term::Fabulous::Widget::Box->new( layout => { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow() } } );

		$_field = Term::Fabulous::Widget::TextField->new(
			placeholder => $self->_placeholder,
			max_length  => 32,
			validator   => sub ($text) { $weak_self ? $weak_self->_color_problem($text) : undef },
			layout      => { sizing => { width => sizing_grow( FIELD_MINIMUM, FIELD_WIDTH ) } },
		);
		$_sample = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_fixed(SAMPLE_WIDTH), height => sizing_fixed(1) } } );
		my $top = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 1, padding => { bottom => 1 } } );
		$top->add_child( $_field, $_sample );
		$_field->on( Change => sub ( $self, $event ) { $self->_typed( $event->value ); return }, owner => $self );
		$_field->on( Submit => sub ( $self, $event ) { $self->_submit;                 return }, owner => $self );

		$_switch = Term::Fabulous::Widget::SegmentedControl->new( options => [ [ RGB => 'rgb' ], [ HSL => 'hsl' ] ], value => $sliders );
		$_switch->on( Change => sub ( $self, $event ) { $self->sliders( $event->value ); return }, owner => $self );
		$_column->add_child( $top, $_switch );

		foreach ( 1 .. 3 ) {
			my ( $row, $label, $slider ) = $self->_slider_row;
			push @_channel_sliders, $slider;
			push @_channel_labels,  $label;
			$_column->add_child($row);
		}
		( $_alpha_row, my $alpha_label, $_alpha_slider ) = $self->_slider_row;
		$alpha_label->text('A');
		$_alpha_slider->set_range( min => 0, max => 255 );
		$_column->add_child($_alpha_row) if $alpha;
		return $_column;
	}

	# A label and a slider in a row; moving the slider writes the value.
	method _slider_row () {
		my $label  = Term::Fabulous::Widget::Text->new( text => ' ' );
		my $slider = Term::Fabulous::Widget::Slider->new( min => 0, max => 255, value_format => '%3d', layout => { sizing => { width => sizing_grow() } } );
		my $row    = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow() }, child_gap => 1 } );
		$row->add_child( $label, $slider );
		$slider->on( Change => sub ( $self, $event ) { $self->_slid; return }, owner => $self );
		return ( $row, $label, $slider );
	}

	method _placeholder () {
		return $alpha ? '#rrggbb or #rrggbbaa' : '#rrggbb';
	}

	# What is wrong with a typed color, or undef: the field's validator.
	method _color_problem ($text) {
		my $rgba = _parsed_color($text);
		return 'Please enter a color: #rrggbb, rgb(...), hsl(...) or a color name.' unless defined $rgba;
		return 'Please enter a color without transparency.' if !$alpha && $rgba->[3] != 255;
		return undef;
	}

	# The color a text stands for as [r, g, b, a], or undef when it is none.
	sub _parsed_color ($text) {
		my $rgba;
		try {
			$rgba = color( __PACKAGE__, color => $text );
		}
		catch ($error) {
			$rgba = undef;
		}
		return $rgba;
	}

	sub _hex_of ( $red, $green, $blue, $opacity ) {
		return sprintf( '#%02x%02x%02x', $red, $green, $blue ) if $opacity == 255;
		return sprintf( '#%02x%02x%02x%02x', $red, $green, $blue, $opacity );
	}

	# ---------------------------------------------------------------------
	# Showing the value
	# ---------------------------------------------------------------------

	# Sets the value from the program: the field, the sliders and the list
	# follow. Dies on a value that is neither a swatch's nor a color.
	method _show_value ($spec) {
		my $swatch = $self->_swatch_of($spec);
		my $rgba   = defined $spec && !defined $swatch ? $self->_checked_color($spec) : undef;
		( $chosen, $_rgba ) = ( $spec, defined $swatch ? $swatch->{rgba} : $rgba );
		$_field->value( defined $swatch ? ( $spec =~ /\A#/ ? $spec : '' ) : $spec // '' );
		$_field->editor->select_all;    # typing replaces the color
		$self->_show_in_list($swatch);
		$self->_show_on_sliders;
		$self->_show_sample;
		return;
	}

	method _checked_color ($spec) {
		my $rgba = color( $self, value => $spec );
		die ref($self) . ": value must be opaque without alpha, got " . describe($spec) if !$alpha && $rgba->[3] != 255;
		return $rgba;
	}

	# Selects the swatch in the list, scrolled so that it is near the
	# middle; without one, the list has no selection.
	method _show_in_list ($swatch) {
		return unless defined $_list;
		return $_list->set_selection unless defined $swatch;
		my ($index) = grep { $_swatches[$_] == $swatch } 0 .. $#_swatches;
		my $below = min( $#_swatches, $index + int( $list_rows / 2 ) );
		$_list->cursor( $_swatches[$below]{value} );
		$_list->cursor( $swatch->{value} );
		$_list->set_selection( $swatch->{value} );
		return;
	}

	# The sliders show the color in the current mode; without a color,
	# black.
	method _show_on_sliders () {
		my ( $red, $green, $blue, $opacity ) = defined $_rgba ? @$_rgba : ( 0, 0, 0, 255 );
		my @levels = $sliders eq 'hsl' ? Term::Fabulous::Color->rgb_to_hsl( $red, $green, $blue ) : ( $red, $green, $blue );
		$_channel_sliders[$_]->value( $levels[$_] ) foreach 0 .. 2;
		$_alpha_slider->value($opacity);
		return;
	}

	method _show_sample () {
		return $_sample->background_color($_rgba) if defined $_rgba && $_rgba->[3] > 0;
		$_sample->reset_look('background_color');
		return;
	}

	# The channel sliders take the ranges and labels of the mode, then
	# read the color again; the value stays as it is.
	method _use_sliders () {
		my $channels = $CHANNELS_OF_MODE{$sliders};
		foreach my $index ( 0 .. 2 ) {
			my ( $label, $maximum ) = @{ $channels->[$index] };
			$_channel_sliders[$index]->set_range( min => 0, max => $maximum );
			$_channel_labels[$index]->text($label);
		}
		$self->_show_on_sliders;
		return;
	}

	# ---------------------------------------------------------------------
	# What the user does
	# ---------------------------------------------------------------------

	method _typed ($text) {
		return unless length $text && $_field->is_valid;
		( $chosen, $_rgba ) = ( $text, _parsed_color($text) );
		$_list->set_selection if defined $_list;
		$self->_show_on_sliders;
		$self->_show_sample;
		$self->_fire_change;
		return;
	}

	# A slider moved: the value is written from the sliders, which stay
	# as they are (HSL in whole numbers cannot reach every RGB color).
	method _slid () {
		my @levels  = map { $_->value } @_channel_sliders;
		my @rgb     = $sliders eq 'hsl' ? Term::Fabulous::Color->hsl_to_rgb(@levels) : @levels;
		my $opacity = $alpha            ? $_alpha_slider->value                      : 255;
		$chosen = _hex_of( @rgb, $opacity );
		$_rgba  = [ @rgb, $opacity ];
		$_field->value($chosen);
		$_list->set_selection if defined $_list;
		$self->_show_sample;
		$self->_fire_change;
		return;
	}

	method _swatch_chosen ($spec) {
		my $swatch = $self->_swatch_of($spec);
		( $chosen, $_rgba ) = ( $spec, $swatch->{rgba} );
		$_field->value( $spec =~ /\A#/ ? $spec : '' );
		$_list->set_selection($spec);
		$self->_show_on_sliders;
		$self->_show_sample;
		$self->_fire_change;
		return;
	}

	# Enter on a swatch row: a row under the cursor but not chosen (after
	# typing or sliding) is chosen first.
	method _swatch_submitted ($spec) {
		$self->_swatch_chosen($spec) if defined $spec && ( $chosen // '' ) ne $spec;
		$self->_submit;
		return;
	}

	method _fire_change () {
		$self->fire_event( Term::Fabulous::Event::Change->new( value => $chosen ) );
		return;
	}

	method _submit () {
		$self->fire_event( Term::Fabulous::Event::Submit->new( value => $chosen ) );
		return;
	}

	# ---------------------------------------------------------------------
	# Accessors
	# ---------------------------------------------------------------------

	method value (@new) {
		return $chosen unless @new;
		$self->_show_value( optional( \&string, $self, value => $new[0] ) );
		return $chosen;
	}

	method rgba () {
		return defined $_rgba ? [@$_rgba] : undef;
	}

	method sliders (@new) {
		return $sliders unless @new;
		$sliders = one_of( $self, sliders => $new[0], keys %CHANNELS_OF_MODE );
		$_switch->value($sliders);
		$self->_use_sliders;
		return $sliders;
	}

	method alpha (@new) {
		return $alpha unless @new;
		my $wanted = boolean( $self, alpha => $new[0] );
		die ref($self) . ": cannot turn alpha off while the value " . describe($chosen) . " is translucent"
			if !$wanted && defined $_rgba && $_rgba->[3] != 255 && !defined $self->_swatch_of($chosen);
		$alpha = $wanted;
		$_column->add_child($_alpha_row) if $alpha && !$_column->has_child($_alpha_row);
		$_column->remove_child($_alpha_row) unless $alpha;
		$_field->placeholder( $self->_placeholder );
		$_field->validate;
		return $alpha;
	}

	method list_rows (@new) {
		return $list_rows unless @new;
		$list_rows = positive_integer( $self, list_rows => $new[0] );
		if ( defined $_frame ) {
			my $layout = $_frame->layout;
			$_frame->layout( { %$layout, sizing => { %{ $layout->{sizing} }, height => sizing_fixed( $list_rows + 2 ) } } );
		}
		return $list_rows;
	}

	# The field's validation: what Prompt and forms read.
	method validate () { return $_field->validate }
	method error ()    { return $_field->error }
	method is_valid () { return $_field->is_valid }

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, ( map { $_ => 'scalar' } qw(value sliders list_rows) ), alpha => 'boolean' );
	}
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Widget::ColorPicker - A field, sliders and swatches for
choosing a color

=head1 SYNOPSIS

	use Clay::UI::Enum::Result;
	use Term::Fabulous::Widget::ColorPicker;

	my $picker = Term::Fabulous::Widget::ColorPicker->new(
		id       => 'accent',
		value    => '#61afef',
		swatches => [ [ blue => 'Blue', '#61afef' ], [ red => 'Red', '#e06c75' ], [ none => 'No color' ] ],
	);
	$picker->on( Change => sub ($event) {
		preview( $event->value );    # '#3b82f6', 'red', 'none', ...
		return Clay::UI::Enum::Result->CONTINUE;
	} );

	say $picker->value;               # #61afef
	$picker->value('red');            # programmatic: fires no Change
	say join ', ', @{ $picker->rgba };    # 224, 108, 117, 255

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/widget-color-picker.svg" alt="Two color pickers. The upper one has a framed list of named swatches with color samples on the left, Orange selected, an empty field with a sample of the orange next to it, the RGB/HSL switch on RGB and the red, green, blue and alpha sliders at the orange. The lower one has no list and no alpha slider, its field shows #2e8b57 and its sliders show hue, saturation and lightness. Below each picker a line names the chosen value and its channels"></p>

=end html

The program is F<examples/widgets/color-picker.pl>. The upper picker
offers named swatches next to its field and sliders; the lower one has
no swatches and no alpha slider and shows its sliders in HSL. The line
below each picker shows the value it has chosen.

=head1 DESCRIPTION

A color picker lets the user choose a color in three ways: by writing
it into a field (C<#rrggbb>, C<#rrggbbaa>, C<rgb(...)>, C<hsl(...)>, a
color name; everything L<Term::Fabulous::Color> reads), by moving
sliders, and, when the program gives it a list of I<swatches>, by
picking a named one from a list. A sample next to the field shows the
color.

The sliders show red, green and blue (each 0 to 255), or hue (0 to 359),
saturation and lightness (each 0 to 100). A
L<Term::Fabulous::Widget::SegmentedControl> above them switches between
the two. An alpha slider (0 to 255) below them is there unless the
picker is built with C<< alpha => 0 >>.

The picker's value is a string:

=over

=item * what the user typed, when it is a color;

=item * the color the sliders give, written as C<#rrggbb> (C<#rrggbbaa>
when the alpha is not 255);

=item * a swatch's value, which need not be a color at all: a theme's
token name such as C<accent>, or C<none> for no color.

=back

L</rgba> gives the color the value stands for as numbers.

The picker is built from other widgets (a
L<Term::Fabulous::Widget::TextField>, a
L<Term::Fabulous::Widget::Table> in a frame, a SegmentedControl,
L<Term::Fabulous::Widget::Slider>s) and takes the keyboard focus only
through them; Tab moves from part to part. It sits inline in a screen,
a form or a L<Term::Fabulous::Widget::Prompt> (see L</As a field of a
prompt>), and has no theme family of its own: its parts are drawn as
their families say. It grows to the width of its parent. When that is
narrow, the field shrinks from 22 columns to 10 and the sliders get
shorter, while the swatch list keeps room for labels of up to 20
columns.

=head2 How the parts follow each other

=over

=item * Typing a valid color sets the value; the sliders move to it and
the list loses its selection. A text that is no color yet changes
nothing but the field, which shows the invalid look.

=item * Moving a slider sets the value to the color of the three
sliders (and the alpha slider) and writes it into the field; the list
loses its selection. The other sliders stay where they are, so in HSL
mode the hue is kept when the saturation goes to 0 and back, although a
gray has no hue.

=item * The cursor on a swatch sets the value to the swatch's value. The
field shows it when it starts with C<#> and is empty otherwise; the
sliders move to the swatch's color, or to black for a swatch without
one.

=item * The RGB/HSL switch reads the sliders from the color again and
leaves the value as it is.

=item * Setting L</value> from the program does all of this at once:
field, sliders and list show the new value.

=back

=head2 As a field of a prompt

A picker can be the C<input> of a field of a
L<Term::Fabulous::Widget::Prompt>. Its C<validate>, C<error> and
C<is_valid> (see L</"validate, error, is_valid">) are those of its text
field, so a primary button keeps the prompt open while the field holds
something that is no color (or a translucent one with
C<< alpha => 0 >>), the prompt's error line says why, and the focus goes
to the text field. Enter in the field or on a swatch presses the
prompt's default button, and the answer's C<values> hold the picker's
L</value>.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $picker = Term::Fabulous::Widget::ColorPicker->new(%parameters);

Accepts the parameters of L<Term::Fabulous::Widget::Box/CONSTRUCTOR>
(C<id>, C<layout>, C<background_color>, ...) and the ones below. All
are optional, and unknown parameters die.

=over

=item C<id>

As for every widget. The swatch list is a table whose id is
C<"$id/list">; without an id, the picker makes one up for it.

=item C<value>

The value the picker starts with: a swatch's value, a color in any
format L<Term::Fabulous::Color> reads, or C<undef> (the default: no
value, empty field, sliders at black). Anything else dies, and so does
a translucent color with C<< alpha => 0 >>.

=item C<alpha>

A boolean. Default: 1. With 1 there is an alpha slider and the field
takes translucent colors. With 0 the alpha slider is left out, the
sliders always write opaque colors, and the field rejects a color whose
alpha is not 255 (swatches are not checked).

=item C<swatches>

An array reference of swatches, or C<undef> (the default: no list). A
swatch is C<[ $value, $label, $color ]>: the value the picker takes
(a non-empty string, unique among the swatches), the label the list
shows (the value when left out), and the color the sample, the sliders
and L</rgba> show for it, in any format L<Term::Fabulous::Color> reads
(none when left out or C<undef>, as for C<none>). The list shows the
color as a sample before the label. Anything else dies.

=item C<sliders>

C<rgb> (the default) or C<hsl>: what the sliders show first. The user
switches with the control above them.

=item C<list_rows>

A positive integer. Default: 12. How many swatches the list shows at
once; it scrolls for more.

=back

=head1 METHODS

The methods of L<Term::Fabulous::Widget::Box>, plus these. The
accessors work like those of the other widgets: without an argument
they return the current value, with one they set it, checked as
C<new> checks it, and return the new value. An invalid value dies and
leaves the old one. Setting from the program fires no events.

=head2 value

	my $spec = $picker->value;
	$picker->value('#ff8800');
	$picker->value('accent');    # a swatch's value
	$picker->value(undef);       # no value

The value chosen now (see L</DESCRIPTION>), or C<undef>. Setting it
shows the new value in the field, the sliders and the list.

=head2 rgba

	my ( $red, $green, $blue, $alpha ) = @{ $picker->rgba // [ 0, 0, 0, 255 ] };

The color of the value as a new array reference C<[r, g, b, a]> with
channels from 0 to 255, or C<undef> when the value has no color (no
value, or a swatch without a color). There is no writer; set
L</value>.

=head2 sliders

	$picker->sliders('hsl');

C<rgb> or C<hsl>: what the sliders show. Setting it moves the switch
and reads the sliders from the color again; the value stays.

=head2 alpha

	$picker->alpha(0);

Whether there is an alpha slider and the field takes translucent
colors. Turning it off dies while the value is a translucent color
(not a swatch).

=head2 list_rows

	$picker->list_rows(8);

How many swatches the list shows at once.

=head2 validate, error, is_valid

	if ( !$picker->is_valid ) {
		$message->text( $picker->error );
	}

Those of the text field (see L<Term::Fabulous::Widget::Input/error>):
C<error> is what is wrong with the text in the field, or C<undef> for
an empty field or a valid color; C<is_valid> says whether there is
nothing wrong; C<validate> reports a changed message with a
C<ValidityChange> event of the field and returns it.

=head1 EVENTS

The picker fires its own events, with itself as the target. The
C<Change>, C<Submit>, C<CursorMove> and C<RowActivate> events of its
parts stop at the parts, so a listener on the picker or above it sees
only these:

=over

=item C<Change>

L<Term::Fabulous::Event::Change> when the user changes the value: types
a valid color, moves a slider, or moves the cursor onto a swatch.
C<value> is the new value. The RGB/HSL switch and programmatic changes
fire none.

=item C<Submit>

L<Term::Fabulous::Event::Submit> when the user presses C<Enter> in the
field or activates a swatch (C<Enter>, a double click). A swatch that is
not the value yet (the cursor stayed on it while the user typed or
moved a slider) becomes the value first, with its C<Change>. C<value>
is the value; check C<is_valid> first if the field may hold an invalid
text.

=back

The text field still fires its C<ValidityChange>, which bubbles on as
usual.

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<value> and C<sliders> (strings), C<alpha> (a boolean) and
C<list_rows> (a number). The swatches can only be given from Perl, so
a picker built from a layout has no list:

=for highlighter language=kdl

	use Term::Fabulous::Widget::ColorPicker as ColorPicker

	ColorPicker "background" {
		value "#282c34"
		alpha #false
		sliders "hsl"
	}

=for highlighter language=perl

	my $picker = $root->find_by_id('background');
	$picker->on( Change => sub ($event) { ...; return } );

=head1 SEE ALSO

L<Term::Fabulous::Color> for the color formats,
L<Term::Fabulous::Widget::Prompt>, L<Term::Fabulous::Widget::Slider>,
L<Term::Fabulous::Widget::SegmentedControl>,
L<Term::Fabulous::Widget::TextField>, L<Term::Fabulous::Widget::Box>.

=cut
