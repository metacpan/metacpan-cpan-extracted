package Term::Fabulous::ThemeEditor::ValueDialog;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Dialog;

# The dialog that edits one setting of a theme: a color picker with the
# palette's tokens as swatches for a color, a list of border styles or
# other choices, or a field for the name. Every change shows in the
# preview at once; Apply writes it to the theme, Cancel takes it back.
class Term::Fabulous::ThemeEditor::ValueDialog :isa(Term::Fabulous::Widget::Dialog) :strict(params) {
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM CLAY_ATTACH_TO_ROOT CLAY_ATTACH_POINT_RIGHT_CENTER);
	use Feature::Compat::Try;
	use List::Util qw(any min);
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Check qw(color);
	use Term::Fabulous::Enum::BorderStyle;
	use Term::Fabulous::Theme;
	use Term::Fabulous::Theme::Document;
	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Widget::Button;
	use Term::Fabulous::Widget::ColorPicker;
	use Term::Fabulous::Widget::Table;
	use Term::Fabulous::Widget::Table::Frame qw(framed);
	use Term::Fabulous::Widget::Text;
	use Term::Fabulous::Widget::TextField;

	use constant LIST_ID   => 'theme-editor-value-list';
	use constant PICKER_ID => 'theme-editor-color';

	field $key        :param :reader;
	field $current    :param;    # the value the theme has now (effective)
	field $is_set     :param = 0;    # whether the theme sets it
	field $default    :param = undef;    # what the key falls back to, for the hint
	field $palette    :param;    # token => [r, g, b, a], for the swatches
	field $on_preview :param;    # code: shows a value (undef: the theme as it is)
	field $on_apply   :param;    # code: writes a value
	field $on_reset   :param;    # code: removes the setting
	field $list_rows  :param = 12;    # how many rows the list shows

	field $kind;    # color, palette, style, boolean, name, base
	field $value;    # the value chosen now
	field $list;
	field $picker;
	field $message;

	ADJUST {
		my $parsed = Term::Fabulous::Theme::Document::parse_key($key);
		$kind
			= $parsed->{section} eq 'palette' ? 'palette'
			: $parsed->{section} eq 'theme'   ? ( $parsed->{field} eq 'name' ? 'name' : 'base' )
			:                                   Term::Fabulous::Theme::slot_info( @{$parsed}{qw(family slot)} )->{kind};
		$value = $current;

		# At the right edge of the screen and without dimming it, so the
		# preview on the left shows the value being chosen in its true
		# colors.
		$self->backdrop_color( [ 0, 0, 0, 0 ] );
		$self->floating(
			{
				attach_to     => CLAY_ATTACH_TO_ROOT,
				attach_points => { element => CLAY_ATTACH_POINT_RIGHT_CENTER, parent => CLAY_ATTACH_POINT_RIGHT_CENTER },
				offset        => { x       => -1,                             y      => 0 },
				z_index       => $self->z_index + 1,
			}
		);
		$self->layout( { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow( 0, 64 ) }, padding => { left => 2, right => 2, top => 1, bottom => 1 }, child_gap => 1 } );

		$self->add_child( Term::Fabulous::Widget::Text->new( text => "Edit $key", bold => 1 ) );
		$self->add_child( Term::Fabulous::Widget::Text->new( text => $self->_hint($parsed) ) );
		$self->add_child( $self->_chooser($parsed) );
		$message = Term::Fabulous::Widget::Text->new( text => '' );
		$self->add_child( $message, $self->_buttons );

		weaken( my $weak_self = $self );
		$self->on( Close => sub ($event) { $weak_self->_closed; return Clay::UI::Enum::Result->CONTINUE } );
	}

	method value () {
		return $value;
	}

	# What the setting is now and what Reset gives it; tokens are named as
	# tokens (a token may be called like a state: disabled).
	method _hint ($parsed) {
		my $now
			= $is_set
			? 'The theme sets it to ' . $self->_words($current) . '.'
			: 'The theme does not set it' . ( defined $current ? '; it is ' . $self->_words($current) . ' now.' : '.' );
		return $now unless defined $default;
		return "$now That is its default, too." if $is_set && defined $current && $current eq $default;
		return "$now Reset gives it back to " . $self->_words($default) . '.';
	}

	method _words ($spec) {
		return exists $palette->{$spec} ? qq{the token "$spec"} : $spec;
	}

	# ---------------------------------------------------------------------
	# What the dialog offers
	# ---------------------------------------------------------------------

	method _chooser ($parsed) {
		return $self->_name_field if $kind eq 'name';
		return $self->_list( map { [ $_, $_ ] } Term::Fabulous::Theme::builtin_names() ) if $kind eq 'base';
		return $self->_style_list($parsed) if $kind eq 'style';
		return $self->_list( [ 'true', 'true' ], [ 'false', 'false' ] ) if $kind eq 'boolean';
		return $self->_color_picker if $kind eq 'palette';    # a token's value must be a color
		my $info     = Term::Fabulous::Theme::slot_info( @{$parsed}{qw(family slot)} );
		my @swatches = map { [ $_, $_, $palette->{$_} ] } Term::Fabulous::Theme::tokens();
		push @swatches, [ 'none',    'none (no color)' ] unless $info->{required};
		push @swatches, [ 'reverse', 'reverse video' ] if $info->{reverse} && $parsed->{state} eq 'pressed';
		return $self->_color_picker(@swatches);
	}

	method _name_field () {
		my $field = Term::Fabulous::Widget::TextField->new( value => $current // '', placeholder => 'The theme\'s name', layout => { sizing => { width => sizing_grow() } } );
		$field->editor->select_all;
		weaken( my $weak_self = $self );
		$field->on( Change => sub ($event) { $weak_self->_choose( $event->value ); return Clay::UI::Enum::Result->CONTINUE } );
		$field->on( Submit => sub ($event) { $weak_self->apply;                    return } );
		return $field;
	}

	method _style_list ($parsed) {
		my $info    = Term::Fabulous::Theme::slot_info( @{$parsed}{qw(family slot)} );
		my @styles  = $info->{grid} ? Term::Fabulous::Enum::BorderStyle->get_grid_styles : Term::Fabulous::Enum::BorderStyle->values;
		my @choices = map {
			my ( $corner, $edge, $other ) = $_->get_top_glyphs;
			[ $_->name, $_->name, "$corner$edge$edge$other" ]
		} @styles;
		push @choices, [ 'none', 'none (no border style)' ] unless $info->{required};
		return $self->_list(@choices);
	}

	# A list of [ value, label, sample ] choices; the cursor on one
	# chooses it.
	method _list (@choices) {
		$list = Term::Fabulous::Widget::Table->new(
			id           => LIST_ID,
			row_id       => 'value',
			selection    => 'single',
			header       => 0,
			border       => 'none',
			column_lines => 'none',
			columns      => [
				{ key => 'sample', width => 'fixed(6)' },
				{ key => 'label',  width => 'grow' },
			],
			rows   => [ map { { value => $_->[0], label => $_->[1], sample => $_->[2] // '' } } @choices ],
			layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
		);
		my ($chosen) = grep { $choices[$_][0] eq ( $current // '' ) } 0 .. $#choices;
		if ( defined $chosen ) {
			my $below = min( $#choices, $chosen + int( $list_rows / 2 ) );
			$list->cursor( $choices[$below][0] );    # scrolls so that the chosen value is near the middle
			$list->cursor( $choices[$chosen][0] );
			$list->set_selection( $choices[$chosen][0] );
		}
		weaken( my $weak_self = $self );
		$list->on( CursorMove  => sub ($event) { $weak_self->_choose( $event->row_id ) if defined $event->row_id; return Clay::UI::Enum::Result->CONTINUE } );
		$list->on( RowActivate => sub ($event) { $weak_self->apply;                                               return } );
		return framed( $list, $list_rows );    # no header
	}

	# The color picker, with the swatches given ([ value, label, color ]):
	# its changes show in the preview, Enter applies.
	method _color_picker (@swatches) {
		$picker = Term::Fabulous::Widget::ColorPicker->new(
			id        => PICKER_ID,
			value     => _pickable( $current, @swatches ),
			swatches  => @swatches ? \@swatches : undef,
			list_rows => $list_rows,
		);
		weaken( my $weak_self = $self );
		$picker->on( Change => sub ($event) { $weak_self->_choose( $event->value ); return Clay::UI::Enum::Result->CONTINUE } );
		$picker->on( Submit => sub ($event) { $weak_self->apply;                    return } );
		return $picker;
	}

	# The value the picker starts with: the current one when the picker
	# can show it (a swatch's value or a color), else none.
	sub _pickable ( $spec, @swatches ) {
		return undef unless defined $spec;
		return $spec if any { $_->[0] eq $spec } @swatches;
		try {
			color( __PACKAGE__, value => $spec );
		}
		catch ($error) {
			return undef;
		}
		return $spec;
	}

	method _buttons () {
		my $row = Term::Fabulous::Widget::Box->new( layout => { child_gap => 2 } );
		weaken( my $weak_self = $self );
		my @buttons = ( [ 'Apply', ['primary'], sub { $weak_self->apply } ], [ 'Reset to default', [], sub { $weak_self->reset } ], [ 'Cancel', [], sub { $weak_self->cancel } ] );
		foreach my $definition (@buttons) {
			my ( $label, $classes, $action ) = @$definition;
			next if $label =~ /\AReset/ && !$is_set;
			my $button = Term::Fabulous::Widget::Button->new( bordered => 1, classes => $classes, layout => { padding => { left => 1, right => 1 } } );
			$button->add_child( Term::Fabulous::Widget::Text->new( text => $label ) );
			$button->on( Activate => sub ($event) { $action->(); return } );
			$row->add_child($button);
		}
		return $row;
	}

	# ---------------------------------------------------------------------
	# Choosing
	# ---------------------------------------------------------------------

	# A value was chosen in the list, the picker or the field; the preview
	# shows it.
	method _choose ($chosen) {
		$value = $chosen;
		$message->text('');
		$on_preview->( $self->_checked($chosen) ? $chosen : undef );
		return;
	}

	# Whether the key can take a value; the message says why not.
	method _checked ($spec) {
		try {
			Term::Fabulous::Theme::Document->parse('')->with_setting( $key, $spec );
		}
		catch ($error) {
			$error =~ s/\ATerm::Fabulous::Theme::Document: //;
			$error =~ s/\n\z//;
			$message->text($error);
			return 0;
		}
		return 1;
	}

	# ---------------------------------------------------------------------
	# Leaving
	# ---------------------------------------------------------------------

	field $finished = 0;

	# A text in the picker's field that is no color is not applied; the
	# message line says what the field wants.
	method apply () {
		if ( defined $picker && !$picker->is_valid ) {
			$message->text( $picker->error );
			return $self;
		}
		return $self unless defined $value && length $value && $self->_checked($value);
		$finished = 1;
		$self->close;
		$on_apply->($value);
		return $self;
	}

	method reset () {
		$finished = 1;
		$self->close;
		$on_reset->();
		return $self;
	}

	method cancel () {
		$self->close;
		return $self;
	}

	# Closed without Apply or Reset (Cancel, Escape): the preview shows the
	# theme as it is again.
	method _closed () {
		$on_preview->(undef) unless $finished;
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::ThemeEditor::ValueDialog - The dialog that edits one
setting in the theme editor

=head1 DESCRIPTION

Part of L<Term::Fabulous::ThemeEditor>; not meant to be used on its
own. The dialog opens at the right edge of the screen and does not dim
the screen behind it, so the preview on the left shows the value being
chosen in its true colors. What the dialog offers depends on the
setting:

=over

=item a color slot

A L<Term::Fabulous::Widget::ColorPicker>: the palette's tokens as
swatches with their colors (and C<none> where the slot may have no
color, C<reverse> for C<button.background.pressed>), and a color of its
own: a field for C<#rrggbb>, C<#rrggbbaa>, C<rgb(...)>, C<hsl(...)> or a
color name, a sample, sliders for red, green and blue or for hue,
saturation and lightness (switched with C<RGB> and C<HSL>), and one for
alpha.

=item a palette token

The color picker without swatches: a token's value must be a color.

=item a style slot

A list of the border styles with a sample of each (only those with
joints for C<tabs.line.style>, and C<none> where the slot may have no
style).

=item C<theme.name>, C<theme.extends>

A field for the name; a list of the built-in themes.

=back

A list shows that it has the keyboard focus with its frame in the
accent color. Every choice shows in the preview at once. C<Apply> (or
C<Enter> in a list or a field) writes the value to the theme as one undo
step, C<Reset to default> removes the setting, and C<Cancel> or
C<Escape> leaves the theme as it was. A value the setting cannot take,
or a text in the color field that is no color, is not applied; the line
above the buttons says why.

=head1 CONSTRUCTOR

=head2 new

	my $dialog = Term::Fabulous::ThemeEditor::ValueDialog->new(
		key        => 'button.border.color.focused',
		current    => 'accent',
		is_set     => 0,
		default    => 'accent',
		palette    => $theme->palette,
		on_preview => sub ($value) { ... },    # undef: show the theme as it is
		on_apply   => sub ($value) { ... },
		on_reset   => sub () { ... },
		list_rows  => 12,    # the rows of the list of tokens or styles
	);

=head1 METHODS

=head2 key, value

The setting's key and the value chosen now.

=head2 apply, reset, cancel

What the buttons do.

=head1 SEE ALSO

L<Term::Fabulous::ThemeEditor>.

=cut
