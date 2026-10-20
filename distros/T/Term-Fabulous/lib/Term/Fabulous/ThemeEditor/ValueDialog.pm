package Term::Fabulous::ThemeEditor::ValueDialog;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Dialog;

# The dialog that edits one setting of a theme: a color picker with the
# palette's tokens as swatches for a color, a list of border styles or
# other choices, or a field for the name. Every change fires Change for
# the preview at once; the answer apply carries the value, reset asks to
# remove the setting, and every other answer takes the preview back.
class Term::Fabulous::ThemeEditor::ValueDialog
	:isa(Term::Fabulous::Widget::Dialog)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use Clay::XS qw(sizing_grow CLAY_TOP_TO_BOTTOM);
	use Feature::Compat::Try;
	use List::Util qw(any min);
	use Term::Fabulous::Check qw(color);
	use Term::Fabulous::Enum::BorderStyle;
	use Term::Fabulous::Event::Change;
	use Term::Fabulous::Text::Markup qw(escape_markup);
	use Term::Fabulous::Theme;
	use Term::Fabulous::Theme::Document;
	use Term::Fabulous::Widget::ColorPicker;
	use Term::Fabulous::Widget::Table;
	use Term::Fabulous::Widget::Table::Frame qw(framed);
	use Term::Fabulous::Widget::Text;
	use Term::Fabulous::Widget::TextField;

	use constant LIST_ID   => 'theme-editor-value-list';
	use constant PICKER_ID => 'theme-editor-color';

	field $key       :param :reader;
	field $current   :param;    # the value the theme has now (effective)
	field $is_set    :param = 0;    # whether the theme sets it
	field $default   :param = undef;    # what the key falls back to, for the hint
	field $palette   :param;    # token => [r, g, b, a], for the swatches
	field $list_rows :param = 12;    # how many rows the list shows

	field $kind;    # color, palette, style, boolean, name, base
	field $value;    # the value chosen now
	field $list;
	field $picker;

	# At the right edge of the screen, titled with the key, with Reset only
	# for a setting the theme has; the line above the buttons keeps its
	# place.
	sub BUILDARGS ( $class, %params ) {
		my $key = $params{key} // die "$class: a key is required";
		return $class->SUPER::BUILDARGS(
			%params,
			title       => "Edit $key",
			placement   => 'right',
			notice_line => 'kept',
			buttons     => [ { id => 'apply', label => 'Apply', primary => 1 }, ( $params{is_set} ? { id => 'reset', label => 'Reset to default' } : () ), { id => 'cancel', label => 'Cancel' } ],
		);
	}

	ADJUST {
		my $parsed = Term::Fabulous::Theme::Document::parse_key($key);
		$kind
			= $parsed->{section} eq 'palette' ? 'palette'
			: $parsed->{section} eq 'theme'   ? ( $parsed->{field} eq 'name' ? 'name' : 'base' )
			:                                   Term::Fabulous::Theme::slot_info( @{$parsed}{qw(family slot)} )->{kind};
		$value = $current;

		# Without dimming the screen, so the preview on the left shows the
		# value being chosen in its true colors.
		$self->backdrop_color( [ 0, 0, 0, 0 ] );
		$self->layout( { layout_direction => CLAY_TOP_TO_BOTTOM, sizing => { width => sizing_grow( 0, 64 ) }, padding => { left => 2, right => 2, top => 1, bottom => 1 }, child_gap => 1 } );

		$self->add_child( Term::Fabulous::Widget::Text->new( text => $self->_hint($parsed) ) );
		$self->add_child( $self->_chooser($parsed) );
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
		$field->on( Change => sub ( $self, $event ) { $self->_choose( $event->value ); return Clay::UI::Enum::Result->HANDLED }, owner => $self );
		$field->on( Submit => sub ( $self, $event ) { $self->apply;                    return },                                 owner => $self );
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
		$list->on( CursorMove  => sub ( $self, $event ) { $self->_choose( $event->row_id ) if defined $event->row_id; return Clay::UI::Enum::Result->CONTINUE }, owner => $self );
		$list->on( RowActivate => sub ( $self, $event ) { $self->apply;                                               return },                                  owner => $self );
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
		$picker->on( Change => sub ( $self, $event ) { $self->_choose( $event->value ); return Clay::UI::Enum::Result->HANDLED }, owner => $self );
		$picker->on( Submit => sub ( $self, $event ) { $self->apply;                    return },                                 owner => $self );
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

	# ---------------------------------------------------------------------
	# Choosing
	# ---------------------------------------------------------------------

	# A value was chosen in the list, the picker or the field: the dialog
	# fires Change with it for the preview, or with undef for a value the
	# key cannot take (the preview shows the theme as it is).
	method _choose ($chosen) {
		$value = $chosen;
		$self->notice('');
		$self->fire_event( Term::Fabulous::Event::Change->new( value => $self->_checked($chosen) ? $chosen : undef ) );
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
			$self->notice( escape_markup($error) );
			return 0;
		}
		return 1;
	}

	# ---------------------------------------------------------------------
	# Leaving
	# ---------------------------------------------------------------------

	method press_button :override ($id) {
		return $self->apply if $id eq 'apply';
		return $self->SUPER::press_button($id);
	}

	# A text in the picker's field that is no color is not applied; the
	# notice line says what the field wants.
	method apply () {
		if ( defined $picker && !$picker->is_valid ) {
			$self->notice( escape_markup( $picker->error ) );
			return $self;
		}
		return $self unless defined $value && length $value && $self->_checked($value);
		return $self->answer( apply => value => $value );
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
		key       => 'button.border.color.focused',
		current   => 'accent',
		is_set    => 0,
		default   => 'accent',
		palette   => $theme->palette,
		list_rows => 12,    # the rows of the list of tokens or styles
	);
	$dialog->on( Change => sub ($event) { preview( $event->value ); return } );    # undef: the theme as it is
	$dialog->on( Answer => sub ($event) { ... } );

The dialog is a L<Term::Fabulous::Widget::Dialog> with the title
C<Edit KEY>, on the right (C<< placement => 'right' >>), with the
buttons C<apply> (primary), C<reset> (only for a setting the theme
sets) and C<cancel>, and a notice line that keeps its place.

=head1 METHODS

=head2 key, value

The setting's key and the value chosen now.

=head2 apply

What C<Apply> and C<Enter> do: answers C<apply> with the value, unless
the value cannot be applied; then the notice line says why.

=head1 EVENTS

=over

=item C<Change> (L<Term::Fabulous::Event::Change>)

A value was chosen: the value to preview, or C<undef> for one the key
cannot take. Fired on the dialog; the C<Change> events of its inputs do
not bubble past it.

=item C<Answer> (L<Term::Fabulous::Event::Answer>)

C<apply> with C<< { value => $value } >>, C<reset>, C<cancel>, or
C<cancel> dismissed (Escape).

=back

=head1 SEE ALSO

L<Term::Fabulous::ThemeEditor>.

=cut
