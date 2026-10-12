package Term::Fabulous::Role::Themed;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

role Term::Fabulous::Role::Themed {
	use Scalar::Util qw(blessed);
	use Term::Fabulous::Check qw(border_sides border_style cell_color color describe optional);
	use Term::Fabulous::Theme;

	# The family of the class (a class method): button, input, ...
	method theme_family;

	# The themed parameters of the class (a class method), as
	# name => [ slot, state ] or name => [ slot, state, kind ]; a subclass
	# adds its own to its parent's. A kind says how a value is checked
	# (see %KIND); the role takes the parameters of a kind from the
	# constructor and declares them as layout properties. A slot of undef
	# (with a kind) is a parameter the family has no slot for: only an
	# explicit value counts.
	method themed_params;

	# The state the widget shows now, from the states its family's slots
	# have: 'normal', 'focused', ...
	method look_state;

	# Called by reset_look for a parameter whose explicit value the class
	# keeps outside the role (a Clay::UI field, say): clears it.
	method look_reset ($name);

	# The class names of the widget (an array reference), which select the
	# theme's variants.
	method classes;

	# Explicit values, under the parameter name; the theme fills the rest.
	field %_override;

	# The looks of the family for the widget's classes, from the theme of
	# the UI the widget is in, as of a theme generation.
	field $_look_table;
	field $_look_generation = -1;

	# Kind => how a value is checked (Term::Fabulous::Check), what a
	# message calls a value, whether undef is a value (none) rather than a
	# mistake, and the kind of its layout property.
	my %KIND = (
		color               => { check => \&color,                   noun        => 'a color',                    property => 'color' },
		cell_color          => { check => \&cell_color,              noun        => 'a color',                    property => 'color' },
		optional_color      => { check => _optional( \&color ),      takes_undef => 1,                            property => 'scalar' },
		optional_cell_color => { check => _optional( \&cell_color ), takes_undef => 1,                            property => 'scalar' },
		border_style        => { check => \&border_style,            noun        => 'a border style or its name', property => 'scalar' },
		grid_border_style   => {
			check    => sub ( $owner, $name, $value ) { border_style( $owner, $name, $value, grid => 1 ) },
			noun     => 'a border style with joints or its name',
			property => 'scalar',
		},
		border_sides => { check => \&border_sides, noun => 'a boolean or a hash reference of sides', property => 'border_sides' },
	);

	sub _optional ($check) {
		return sub ( $owner, $name, $value ) { optional( $check, $owner, $name, $value ) };
	}

	# name => { slot, state, and with a kind: check, noun, takes_undef,
	# property } and "slot.state" => name per class, checked against the
	# family once.
	my %themed_params_of;
	my %param_of_look_of;
	my %forwarded_of;

	sub _themed_params_of ($class) {
		return $themed_params_of{$class} //= do {
			my %params = $class->themed_params;
			my $family = $class->theme_family;
			my %checked;
			foreach my $name ( sort keys %params ) {
				my $mapping = $params{$name};
				die "$class: themed parameter '$name' must map to [ slot, state ] or [ slot, state, kind ], got " . describe($mapping)
					unless ref $mapping eq 'ARRAY' && ( @$mapping == 2 || @$mapping == 3 );
				my ( $slot, $state, $kind ) = @$mapping;
				die "$class: themed parameter '$name' maps to no slot, so it needs a kind" unless defined $slot || defined $kind;
				die "$class: themed parameter '$name' maps to $slot" . ( $state eq 'normal' ? '' : ".$state" ) . ", which the family $family does not have"
					unless !defined $slot || Term::Fabulous::Theme::has_slot( $family, $slot, $state );
				$checked{$name} = { slot => $slot, state => $state, _kind_of( $class, $name, $kind ) };
			}
			\%checked;
		};
	}

	# What a parameter's kind says: one of %KIND, or a code reference that
	# checks like the functions of Term::Fabulous::Check (undef included).
	# No kind: the class keeps and checks the value itself.
	sub _kind_of ( $class, $name, $kind ) {
		return () unless defined $kind;
		return ( check => $kind, takes_undef => 1, property => 'scalar' ) if ref $kind eq 'CODE';
		my $known = $KIND{$kind} // die "$class: themed parameter '$name' has an unknown kind " . describe($kind) . " (known: " . join( ', ', sort keys %KIND ) . ", or a code reference)";
		return %$known;
	}

	sub _param_of_look_of ($class) {
		return $param_of_look_of{$class} //= do {
			my $params       = _themed_params_of($class);
			my %name_of_look = map { join( '.', @{ $params->{$_} }{qw(slot state)} ) => $_ } grep { defined $params->{$_}{slot} } keys %$params;
			\%name_of_look;
		};
	}

	# name => { method, param } for the looks the class keeps on its parts:
	# the method that returns the parts, and the parameter as the part's
	# class declares it.
	sub _forwarded_of ($class) {
		return $forwarded_of{$class} //= do {
			my %parts = $class->can('forwarded_looks') ? $class->forwarded_looks : ();
			my $own   = _themed_params_of($class);
			my %forwarded;
			foreach my $method ( sort keys %parts ) {
				my ( $part_class, @names ) = @{ $parts{$method} };
				foreach my $name (@names) {
					my $param = _themed_params_of($part_class)->{$name};
					die "$class: forwarded look '$name' is not a themed parameter of $part_class with a kind" unless defined $param && defined $param->{check};
					die "$class: forwarded look '$name' is a themed parameter of $class as well" if $own->{$name};
					die "$class: forwarded look '$name' goes to two kinds of parts" if $forwarded{$name};
					$forwarded{$name} = { method => $method, param => $param };
				}
			}
			\%forwarded;
		};
	}

	# The parts that keep a forwarded look, or the empty list.
	method _parts_of ($name) {
		my $forward = _forwarded_of( ref $self )->{$name} // return ();
		my $method  = $forward->{method};
		return $self->$method;
	}

	# The layout properties of the themed parameters of a kind and of the
	# forwarded looks (a class method), for Term::Fabulous::Role::CanParseLayout.
	method themed_layout_properties :common () {
		my $params    = _themed_params_of($class);
		my $forwarded = _forwarded_of($class);
		return (
			( map { $_ => $params->{$_}{property} } grep { defined $params->{$_}{property} } keys %$params ),
			( map { $_ => $forwarded->{$_}{param}{property} } keys %$forwarded ),
		);
	}

	# The constructor records the given themed parameters of a kind,
	# checked; a parameter left out stays with the theme. It runs before
	# the class's own fields and ADJUST blocks, so it calls no accessor
	# and no looks_changed: the class reads its looks when it builds its
	# parts. A forwarded look is the business of the class that builds
	# the part.
	ADJUSTPARAMS($params) {
		my $themed = _themed_params_of( ref $self );
		_forwarded_of( ref $self );    # checks the declaration on first use
		foreach my $name ( sort grep { exists $params->{$_} && defined $themed->{$_}{check} } keys %$themed ) {
			$_override{$name} = $self->_checked_look( $name, $themed->{$name}, delete $params->{$name} );
		}
	}

	# A value checked by its parameter's kind; undef for a kind that does
	# not take it names the way back to the theme.
	method _checked_look ( $name, $param, $value ) {
		return $value unless defined $param->{check};
		die ref($self) . ": $name must be $param->{noun}, got undef (reset_look('$name') returns it to the theme)"
			unless defined $value || $param->{takes_undef};
		return $param->{check}->( $self, $name, $value );
	}

	# The looks of the widget, fetched again after a theme change.
	method _look_table () {
		my $generation = Term::Fabulous::Theme::generation();
		return $_look_table if $_look_generation == $generation;

		$_look_table      = $self->_theme->look_table( ref($self)->theme_family, $self->classes );
		$_look_generation = $generation;
		return $_look_table;
	}

	# The theme the UI the widget is in gives it, or the default one
	# outside a UI.
	method _theme () {
		my $ui = $self->ui;
		return $ui->theme_for($self) if defined $ui && $ui->can('theme_for');
		return defined $ui && $ui->can('theme') ? $ui->theme : Term::Fabulous::Theme->default;
	}

	# Tells the widget which looks may have changed, when it has the hook.
	method _looks_changed (@names) {
		$self->looks_changed(@names) if @names && $self->can('looks_changed');
		return;
	}

	# Every look the widget has: its themed parameters and the forwarded
	# ones.
	method _all_look_names () {
		my @names = sort( keys %{ _themed_params_of( ref $self ) }, keys %{ _forwarded_of( ref $self ) } );
		return @names;
	}

	# Forgets the fetched looks of the widget and of everything below it,
	# for when the theme of its UI or the widget's classes change; in a UI,
	# every look may have changed.
	method forget_looks () {
		forget_tree_looks($self);
		return;
	}

	# Forgets the fetched looks of the widget alone: the tree_changed hook
	# of Term::Fabulous::Widget and ::Text calls it on every widget of a
	# subtree that joined or left a tree.
	method _forget_own_looks () {
		$_look_generation = -1;
		$self->_looks_changed( $self->_all_look_names ) if $self->_in_themed_ui;
		return;
	}

	# True in a UI that gives the widget its looks: a Clay::UI without
	# themes (the default theme), or a Term::Fabulous whose theme is a
	# theme. Clay::UI announces a new UI to its widgets from its own
	# constructor, before Term::Fabulous has turned its theme argument into
	# a theme; Term::Fabulous tells them itself once it has.
	method _in_themed_ui () {
		my $ui = $self->ui // return 0;
		return 1 unless $ui->can('theme');
		my $theme = $ui->theme;
		return blessed $theme && $theme->isa('Term::Fabulous::Theme') ? 1 : 0;
	}

	# A node and every themed widget below it forget their looks; the walk
	# goes on below nodes that are not themed (the rows of a grid).
	sub forget_tree_looks ($node) {
		my @below = $node->can('descendants') ? $node->descendants : ();
		$_->_forget_own_looks foreach grep { $_->DOES(__PACKAGE__) } $node, @below;
		return;
	}

	# The theme's value of a slot in a state: a state the theme gives no
	# value of its own looks like the normal state.
	method look ( $slot, $state = 'normal' ) {
		my $table = $_look_generation == Term::Fabulous::Theme::generation() ? $_look_table : $self->_look_table;
		return exists $table->{"$slot.$state"} ? $table->{"$slot.$state"} : $table->{"$slot.normal"};
	}

	method family_look ( $family, $slot, $state = 'normal' ) {
		return $self->_theme->look( $family, $slot, $state );
	}

	# The value a slot has in a state, given what it has in the normal
	# state (an explicit value or the theme's): the explicit value of the
	# state's parameter, else the theme's own value for the state, else
	# the normal value.
	method themed_value ( $slot, $state, $normal_value ) {
		return $normal_value if $state eq 'normal';
		my $name = _param_of_look_of( ref $self )->{"$slot.$state"};
		return $_override{$name} if defined $name && exists $_override{$name};
		my $table = $_look_generation == Term::Fabulous::Theme::generation() ? $_look_table : $self->_look_table;
		return exists $table->{"$slot.$state"} ? $table->{"$slot.$state"} : $normal_value;
	}

	method _unknown_look ( $what, $name ) {
		die ref($self) . ": $what does not know " . describe($name) . " (known: " . join( ', ', $self->_all_look_names ) . ")";
	}

	# What a themed parameter is worth: its explicit value, or the theme's.
	method look_value ($name) {
		my ($part) = $self->_parts_of($name);
		return $part->look_value($name) if defined $part;
		return $_override{$name} if exists $_override{$name};
		my $param = _themed_params_of( ref $self )->{$name} // $self->_unknown_look( look_value => $name );
		return undef unless defined $param->{slot};
		return $self->look( @{$param}{qw(slot state)} );
	}

	method has_look_override ($name) {
		my ($part) = $self->_parts_of($name);
		return $part->has_look_override($name) if defined $part;
		return exists $_override{$name} ? 1 : 0;
	}

	# Records an explicit value, checked by the parameter's kind (a
	# parameter without one the caller has checked); a forwarded look is
	# checked here, in the owner's name, and goes to every part that keeps
	# it.
	method set_look ( $name, $value ) {
		my $forward = _forwarded_of( ref $self )->{$name};
		if ( defined $forward ) {
			$value = $self->_checked_look( $name, $forward->{param}, $value );
			$_->set_look( $name => $value ) foreach $self->_parts_of($name);
		}
		else {
			my $param = _themed_params_of( ref $self )->{$name} // $self->_unknown_look( set_look => $name );
			$value = $self->_checked_look( $name, $param, $value );
			$_override{$name} = $value;
		}
		$self->mark_changed;
		$self->_looks_changed($name);
		return $value;
	}

	method reset_look (@names) {
		my $params    = _themed_params_of( ref $self );
		my $forwarded = _forwarded_of( ref $self );
		foreach my $name (@names) {
			$self->_unknown_look( reset_look => $name ) unless defined $name && !ref $name && ( exists $params->{$name} || exists $forwarded->{$name} );
		}
		foreach my $name (@names) {
			if ( $forwarded->{$name} ) {
				$_->reset_look($name) foreach $self->_parts_of($name);
				next;
			}
			delete $_override{$name};
			$self->look_reset($name);
		}
		$self->mark_changed;
		$self->_looks_changed(@names);
		return $self;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Role::Themed - How a widget reads its colors and
borders from the theme

=head1 SYNOPSIS

	use Object::Pad 0.825;

	class My::Gauge :isa(Term::Fabulous::Widget::Display) :strict(params) {
		method theme_family :common () { return 'progress' }

		# fill_color: the theme's progress.color unless given; a color
		method themed_params :common () {
			return ( $class->SUPER::themed_params, fill_color => [ 'color', 'normal', 'cell_color' ] );
		}

		method fill_color (@new) {
			return @new ? $self->set_look( fill_color => $new[0] ) : $self->look_value('fill_color');
		}

		method paint () {
			my $fill = $self->color_attr( $self->fill_color );
			...
		}
	}

	my $gauge = My::Gauge->new( fill_color => '#ff8800' );    # explicit, wins over the theme
	$gauge->reset_look('fill_color');                          # back to the theme

=head1 DESCRIPTION

Every Term::Fabulous widget composes this role (through
L<Term::Fabulous::Widget> or L<Term::Fabulous::Widget::Text>). It
holds the widget's I<explicit> looks, the colors, border styles and
borders the program set, and reads everything else from the
L<Term::Fabulous::Theme> of the UI the widget is in, for the widget's
I<family> and I<classes>: the theme the UI's
L<theme_for|Term::Fabulous::Render/theme_for> returns for the widget,
which is the UI's L<theme|Term::Fabulous::Render/theme> unless a
subclass of the UI says otherwise. A widget in no UI reads the default
theme.

The looks are fetched once and kept until the theme changes
(L<Term::Fabulous::Theme/generation, bump_generation>) or the widget
joins or leaves a tree, so reading a look while a frame is drawn costs
one hash lookup.

A themed parameter is declared once, in L</themed_params>, with the
slot it reads and its I<kind>. The role takes a parameter of a kind
from the constructor, checks every value given to L</set_look> by the
kind and makes it a layout property, so the widget writes only a
one-line accessor. A widget that copies looks into parts it builds
learns about every change in one hook, L</looks_changed>; a widget
whose looks live on its parts declares them in L</forwarded_looks>.

This page is for widget authors; L<Term::Fabulous::Manual::Looks/THEMES>
explains themes to users, and
L<Term::Fabulous::Manual::CustomWidgets> shows the role in a widget.

=head1 CLASS METHODS A WIDGET DEFINES

=head2 theme_family

	method theme_family :common () { return 'input' }

The family whose slots the widget draws with, one of
L<Term::Fabulous::Theme/Families, slots and states>. A subclass
inherits its parent's family unless it defines its own.

=head2 themed_params

	method themed_params :common () {
		return (
			$class->SUPER::themed_params,
			accent_color           => [ 'accent',     'normal',  'cell_color' ],
			focus_background_color => [ 'background', 'focused', 'cell_color' ],
		);
	}

The parameters whose value the theme supplies when the program gives
none: C<< name => [ slot, state, kind ] >>. The slot and state must
exist in the family; the first use of the class checks that, and the
kind, and dies otherwise. A subclass returns its parent's list plus
its own.

A parameter with a kind may map to the slot C<undef>: the family has
no slot for it, so only an explicit value counts and L</look_value>
answers C<undef> without one. L<Term::Fabulous::Widget> declares
C<bordered> this way for the families that have no C<border.enabled>:

	my $slot = Term::Fabulous::Theme::has_slot( $class->theme_family, 'border.enabled' ) ? 'border.enabled' : undef;
	...
	bordered => [ $slot, 'normal', 'border_sides' ],

The kind says what a value is:

=over

=item C<color>, C<cell_color>

A color (L<Term::Fabulous::Check/color>; C<cell_color> also takes a
packed C<0xRRGGBB>), stored as C<[r, g, b, a]>. C<undef> dies with a
message that names L</reset_look>, the way back to the theme. In a
layout it is a C<'color'> property.

=item C<optional_color>, C<optional_cell_color>

The same, or C<undef> for none (a look the widget then leaves out,
such as a focus border). In a layout it is a C<'scalar'> property, so
C<#null> gives C<undef>.

=item C<border_style>, C<grid_border_style>

A L<Term::Fabulous::Enum::BorderStyle> item or its name
(L<Term::Fabulous::Check/border_style>); C<grid_border_style> only a
style with joints. C<undef> dies as for a color. A C<'scalar'> layout
property.

=item C<border_sides>

The sides of a border (L<Term::Fabulous::Check/border_sides>): one
boolean for all four sides or a hash reference of booleans under the
side names, stored as a hash of all four sides, 1 or 0. It maps to a
boolean slot, whose 1 or 0 stands for all four sides, or to no slot
(see above). C<undef> dies as
for a color. A C<'border_sides'> layout property.

=item a code reference

A check of your own, called like the functions of
L<Term::Fabulous::Check> as C<< $check->( $widget, $name, $value ) >>,
C<undef> included; it returns the value to keep or dies. A C<'scalar'>
layout property.

=back

The role takes a parameter of a kind out of the constructor's
arguments and records it, checked, as an explicit value; a parameter
the program left out stays with the theme. It does that before the
class's own fields and C<ADJUST> blocks run, so it calls neither the
accessor nor L</looks_changed>: build your parts in C<ADJUST> from
L</look_value>. Do not declare such a parameter as a field: "not
given" and "given as C<undef>" (for a look C<undef> switches off) stay
apart this way. A layout entry of the same name in
L<Term::Fabulous::Role::CanParseLayout/layout_properties> replaces the
one the kind gives.

Without a kind (C<< [ slot, state ] >>) the class keeps and checks the
value itself and the role leaves the constructor and the layout to
it: L<Term::Fabulous::Widget> keeps C<background_color> and
C<border_color> in the Clay::UI roles, L<Term::Fabulous::Widget::Text>
its C<text_color>. Its accessor checks the value before
L</set_look>, and L</look_reset> clears it.

=head2 forwarded_looks

	method forwarded_looks :common () {
		return ( bar => [ 'Term::Fabulous::Widget::Tabs::Bar', qw(line_color text_color) ] );
	}

Optional. The looks the widget keeps on parts it builds:
C<< method => [ part class, names ] >>, where the method returns the
parts (one or more) and every name is a themed parameter with a kind
of the part class. L<Term::Fabulous::Widget::Tabs> keeps its colors on
its bar, L<Term::Fabulous::Widget::ScrollBox> its scrollbar colors on
both scrollbars. The role routes L</set_look> (checked by the part's
kind, in the widget's name, then given to every part),
L</look_value> and L</has_look_override> (asking the first part) and
L</reset_look> (on every part) through the method, and makes the names
layout properties of the part's kinds. The widget passes the
constructor's values to the parts it builds, or calls L</set_look>
once they exist. The first use of the class dies for a name the part
class has no kind for, a name that is also a themed parameter of the
widget, or a name given twice.

=head1 METHODS A WIDGET DEFINES

=head2 look_state

	method look_state () { return $self->is_focused ? 'focused' : 'normal' }

The state the widget shows now: C<normal>, or a state its family's
slots have. L<Term::Fabulous::Widget> answers C<normal>; a widget with
states overrides it and decides the precedence (a disabled button is
disabled, not focused).

=head2 look_reset

	method look_reset ($name) { ... }

Called by L</reset_look> for every parameter name, after the role
dropped its explicit value. A class that keeps the explicit value of a
parameter outside the role (L<Term::Fabulous::Widget> keeps
C<background_color> and C<border_color> in the Clay::UI roles) clears
it here; the others do nothing.

=head2 classes

The widget's class names as an array reference; see
L<Term::Fabulous::Widget/classes>.

=head2 looks_changed

	method looks_changed (@names) {
		$_close_button->text_color( $self->text_color );
		return;
	}

Optional. Called with the names of the looks that may have changed:
after L</set_look> (the name), after L</reset_look> (the names given),
and with every look of the widget (its themed parameters and its
forwarded looks) while the widget is in a UI: when the UI is created,
when its theme is set to another one, when L</forget_looks> runs (the
widget's classes changed) and when the widget joins a tree that is in
a UI (its C<tree_changed> hook, see
L<Term::Fabulous::Widget/tree_changed>). Not called during construction
(see L</themed_params>), nor for a widget outside a UI, which reads its
looks when it is drawn.

Most widgets need none, because they read their looks when a frame is
drawn. A widget that copies looks into the parts it builds
(L<Term::Fabulous::Widget::Table> colors its cells, its pager and its
scrollbar) colors them again here.

=head1 CLASS METHODS

=head2 themed_layout_properties

	my %kind_of = My::Gauge->themed_layout_properties;    # ( fill_color => 'color' )

The layout properties the themed parameters of a kind and the
forwarded looks give the class (see L</themed_params>);
L<Term::Fabulous::Role::CanParseLayout> adds them to the class's own
L<layout_properties|Term::Fabulous::Role::CanParseLayout/layout_properties>.

=head1 METHODS

=head2 look

	my $color = $self->look('accent');
	my $color = $self->look( 'border.color', 'focused' );

The theme's value of a slot of the widget's family in a state
(C<normal> by default), for the widget's classes: C<[r, g, b, a]>, a
L<Term::Fabulous::Enum::BorderStyle> item, C<'reverse'> or C<undef>
for none, 1 or 0 for a boolean slot (C<border.enabled>). A state the
theme gives no value of its own looks like the normal state.

=head2 family_look

	my $track = $self->family_look( scrollbar => 'track' );

Like L</look>, for a slot of another family, without the widget's
classes: for a part the widget paints itself in the looks of that
family, such as the scrollbar of a L<Term::Fabulous::Widget::TextArea>.
Read it while painting; a theme switch repaints a
L<Term::Fabulous::Widget::Display> by itself.

=head2 look_value

	my $color = $self->look_value('accent_color');

What a themed parameter is worth: the explicit value when the program
set one, else the theme's value of the slot and state the parameter
maps to, or C<undef> for a parameter that maps to no slot. A forwarded
look is the first part's. Dies for a name that is
neither in L</themed_params> nor in L</forwarded_looks>.

=head2 themed_value

	my $background = $self->themed_value( 'background', $state, $explicit // $self->look('background') );

The value of a slot in a state, given the value of the normal state:
the explicit value of the parameter mapped to that state (such as
C<focus_background_color>), else the theme's own value for the state,
else the normal value. This is how an explicit normal color stays in
states the theme does not color differently.

=head2 set_look

	$self->set_look( accent_color => '#61afef' );

Records an explicit value: checked by the parameter's kind (a
parameter without a kind takes the value as given, checked by the
caller), or, for a forwarded look, checked by the part's kind and
given to every part. Marks the widget changed, calls
L</looks_changed> with the name and returns the value as recorded
(C<[r, g, b, a]> for a color). Dies for an unknown name.

=head2 has_look_override

	if ( $self->has_look_override('accent_color') ) { ... }

Whether the program set the parameter explicitly (for a forwarded
look: on the first part).

=head2 reset_look

	$widget->reset_look('accent_color');
	$widget->reset_look( 'border_color', 'background_color' );

Drops the explicit values of the named parameters, so the theme
supplies them again (a forwarded look on every part), marks the widget
changed and calls L</looks_changed> with the names. Returns the
widget. Dies for a name that is neither in L</themed_params> nor in
L</forwarded_looks>, before anything changes.

=head2 forget_looks

	$widget->forget_looks;

Drops the fetched looks of the widget and of every widget below it;
the next read fetches them from the theme of the UI the widget is in
now. When the widget is in a UI, calls L</looks_changed> with all its
looks. Term::Fabulous calls it when a widget changes its classes. A
widget that joins or leaves a tree forgets its own looks from its
C<tree_changed> hook instead, which Clay::UI calls on every widget of
the moved subtree (see L<Term::Fabulous::Widget/tree_changed>).

=head1 FUNCTIONS

=head2 forget_tree_looks

	Term::Fabulous::Role::Themed::forget_tree_looks( $ui->root );

L</forget_looks> for a node and every themed widget below it, in
layout pre-order (L<Clay::UI::Role::Core::Element/descendants>), also
below nodes that are not themed (the rows of a grid). The UI calls it
when it is created and when its theme changes.

=head1 SEE ALSO

L<Term::Fabulous::Theme>, L<Term::Fabulous::Widget>,
L<Term::Fabulous::Manual::CustomWidgets>.

=cut
