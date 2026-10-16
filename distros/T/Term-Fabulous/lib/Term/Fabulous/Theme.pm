package Term::Fabulous::Theme;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

class Term::Fabulous::Theme :strict(params) {
	use Feature::Compat::Try;
	use Scalar::Util qw(blessed);
	use Text::KDL::XS qw(parse_kdl);
	use Term::Fabulous::Check qw(border_style color describe);
	use Term::Fabulous::Enum::BorderStyle;

	# ---------------------------------------------------------------------
	# The vocabulary: palette tokens, families with their slots and states.
	# ---------------------------------------------------------------------

	my @STATES   = qw(hovered focused pressed disabled selected active invalid);
	my %IS_STATE = map { $_ => 1 } 'normal', @STATES;

	# Every token, with its value in the built-in dark and light themes.
	# The dark values are the colors the widgets were drawn in before
	# themes existed.
	my %PALETTE = (
		background       => { dark => [ 22,  22,  34,  255 ], light => [ 250, 250, 247, 255 ] },
		surface          => { dark => [ 28,  33,  45,  255 ], light => [ 240, 241, 245, 255 ] },
		surface_raised   => { dark => [ 36,  40,  50,  255 ], light => [ 228, 231, 238, 255 ] },
		surface_field    => { dark => [ 36,  40,  48,  255 ], light => [ 255, 255, 255, 255 ] },
		surface_low      => { dark => [ 30,  33,  40,  255 ], light => [ 236, 238, 242, 255 ] },
		group_background => { dark => [ 28,  32,  41,  255 ], light => [ 232, 235, 241, 255 ] },
		border           => { dark => [ 70,  85,  110, 255 ], light => [ 160, 170, 190, 255 ] },
		line             => { dark => [ 88,  96,  112, 255 ], light => [ 190, 196, 208, 255 ] },
		outline          => { dark => [ 90,  96,  110, 255 ], light => [ 175, 182, 196, 255 ] },
		text             => { dark => [ 220, 223, 228, 255 ], light => [ 30,  34,  42,  255 ] },
		text_bright      => { dark => [ 235, 238, 243, 255 ], light => [ 10,  12,  16,  255 ] },
		text_muted       => { dark => [ 140, 146, 158, 255 ], light => [ 110, 118, 132, 255 ] },
		text_dim         => { dark => [ 150, 160, 180, 255 ], light => [ 100, 108, 124, 255 ] },
		text_inverse     => { dark => [ 16,  18,  22,  255 ], light => [ 250, 250, 250, 255 ] },
		placeholder      => { dark => [ 120, 126, 138, 255 ], light => [ 140, 146, 158, 255 ] },
		disabled         => { dark => [ 108, 112, 120, 255 ], light => [ 160, 164, 172, 255 ] },
		accent           => { dark => [ 97,  175, 239, 255 ], light => [ 30,  110, 200, 255 ] },
		focus_background => { dark => [ 52,  58,  72,  255 ], light => [ 220, 228, 244, 255 ] },
		hover_background => { dark => [ 40,  45,  58,  255 ], light => [ 230, 234, 242, 255 ] },
		hover_low        => { dark => [ 38,  42,  52,  255 ], light => [ 234, 237, 243, 255 ] },
		control_hover    => { dark => [ 60,  66,  80,  255 ], light => [ 214, 220, 232, 255 ] },
		selected         => { dark => [ 38,  62,  92,  255 ], light => [ 200, 216, 240, 255 ] },
		selection        => { dark => [ 38,  79,  120, 255 ], light => [ 190, 210, 240, 255 ] },
		track            => { dark => [ 58,  63,  75,  255 ], light => [ 215, 219, 228, 255 ] },
		track_scroll     => { dark => [ 70,  76,  90,  255 ], light => [ 205, 209, 218, 255 ] },
		button_face      => { dark => [ 44,  49,  60,  255 ], light => [ 222, 226, 234, 255 ] },
		backdrop         => { dark => [ 0,   0,   0,   128 ], light => [ 0,   0,   0,   96 ] },
		success          => { dark => [ 152, 195, 121, 255 ], light => [ 60,  140, 50,  255 ] },
		warning          => { dark => [ 229, 192, 123, 255 ], light => [ 190, 130, 20,  255 ] },
		danger           => { dark => [ 224, 108, 117, 255 ], light => [ 200, 50,  60,  255 ] },
	);

	# A slot: its kind (color, style or boolean), its default for the
	# normal state and for every state it has. A state default of 'normal'
	# means the state looks like the normal state unless a theme says
	# otherwise. Flags added to a slot: reverse (it may be 'reverse'),
	# required (it cannot be 'none', its widget draws with the value) and
	# grid (a style with joints). A boolean slot has no states, because
	# its widget would change size when its state changes, and is always
	# required.
	sub _color_slot ( $default, %by_state ) {
		return { kind => 'color', default => { normal => $default, %by_state } };
	}

	sub _style_slot ($default) {
		return { kind => 'style', default => { normal => $default } };
	}

	sub _boolean_slot ($default) {
		return { kind => 'boolean', required => 1, default => { normal => $default } };
	}

	# The values a boolean slot takes, and the spec each one is stored as.
	my %BOOLEAN_SPEC = ( true => 'true', 1 => 'true', false => 'false', 0 => 'false' );

	sub _required ( $slot, %flags ) {
		return { %$slot, required => 1, %flags };
	}

	my %FAMILY = (
		text => {
			slots => {
				'color'           => _color_slot('text'),
				'link'            => _color_slot( 'accent', hovered => 'text_bright',      selected => 'text_inverse' ),
				'link.background' => _color_slot( 'none',   hovered => 'hover_background', selected => 'accent' ),
			}
		},
		box => {
			slots => {
				'background'   => _color_slot('none'),
				'border.color' => _color_slot('border'),
				'border.style' => _style_slot('Round'),
			}
		},
		button => {
			extends => 'box',
			slots   => {
				'background'     => { %{ _color_slot( 'none', hovered => 'normal', focused => 'normal', pressed => 'reverse', disabled => 'normal' ) }, reverse => 1 },
				'border.color'   => _color_slot( 'border', hovered => 'normal', focused => 'accent', pressed => 'normal', disabled => 'disabled' ),
				'border.enabled' => _boolean_slot('false'),
				'text'           => _color_slot( 'text', hovered => 'normal', focused => 'normal', pressed => 'normal', disabled => 'disabled' ),
			}
		},
		input => {
			extends => 'box',
			slots   => {
				'background'       => _color_slot( 'none',   focused => 'focus_background', disabled => 'normal' ),
				'border.color'     => _color_slot( 'border', focused => 'normal', disabled => 'normal', invalid => 'danger' ),
				'border.enabled'   => _boolean_slot('false'),
				'text'             => _color_slot( 'text', disabled => 'disabled', invalid => 'danger' ),
				'accent'           => _color_slot('accent'),
				'star'             => _required( _color_slot('warning') ),
				'placeholder'      => _color_slot('placeholder'),
				'selection'        => _color_slot('selection'),
				'track'            => _color_slot('outline'),
				'inactive'         => _required( _color_slot('outline') ),
				'half'             => _color_slot('none'),
				'separator'        => _color_slot('outline'),
				'selected_text'    => _color_slot('text_inverse'),
				'hover_background' => _color_slot('control_hover'),
			}
		},
		text_input => {
			extends => 'input',
			slots   => { 'background' => _color_slot( 'surface_field', focused => 'focus_background', disabled => 'normal' ) },
		},
		dropdown => {
			extends => 'input',
			slots   => {
				'background'           => _color_slot( 'surface_field', focused => 'focus_background', disabled => 'normal' ),
				'list.background'      => _color_slot('surface_low'),
				'list.border.color'    => _color_slot('accent'),
				'list.border.style'    => _style_slot('Round'),
				'highlight.text'       => _color_slot('text_inverse'),
				'highlight.background' => _color_slot('accent'),
			}
		},
		menu => {
			extends => 'input',
			slots   => {
				'background'           => _color_slot( 'surface_low', focused => 'normal', disabled => 'normal' ),
				'border.color'         => _color_slot( 'accent', focused => 'normal', disabled => 'normal', invalid => 'normal' ),
				'border.style'         => _style_slot('Round'),
				'border.enabled'       => _boolean_slot('true'),
				'keys'                 => _color_slot('placeholder'),
				'separator'            => _color_slot('placeholder'),
				'highlight.text'       => _color_slot('text_inverse'),
				'highlight.background' => _color_slot('accent'),
			}
		},
		menu_bar => {
			extends => 'input',
			slots   => {
				'background'           => _color_slot( 'surface_low', focused => 'normal', disabled => 'normal' ),
				'caption'              => _color_slot('placeholder'),
				'highlight.text'       => _color_slot('text_inverse'),
				'highlight.background' => _color_slot('accent'),
			}
		},
		table => {
			extends => 'box',
			slots   => {
				'text'              => _required( _color_slot('text') ),
				'header.text'       => _required( _color_slot('text_bright') ),
				'header.background' => _color_slot('surface_raised'),
				'group.text'        => _color_slot('accent'),
				'group.background'  => _color_slot('group_background'),
				'cursor'            => _required( _color_slot('focus_background') ),
				'selected'          => _color_slot('selected'),
				'hover'             => _color_slot('hover_low'),
				'filter.background' => _color_slot('surface_low'),
				'error'             => _color_slot('danger'),
				'muted'             => _required( _color_slot('text_muted') ),
				'line.color'        => _required( _color_slot('line') ),
				'stripe'            => _color_slot('none'),
				'pager.button'      => _required( _color_slot('button_face') ),
			}
		},
		scrollbar => { extends => 'box', slots => { track => _required( _color_slot('track_scroll') ), thumb => _required( _color_slot('accent') ) } },
		tabs      => {
			extends => 'box',
			slots   => {
				'line.color'       => _color_slot('outline'),
				'line.style'       => _required( _style_slot('Round'), grid => 1 ),
				'text'             => _color_slot( 'text_dim', active => 'text', disabled => 'disabled' ),
				'hover_background' => _color_slot('hover_background'),
				'focus_border'     => _color_slot('accent'),
			}
		},
		document_tabs => {
			extends => 'box',
			slots   => {
				'background' => _color_slot( 'surface_low', active => 'focus_background' ),
				'text'       => _color_slot( 'text_dim',    active => 'text' ),
				'modified'   => _color_slot('accent'),
				'error'      => _color_slot('danger'),
				'button'     => _color_slot('accent'),
			}
		},
		accordion => {
			extends => 'box',
			slots   => {
				'title'             => _required( _color_slot('text') ),
				'accent'            => _required( _color_slot('accent') ),
				'header.background' => _color_slot( 'none', focused => 'focus_background', hovered => 'hover_background' ),
				'disabled'          => _required( _color_slot('disabled') ),
				'border.color'      => _color_slot('disabled'),
				'border.style'      => _style_slot('Round'),
				'border.enabled'    => _boolean_slot('false'),
			}
		},
		dialog => {
			extends => 'box',
			slots   => {
				'background'     => _color_slot('surface'),
				'border.color'   => _color_slot('accent'),
				'border.style'   => _style_slot('Round'),
				'border.enabled' => _boolean_slot('true'),
				'backdrop'       => _color_slot('backdrop'),
			}
		},
		toast => {
			extends => 'box',
			slots   => {
				'background'     => _color_slot('surface'),
				'border.style'   => _style_slot('Round'),
				'border.enabled' => _boolean_slot('true'),
				'text'           => _required( _color_slot('text') ),
				'important_text' => _required( _color_slot('text_inverse') ),
				'info'           => _required( _color_slot('accent') ),
				'success'        => _required( _color_slot('success') ),
				'warning'        => _required( _color_slot('warning') ),
				'danger'         => _required( _color_slot('danger') ),
			}
		},
		status_bar => {
			extends => 'box',
			slots   => {
				'background' => _color_slot('surface_low'),
				'text'       => _color_slot('text'),
				'dim'        => _color_slot('placeholder'),
				'accent'     => _color_slot('accent'),
				'success'    => _color_slot('success'),
				'warning'    => _color_slot('warning'),
				'danger'     => _color_slot('danger'),
			}
		},
		progress => {
			extends => 'box',
			slots   => {
				'color'          => _color_slot('accent'),
				'track'          => _color_slot('track'),
				'text'           => _color_slot('text'),
				'inside_text'    => _color_slot('text_inverse'),
				'border.enabled' => _boolean_slot('false'),
			}
		},
		spinner => { extends => 'box', slots => { color  => _color_slot('accent'),   label => _color_slot('text'), 'border.enabled' => _boolean_slot('false') } },
		image   => { extends => 'box', slots => { notice => _color_slot('text_dim'), 'border.enabled' => _boolean_slot('false') } },
		divider => {
			extends => 'box',
			slots   => {
				'line.color' => _color_slot('outline'),
				'line.style' => _style_slot('Solid'),
				'text'       => _color_slot('text_dim'),
			}
		},
	);

	# The slots of a family, its ancestors' included; the family's own
	# definitions win.
	my %slots_of_family;

	sub _slots_of ($family) {
		return $slots_of_family{$family} //= do {
			my $definition = $FAMILY{$family};
			my $parent     = $definition->{extends};
			+{ ( defined $parent ? %{ _slots_of($parent) } : () ), %{ $definition->{slots} } };
		};
	}

	sub families () {
		my @names = sort keys %FAMILY;
		return @names;
	}

	sub tokens () {
		my @names = sort keys %PALETTE;
		return @names;
	}

	sub states () {
		return ( 'normal', @STATES );
	}

	sub is_family ($name) {
		return defined $name && !ref $name && exists $FAMILY{$name} ? 1 : 0;
	}

	# The slot names of a family, each with the states it has.
	sub slots ($family) {
		die "Term::Fabulous::Theme: unknown family " . describe($family) . " (known: " . join( ', ', families() ) . ")" unless is_family($family);
		my $slots = _slots_of($family);
		my %states_of;
		foreach my $slot ( keys %$slots ) {
			$states_of{$slot} = [ grep { $_ ne 'normal' } sort keys %{ $slots->{$slot}{default} } ];
		}
		return %states_of;
	}

	sub has_slot ( $family, $slot, $state = 'normal' ) {
		return 0 unless is_family($family) && defined $slot && defined $state && !ref $slot && !ref $state;
		my $definition = _slots_of($family)->{$slot} // return 0;
		return exists $definition->{default}{$state} ? 1 : 0;
	}

	# What the vocabulary says about a slot: its kind, the values it takes
	# besides colors or styles, its states and its defaults.
	sub slot_info ( $family, $slot ) {
		die "Term::Fabulous::Theme: unknown family " . describe($family) . " (known: " . join( ', ', families() ) . ")" unless is_family($family);
		my $slots      = _slots_of($family);
		my $definition = defined $slot && !ref $slot ? $slots->{$slot} : undef;
		die "Term::Fabulous::Theme: the family $family has no slot " . describe($slot) . " (known: " . join( ', ', sort keys %$slots ) . ")" unless defined $definition;
		return {
			kind     => $definition->{kind},
			required => $definition->{required} ? 1 : 0,
			reverse  => $definition->{reverse}  ? 1 : 0,
			grid     => $definition->{grid}     ? 1 : 0,
			states   => [ grep { $_ ne 'normal' } sort keys %{ $definition->{default} } ],
			default  => { %{ $definition->{default} } },
		};
	}

	# A value a theme may give a slot in a state, as the theme would store
	# it; dies with the reason when the slot cannot take it.
	sub check_value ( $family, $slot, $state, $value ) {
		die "Term::Fabulous::Theme: the family " . describe($family) . " has no slot " . describe($slot) . " with the state " . describe($state) unless has_slot( $family, $slot, $state );
		return _checked_spec( $family, $slot, $state, $value );
	}

	# ---------------------------------------------------------------------
	# The generation: a process-wide counter that every UI bumps when its
	# theme is set, so that widgets know when to look their looks up again.
	# ---------------------------------------------------------------------

	my $generation = 0;

	sub generation () {
		return $generation;
	}

	sub bump_generation () {
		return ++$generation;
	}

	# ---------------------------------------------------------------------
	# Construction
	# ---------------------------------------------------------------------

	my %builtin;

	field $name :param :reader = undef;
	field $extends :param = 'dark';

	# What the theme sets itself: tokens as [r, g, b, a], and the raw specs
	# (a token name, a color, a style, 'none', 'reverse') of its slot and
	# variant overrides, under "family" and "family.variant".
	field %_palette;
	field %_own_slot;
	field %_own_variant;

	# The result of the compile step: every slot and state of every family
	# and variant, as values the widgets draw with.
	field %_table;
	field %_variant_table;
	field %_look_table_cache;

	# The constructor parameters, read once in ADJUST and then dropped.
	field $palette  :param           = {};
	field $slots    :param           = {};
	field $variants :param           = {};
	field $_builtin :param(_builtin) = undef;

	ADJUST {
		die "Term::Fabulous::Theme: name must be a string, got " . describe($name) if defined $name && ref $name;
		$extends = defined $_builtin ? undef : _theme_of( extends => $extends );
		$name //= $_builtin;

		my %own_palette = _checked_palette( $palette, $_builtin );
		%_palette = ( ( defined $extends ? %{ $extends->_palette_copy } : () ), %own_palette );

		%_own_slot    = _checked_slots($slots);
		%_own_variant = _checked_variants($variants);
		$self->_compile;
		( $palette, $slots, $variants ) = ( undef, undef, undef );
	}

	sub _theme_of ( $what, $value ) {
		return $value if blessed $value && $value->isa(__PACKAGE__);
		die "Term::Fabulous::Theme: $what must be a Term::Fabulous::Theme or the name of a built-in theme, got " . describe($value)
			unless defined $value && !ref $value;
		my $theme = __PACKAGE__->builtin($value);
		die "Term::Fabulous::Theme: $what names an unknown built-in theme '$value' (known: " . join( ', ', builtin_names() ) . ")" unless defined $theme;
		return $theme;
	}

	# The palette a theme sets: every token for a built-in theme, any
	# subset otherwise.
	sub _checked_palette ( $palette, $builtin_name ) {
		die "Term::Fabulous::Theme: palette must be a hash reference of token names and colors, got " . describe($palette) unless ref $palette eq 'HASH';
		my @unknown = grep { !exists $PALETTE{$_} } sort keys %$palette;
		die "Term::Fabulous::Theme: palette does not know the token" . ( @unknown > 1 ? 's' : '' ) . " @unknown (known: " . join( ', ', tokens() ) . ")" if @unknown;
		return map { $_ => $PALETTE{$_}{$builtin_name} } tokens() if defined $builtin_name;
		return map { $_ => color( __PACKAGE__, "palette token $_", $palette->{$_} ) } sort keys %$palette;
	}

	# Slot overrides as { family => { "slot.state" => raw spec } }. A key is
	# "family.slot" or "family.slot.state".
	sub _checked_slots ($slots) {
		die "Term::Fabulous::Theme: slots must be a hash reference, got " . describe($slots) unless ref $slots eq 'HASH';
		my %by_family;
		foreach my $key ( sort keys %$slots ) {
			my ( $family, $slot, $state ) = _split_slot_key($key);
			$by_family{$family}{"$slot.$state"} = _checked_spec( $family, $slot, $state, $slots->{$key} );
		}
		return %by_family;
	}

	# Variant overrides as { "family.variant" => { "slot.state" => raw spec } }.
	sub _checked_variants ($variants) {
		die "Term::Fabulous::Theme: variants must be a hash reference, got " . describe($variants) unless ref $variants eq 'HASH';
		my %by_variant;
		foreach my $key ( sort keys %$variants ) {
			my ( $family, $variant ) = $key =~ /\A([a-z_]+)\.([A-Za-z0-9_-]+)\z/
				or die "Term::Fabulous::Theme: a variant key must be 'family.variant', got " . describe($key);
			die "Term::Fabulous::Theme: variant '$key' names an unknown family '$family' (known: " . join( ', ', families() ) . ")" unless is_family($family);
			my $overrides = $variants->{$key};
			die "Term::Fabulous::Theme: variant '$key' must be a hash reference of slots, got " . describe($overrides) unless ref $overrides eq 'HASH';
			foreach my $slot_key ( sort keys %$overrides ) {
				my ( $slot, $state ) = _split_slot_name( $family, $slot_key, "variant '$key'" );
				$by_variant{$key}{"$slot.$state"} = _checked_spec( $family, $slot, $state, $overrides->{$slot_key} );
			}
		}
		return %by_variant;
	}

	sub _split_slot_key ($key) {
		my ( $family, $rest ) = ( $key // '' ) =~ /\A([a-z_]+)\.(.+)\z/
			or die "Term::Fabulous::Theme: a slot key must be 'family.slot' or 'family.slot.state', got " . describe($key);
		die "Term::Fabulous::Theme: slot '$key' names an unknown family '$family' (known: " . join( ', ', families() ) . ")" unless is_family($family);
		return ( $family, _split_slot_name( $family, $rest, "slot '$key'" ) );
	}

	# ( slot, state ) of "slot" or "slot.state" within a family.
	sub _split_slot_name ( $family, $name, $what ) {
		my $slots = _slots_of($family);
		return ( $name, 'normal' ) if exists $slots->{$name};
		if ( my ( $slot, $state ) = $name =~ /\A(.+)\.([a-z]+)\z/ ) {
			if ( exists $slots->{$slot} ) {
				my @states = grep { $_ ne 'normal' } sort keys %{ $slots->{$slot}{default} };
				die "Term::Fabulous::Theme: $what: the slot $family.$slot has no state '$state' (" . ( @states ? 'its states: ' . join( ', ', @states ) : 'it has the normal state only' ) . ")"
					unless exists $slots->{$slot}{default}{$state};
				return ( $slot, $state );
			}
		}
		die "Term::Fabulous::Theme: $what: the family $family has no slot '$name' (known: " . join( ', ', sort keys %$slots ) . ")";
	}

	# A raw spec a theme may give: undef or 'none' (no color or style)
	# unless the slot is required, a token name, 'reverse' where the slot
	# allows it, a style name or item for a style slot (one with joints for
	# a grid slot), true, false, 1 or 0 for a boolean slot, any color for
	# a color slot. Returned normalized; a boolean as 'true' or 'false'.
	sub _checked_spec ( $family, $slot, $state, $value ) {
		my $definition = _slots_of($family)->{$slot};
		my $what       = "$family.$slot" . ( $state eq 'normal' ? '' : ".$state" );
		if ( !defined $value || ( !ref $value && $value eq 'none' ) ) {
			die "Term::Fabulous::Theme: $what cannot be 'none'" if $definition->{required};
			return 'none';
		}
		if ( !ref $value && $value eq 'reverse' ) {
			die "Term::Fabulous::Theme: $what cannot be 'reverse' (only button.background can)" unless $definition->{reverse};
			return 'reverse';
		}
		if ( $definition->{kind} eq 'style' ) {
			my %allowed = ( ( $definition->{required} ? () : ( none => 'none' ) ), ( $definition->{grid} ? ( grid => 1 ) : () ) );
			return border_style( __PACKAGE__, $what, $value, %allowed );
		}
		if ( $definition->{kind} eq 'boolean' ) {
			die "Term::Fabulous::Theme: $what must be true, false, 1 or 0, got " . describe($value) unless !ref $value && exists $BOOLEAN_SPEC{$value};
			return $BOOLEAN_SPEC{$value};
		}
		return $value if !ref $value && exists $PALETTE{$value};
		return color( __PACKAGE__, $what, $value );
	}

	# ---------------------------------------------------------------------
	# The compile step
	# ---------------------------------------------------------------------

	method _palette_copy () {
		return { map { $_ => [ @{ $_palette{$_} } ] } keys %_palette };
	}

	# The raw spec of a slot and state: this theme's own, the parent's, or
	# the vocabulary's default.
	method _raw ( $family, $key ) {
		return $_own_slot{$family}{$key} if exists $_own_slot{$family}{$key};
		return $extends->_raw( $family, $key ) if defined $extends;
		my ( $slot, $state ) = $key =~ /\A(.+)\.([a-z]+)\z/;
		return _slots_of($family)->{$slot}{default}{$state};
	}

	# The raw spec a variant sets for a slot and state, in this theme or
	# an ancestor; undef when none does.
	method _raw_variant ( $variant_key, $key ) {
		return $_own_variant{$variant_key}{$key} if exists $_own_variant{$variant_key}{$key};
		return $extends->_raw_variant( $variant_key, $key ) if defined $extends;
		return undef;
	}

	method _variant_keys () {
		my %seen = ( ( defined $extends ? map { $_ => 1 } $extends->_variant_keys : () ), map { $_ => 1 } keys %_own_variant );
		my @keys = sort keys %seen;
		return @keys;
	}

	method _compile () {
		foreach my $family ( families() ) {
			my $slots = _slots_of($family);
			my %raw;
			foreach my $slot ( keys %$slots ) {
				$raw{"$slot.$_"} = $self->_raw( $family, "$slot.$_" ) foreach keys %{ $slots->{$slot}{default} };
			}
			$_table{$family} = $self->_resolved_table( $family, \%raw );
		}

		foreach my $variant_key ( $self->_variant_keys ) {
			my ($family) = split /\./, $variant_key;
			my $slots    = _slots_of($family);
			my %raw;
			foreach my $slot ( keys %$slots ) {
				foreach my $state ( keys %{ $slots->{$slot}{default} } ) {
					my $own = $self->_raw_variant( $variant_key, "$slot.$state" ) // next;
					$raw{"$slot.$state"} = $own;
				}
			}
			$_variant_table{$variant_key} = $self->_resolved_table( $family, \%raw );
		}
		return;
	}

	# The values of a raw table. A state whose spec is 'normal' gets no
	# entry: readers fall back to the slot's normal value, which lets an
	# explicit normal color of a widget show in such a state too.
	method _resolved_table ( $family, $raw ) {
		my %table;
		foreach my $key ( keys %$raw ) {
			my $spec = $raw->{$key};
			next if !ref $spec && $spec eq 'normal';
			$table{$key} = $self->_resolved_value( $family, $key, $spec );
		}
		return \%table;
	}

	method _resolved_value ( $family, $key, $spec ) {
		return $spec if ref $spec;    # a color as [r, g, b, a] or a BorderStyle item, checked when it was given
		return undef if $spec eq 'none';
		return 'reverse' if $spec eq 'reverse';
		return $_palette{$spec} if exists $PALETTE{$spec};
		my ($slot) = $key =~ /\A(.+)\.[a-z]+\z/;
		my $kind = _slots_of($family)->{$slot}{kind};
		return Term::Fabulous::Enum::BorderStyle->from_name($spec) if $kind eq 'style';
		return $spec eq 'true' ? 1 : 0 if $kind eq 'boolean';
		die "Term::Fabulous::Theme: internal: no value for $family.$key from '$spec'";
	}

	# ---------------------------------------------------------------------
	# Reading
	# ---------------------------------------------------------------------

	method extends () {
		return $extends;
	}

	method palette () {
		return $self->_palette_copy;
	}

	method token ($token) {
		die "Term::Fabulous::Theme: unknown token " . describe($token) . " (known: " . join( ', ', tokens() ) . ")" unless defined $token && !ref $token && exists $_palette{$token};
		return [ @{ $_palette{$token} } ];
	}

	method has_variant ( $family, $variant ) {
		return exists $_variant_table{"$family.$variant"} ? 1 : 0;
	}

	# The looks of a family for a widget with the given classes: the
	# family's table, overlaid with the variant of every class that has
	# one, in class order. The result is shared and must not be changed.
	method look_table ( $family, $classes = [] ) {
		die "Term::Fabulous::Theme: unknown family " . describe($family) . " (known: " . join( ', ', families() ) . ")" unless is_family($family);
		die "Term::Fabulous::Theme: classes must be an array reference, got " . describe($classes) unless ref $classes eq 'ARRAY';
		my @variants = grep { exists $_variant_table{$_} } map { "$family.$_" } @$classes;
		return $_table{$family} unless @variants;

		my $cache_key = join "\x{1F}", @variants;
		return $_look_table_cache{$cache_key} //= { %{ $_table{$family} }, map { %{ $_variant_table{$_} } } @variants };
	}

	method look ( $family, $slot, $state = 'normal', $classes = [] ) {
		die "Term::Fabulous::Theme: the family " . ( $family // 'undef' ) . " has no slot " . describe($slot) . " with the state " . describe($state) unless has_slot( $family, $slot, $state );
		my $table = $self->look_table( $family, $classes );
		return exists $table->{"$slot.$state"} ? $table->{"$slot.$state"} : $table->{"$slot.normal"};
	}

	# ---------------------------------------------------------------------
	# Built-in themes
	# ---------------------------------------------------------------------

	sub builtin_names () {
		return qw(dark light);
	}

	method builtin :common ($theme_name) {
		return undef unless defined $theme_name && !ref $theme_name && grep { $_ eq $theme_name } builtin_names();
		return $builtin{$theme_name} //= $class->new( _builtin => $theme_name );
	}

	method default :common () {
		return $class->builtin('dark');
	}

	# ---------------------------------------------------------------------
	# Theme files
	# ---------------------------------------------------------------------

	method from_file :common ($path) {
		die "Term::Fabulous::Theme: from_file needs a file name, got " . describe($path) unless defined $path && !ref $path && length $path;
		return _from_source( _open_file($path), "theme file '$path'" );
	}

	# Text::KDL::XS reads a filehandle as UTF-8 bytes, a string as characters.
	sub _open_file ($path) {
		open my $handle, '<:raw', $path or die "Term::Fabulous::Theme: cannot open '$path': $!";
		return $handle;
	}

	method from_string :common ($kdl) {
		die "Term::Fabulous::Theme: from_string needs a string, got " . describe($kdl) unless defined $kdl && !ref $kdl;
		return _from_source( $kdl, 'theme' );
	}

	sub _from_source ( $source, $where ) {
		my $document;
		try {
			$document = parse_kdl($source);
		}
		catch ($error) {
			die "Term::Fabulous::Theme: $where: failed to parse KDL: $error";
		}
		my $theme;
		try {
			$theme = __PACKAGE__->new( _parse_document($document) );
		}
		catch ($error) {
			chomp $error;
			$error =~ s/\ATerm::Fabulous::Theme: //;
			$error =~ s/ at \S+ line \d+\.?\z//;
			die "Term::Fabulous::Theme: $where: $error\n";
		}
		return $theme;
	}

	# The constructor parameters a theme document describes.
	sub _parse_document ($document) {
		my ( %params, %slots, %variants, $saw_theme, $saw_palette );
		foreach my $node ( $document->nodes->@* ) {
			my $node_name = $node->name;
			if ( $node_name eq 'theme' ) {
				die "the 'theme' node may appear only once" if $saw_theme++;
				%params = ( %params, _parse_theme_node($node) );
				next;
			}
			if ( $node_name eq 'palette' ) {
				die "the 'palette' node may appear only once" if $saw_palette++;
				$params{palette} = _parse_palette_node($node);
				next;
			}
			die "unknown top-level node '$node_name' (known: theme, palette and the families " . join( ', ', families() ) . ")" unless is_family($node_name);
			die "$node_name: a family node takes no arguments or properties" if $node->args->@* || $node->props->@*;
			_parse_block( $node->children, $node_name, 'normal', \%slots, \%variants );
		}
		return ( %params, slots => \%slots, variants => \%variants );
	}

	sub _parse_theme_node ($node) {
		my @args = $node->args->@*;
		die "the 'theme' node takes at most one argument, the theme's name" if @args > 1;
		die "the theme's name must be a string" if @args && !$args[0]->is_string;
		die "the 'theme' node has no children" if $node->children->@*;
		my %params = ( @args ? ( name => $args[0]->value ) : () );
		foreach my $prop ( $node->props->@* ) {
			my ( $key, $value ) = @$prop;
			die "the 'theme' node knows only the property 'extends', got '$key'" unless $key eq 'extends';
			die "extends must be the name of a built-in theme" unless $value->is_string;
			$params{extends} = $value->value;
		}
		return %params;
	}

	sub _parse_palette_node ($node) {
		die "the 'palette' node takes no arguments or properties" if $node->args->@* || $node->props->@*;
		my %palette;
		foreach my $kid ( $node->children->@* ) {
			my $token = $kid->name;
			die "palette: unknown token '$token' (known: " . join( ', ', tokens() ) . ")" unless exists $PALETTE{$token};
			die "palette: the token '$token' is set twice" if exists $palette{$token};
			$palette{$token} = _single_string( $kid, "palette token '$token'" );
		}
		return \%palette;
	}

	# The nodes of a family block, or of a state or variant block in it:
	# state blocks, variant blocks and slot nodes. A slot set twice in one
	# document is a mistake (usually a copy), not an override.
	sub _parse_block ( $nodes, $family, $state, $slots, $variants, $variant = undef ) {
		foreach my $kid (@$nodes) {
			my $kid_name = $kid->name;
			if ( $kid_name eq 'variant' ) {
				die "$family: a variant cannot be inside a state or another variant" if $state ne 'normal' || defined $variant;
				my $variant_name = _single_string( $kid, "$family: a variant" );
				die "$family: a variant name must be a word" unless $variant_name =~ /\A[A-Za-z0-9_-]+\z/;
				_parse_block( $kid->children, $family, 'normal', $slots, $variants, $variant_name );
				next;
			}
			if ( $IS_STATE{$kid_name} && $kid_name ne 'normal' ) {
				die "$family: a state cannot be inside another state" if $state ne 'normal';
				die "$family: a state node takes no arguments or properties" if $kid->args->@* || $kid->props->@*;
				_parse_block( $kid->children, $family, $kid_name, $slots, $variants, $variant );
				next;
			}
			foreach my $pair ( _slot_values( $kid, $family ) ) {
				my ( $slot, $value ) = @$pair;
				my $key    = $state eq 'normal' ? $slot                                      : "$slot.$state";
				my $target = defined $variant   ? ( $variants->{"$family.$variant"} //= {} ) : $slots;
				my $name   = defined $variant   ? $key                                       : "$family.$key";
				die "$family: " . ( defined $variant ? "variant '$variant': " : '' ) . "the slot '$key' is set twice" if exists $target->{$name};
				$target->{$name} = $value;
			}
		}
		return;
	}

	# [ slot, value ] pairs of a slot node: `name "value"` sets the slot
	# name, `name key="value"` sets name.key for every property.
	sub _slot_values ( $kid, $family ) {
		my $kid_name = $kid->name;
		my @args     = $kid->args->@*;
		my @props    = $kid->props->@*;
		die "$family: the node '$kid_name' has no children" if $kid->children->@*;
		die "$family: the node '$kid_name' needs either one value or key=value properties" if ( @args && @props ) || ( !@args && !@props ) || @args > 1;
		return ( [ $kid_name, _kdl_spec( $args[0], $family, $kid_name ) ] ) if @args;
		return map { [ "$kid_name.$_->[0]", _kdl_spec( $_->[1], $family, "$kid_name.$_->[0]" ) ] } @props;
	}

	# The raw spec of a KDL value: #null for none, #true or #false for a
	# boolean slot, a string for any other slot. Checked like any spec
	# when the theme is built.
	sub _kdl_spec ( $value, $family, $slot ) {
		return undef if $value->is_null;
		my $definition = _slots_of($family)->{$slot};
		if ( defined $definition && $definition->{kind} eq 'boolean' ) {
			die "$family.$slot must be #true or #false" unless $value->is_bool;
			return $value->as_perl ? 'true' : 'false';
		}
		die "$family.$slot must be a string or #null" unless $value->is_string;
		return $value->value;
	}

	sub _single_string ( $kid, $what ) {
		my @args = $kid->args->@*;
		die "$what needs exactly one string argument" unless @args == 1 && $args[0]->is_string && !$kid->props->@*;
		return $args[0]->value;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Theme - Colors and borders for every widget, with
variants per class

=head1 SYNOPSIS

	use Term::Fabulous;
	use Term::Fabulous::Theme;

	# A built-in theme, or one derived from it in Perl ...
	my $theme = Term::Fabulous::Theme->new(
		name    => 'ocean',
		extends => 'dark',
		palette => { accent => '#88c0d0', surface => '#2e3440' },
		slots   => {
			'button.border.style'         => 'Round',
			'button.border.color.focused' => 'accent',
			'text_input.border.enabled'   => 1,
		},
		variants => {
			'button.primary' => { 'border.color' => 'accent', 'text' => 'text_bright' },
		},
	);

	# ... or from a theme file
	my $theme = Term::Fabulous::Theme->from_file('themes/ocean.kdl');

	my $ui = Term::Fabulous->new( root => $root, theme => $theme );
	$ui->theme('light');    # switch at run time

	# What a widget of a family draws with
	my $border = $theme->look( 'button', 'border.color', 'focused', ['primary'] );

=head1 DESCRIPTION

A theme decides the colors and the borders of every widget that does
not set them itself: whether a text field has a border, the border
color of a focused button, the background of a text field, the color
of the lines of a table, the color of text. It is made of a
I<palette> of named colors (tokens) and of I<slots>, one for every
part of every widget family that a theme colors, styles or switches
on, in every state the part can be in. Most slots default to tokens,
so most themes set a few tokens and nothing else. A theme may also
define I<variants>: a widget whose C<classes> name a variant draws
with it.

Themes are set per UI (L<Term::Fabulous/theme>,
L<Term::Fabulous::Static/theme>) and can be switched at any time. A
widget that was given a color or style explicitly keeps it, whatever
the theme says, and so does a widget that was given C<bordered>;
L<Term::Fabulous::Widget/reset_look> returns it to the theme. See
L<Term::Fabulous::Manual::Looks/THEMES> for the guide.

=head1 VOCABULARY

=head2 Tokens

The palette has these tokens. The built-in C<dark> theme gives them the
colors the widgets have always been drawn in; C<light> gives them
colors for a light screen.

	background surface surface_raised surface_field surface_low group_background
	border line outline
	text text_bright text_muted text_dim text_inverse placeholder disabled
	accent focus_background hover_background hover_low control_hover selected selection
	track track_scroll button_face backdrop
	success warning danger

C<border> is the color every border is drawn in unless a theme or the
widget says otherwise, so a frame stays visible on the theme's own
screen. Which widgets have a border at all is a slot of its own (see
L</Borders>). C<background> is the screen behind the widgets: L<Term::Fabulous>
paints the whole screen in it before every frame, so a theme looks the
same whatever colors the terminal shows otherwise, and a light theme is
readable on a dark terminal. A theme that wants the terminal's own
background instead gives the token a color with alpha 0, such as
C<rgba(0, 0, 0, 0)>. L<Term::Fabulous::Static> does not paint it.

=head2 Families, slots and states

A family is the kind of a widget: C<text>, C<box>, C<button>,
C<input>, C<text_input>, C<dropdown>, C<menu>, C<menu_bar>, C<table>,
C<scrollbar>, C<tabs>, C<document_tabs>, C<accordion>, C<dialog>,
C<toast>, C<status_bar>, C<progress>, C<spinner>, C<image>, C<divider>.
A widget class says which family it belongs to
(L<Term::Fabulous::Role::Themed/theme_family>), and a family may
extend another: C<button> extends C<box>, so it has the box's slots
too.

A slot is one part a theme decides: C<background>, C<border.color>,
C<border.style>, C<border.enabled>, C<text>, C<accent>,
C<line.color>, ... Slots whose name ends in C<style> take a border
style name, C<border.enabled> takes true or false (see L</Borders>),
and all others take a color. A slot has a value for the C<normal>
state and, where the widget shows states, for some of C<hovered>,
C<focused>, C<pressed>, C<disabled>, C<selected>, C<active> and
C<invalid>; style slots and C<border.enabled> have the C<normal> state
only. A state that a theme does not set looks like the normal state.
L</slots> lists the slots of a family with their states.

A theme sets a slot for one family. A family that extends it has the
same slot, but keeps its own value: C<box.border.color> does not change
C<button.border.color>, and C<input.border.enabled> does not change
C<text_input.border.enabled> or C<dropdown.border.enabled>.

The slots of the status bar are named after the colors they give, not
after the kinds of message: a message of the kind C<info> is drawn in
C<status_bar.text>, the others in C<status_bar.success>,
C<status_bar.warning> and C<status_bar.danger> (see
L<Term::Fabulous::Widget::StatusBar>). A toast of the kind C<info>, by
contrast, is drawn in C<toast.info>, an accent color.

=head2 Borders

Three slots decide the border of a widget:

=over

=item C<border.enabled>

Whether a widget of the family has a border on all four sides when
the program does not decide it with the widget's C<bordered> parameter
(see L<Term::Fabulous::Widget/bordered>). The families C<button>,
C<input>, C<text_input>, C<dropdown>, C<menu>, C<menu_bar>,
C<accordion>, C<dialog>, C<toast>, C<progress>, C<spinner> and
C<image> have it. It is C<false> in the built-in themes, except for
C<menu>, C<dialog> and C<toast>, where it is C<true>.

A border takes one cell on each side, inside the widget's box, so this
slot has the C<normal> state only: a border that came and went with
the focus would resize the widget and move its neighbors.

=item C<border.style>

The border style the border is drawn in: C<Round> in the built-in
themes. A widget may give each side a style of its own; a side whose
style is C<Hidden> has no border, whatever C<border.enabled> says.

=item C<border.color>

The color of the border's characters, by state.

=back

Every family but C<text> has C<border.style> and C<border.color>. The
families not listed under C<border.enabled> above have no
C<border.enabled>, and a widget of one of them has a border only where
the program gives it one:

=over

=item * C<box>, the family of plain boxes, scroll boxes, canvases,
charts and every widget that names no family of its own. Widgets build
their parts out of boxes, so a theme that framed every box would frame
those parts too.

=item * C<table>: a table draws its frame and its lines itself, with
its own parameters (see
L<Term::Fabulous::Manual::TableStyles/Lines between and around the cells>),
and takes no C<bordered> at all.

=item * C<tabs>: the line of a tab bar joins the borders of its tabs,
which the bar draws itself.

=item * C<scrollbar>, C<divider>, C<status_bar> and C<document_tabs>:
lines one cell thick, which a frame does not fit around.

=item * C<text>, which has no border slots.

=back

A widget that frames one of its parts decides that part's border
itself: the tabs of a tab bar, the list of an open dropdown, the items
of an accordion with C<item_borders>.

=head2 Values

Where a theme sets a slot, it gives one of:

=over

=item * a token name, such as C<accent>: the palette's color;

=item * a color, in any format L<Term::Fabulous::Color> accepts (a color slot);

=item * a border style name, such as C<Round> (a style slot; see L<Term::Fabulous::Enum::BorderStyle>);

=item * C<true> or C<false>, or C<1> or C<0>, for C<border.enabled> (in a theme file C<#true> or C<#false>);

=item * C<none>: no color or no style, as if the widget had been given none (not for a required slot, see below);

=item * C<reverse>: for C<button.background> in the C<pressed> state only, the button is drawn in reverse video.

=back

Some slots are I<required>: their widgets draw with the value, or hand
it to a part that needs one, so C<none> (and C<undef> or C<#null>) dies
where the theme is built, with C<Term::Fabulous::Theme: SLOT cannot be
'none'>, in every state the slot has. The required slots are
C<scrollbar.track> and C<scrollbar.thumb>; C<tabs.line.style>;
C<input.star> and C<input.inactive> (in every family extending
C<input>); C<table.text>, C<table.header.text>, C<table.cursor>,
C<table.muted>, C<table.line.color> and C<table.pager.button>;
C<accordion.title>, C<accordion.accent> and C<accordion.disabled>;
C<toast.text>, C<toast.important_text>, C<toast.info>,
C<toast.success>, C<toast.warning> and C<toast.danger>, and
C<border.enabled> in every family that has it.
C<tabs.line.style> also needs a style with joints (see
L<Term::Fabulous::Enum::BorderStyle/get_grid_styles>), because the tab
bar's line joins the tab borders; another style dies.

=head1 THEME FILES

A theme file is a KDL document (L<https://kdl.dev>) with a C<theme>
node, a C<palette> node and one node per family, all optional:

=for highlighter language=kdl

	theme "ocean" extends="dark"

	palette {
		background "#242933"
		accent "#88c0d0"
		surface "#2e3440"
	}

	button {
		background "surface_raised"
		border style=Round color="border"
		text "text"
		focused { border color="accent" }
		pressed { background "reverse" }
		disabled { text "disabled" }
		variant "primary" {
			border color="accent"
			focused { border color="text_bright" }
		}
	}

	text_input {
		border enabled=#true style=Solid
		focused { background "focus_background" }
	}

Inside a family node, C<name "value"> sets the slot C<name> and C<name
key="value"> sets the slot C<name.key> for every property, so C<border
style=Round color="border"> sets C<border.style> and C<border.color>,
and C<border enabled=#true> sets C<border.enabled>. A node named after a
state holds the slots of that state. A C<variant "NAME"> node holds the
slots and states of a variant. C<#null> means C<none>. C<border.enabled>
takes C<#true> or C<#false> only; every other slot takes a string or
C<#null>. An unknown family, slot, state, token or style dies with the
known names, and so does C<none> or C<#null> for a required slot (see
L</Values>). A palette token, or a slot of a family, state or variant,
that is set twice in one document dies too (C<palette: the token
'accent' is set twice>, C<button: the slot 'text.focused' is set
twice>), also when the two settings are in two nodes of the same family.

=head1 CONSTRUCTORS

=head2 new

	my $theme = Term::Fabulous::Theme->new(%parameters);

=over

=item C<name>

A string, for your own use. Default: none.

=item C<extends>

The theme this one starts from: a Term::Fabulous::Theme or the name
of a built-in theme. Default: C<'dark'>. Everything the parent sets is
inherited, including its variants.

=item C<palette>

A hash reference of token names and colors. Unknown tokens die.

=item C<slots>

A hash reference whose keys are C<family.slot> or
C<family.slot.state> and whose values are as in L</Values>.

=item C<variants>

A hash reference whose keys are C<family.variant> and whose values are
hash references of C<slot> or C<slot.state> keys. A variant inherits
every slot of its family that it does not set.

=back

=head2 builtin

	my $dark = Term::Fabulous::Theme->builtin('dark');

The built-in theme of that name (C<dark> or C<light>), a shared
object; C<undef> for any other name. L</families, tokens, states, builtin_names>
lists the names.

=head2 default

	my $theme = Term::Fabulous::Theme->default;

The theme a UI uses when it is given none, and the one a widget that
is in no UI resolves its looks against: the built-in C<dark>.

=head2 from_file

	my $theme = Term::Fabulous::Theme->from_file('themes/ocean.kdl');

Reads a theme file (see L</THEME FILES>). Dies with the file name and
the node when the file cannot be read or describes something unknown.

=head2 from_string

	my $theme = Term::Fabulous::Theme->from_string($kdl);

The same for a theme given as a character string.

=head1 METHODS

=head2 name

The C<name> given to the constructor, the name of a built-in theme, or
C<undef>.

=head2 extends

The theme this one was derived from, or C<undef> for a built-in theme.

=head2 palette

A new hash reference with every token's color as C<[r, g, b, a]>.

=head2 token

	my $accent = $theme->token('accent');

One token's color as a new C<[r, g, b, a]>. Unknown tokens die.

=head2 look

	my $color = $theme->look( 'button', 'border.color', 'focused' );
	my $color = $theme->look( 'button', 'border.color', 'focused', ['primary'] );

The value of a slot in a state (C<normal> by default) for a widget of a
family with the given classes: C<[r, g, b, a]> for a color, a
L<Term::Fabulous::Enum::BorderStyle> item for a style, 1 or 0 for
C<border.enabled>, C<'reverse'>, or C<undef> for none. Dies for a slot
or state the family does not have.

=head2 look_table

	my $looks = $theme->look_table( 'button', ['primary'] );
	my $color = $looks->{'border.color.focused'};

The looks of a family for a widget with the given classes, under
C<slot.state> keys: the family's values with the variant of every
class that has one laid over them, in the order of the classes. Every
slot has a C<slot.normal> entry; a state has an entry only when the
theme gives it a value of its own, so a reader falls back to the
normal entry (as L</look> does). The hash is shared and cached; do not
change it. This is what widgets read while a frame is drawn.

=head2 has_variant

	if ( $theme->has_variant( 'button', 'primary' ) ) { ... }

Whether the theme (or one it extends) defines the variant.

=head1 FUNCTIONS

Plain functions, called as C<Term::Fabulous::Theme::NAME(...)>.

=head2 families, tokens, states, builtin_names

The names of the families, the tokens, the states (C<normal> first)
and the built-in themes.

=head2 slots

	my %states_of = Term::Fabulous::Theme::slots('button');

The slots of a family, each with the list of its states besides
C<normal>.

=head2 is_family, has_slot

	Term::Fabulous::Theme::is_family('button');                      # 1
	Term::Fabulous::Theme::has_slot( 'button', 'text', 'pressed' );    # 1

Whether a family exists, and whether it has a slot in a state.

=head2 slot_info

	my $info = Term::Fabulous::Theme::slot_info( 'button', 'background' );
	# {
	#     kind     => 'color',
	#     required => 0,
	#     reverse  => 1,
	#     grid     => 0,
	#     states   => [ 'disabled', 'focused', 'hovered', 'pressed' ],
	#     default  => { normal => 'none', pressed => 'reverse', hovered => 'normal', ... },
	# }

What the vocabulary says about one slot of a family, as a new hash
reference:

=over

=item C<kind>

C<color>, C<style> or C<boolean>: whether the slot takes a color, a
border style, or true or false (see L</Values>).

=item C<required>

1 when the slot cannot be C<none> (see L</Values>), else 0. Always 1
for a boolean slot.

=item C<reverse>

1 when the slot may be C<reverse> (C<button.background>), else 0.

=item C<grid>

1 when the slot needs a border style with joints (C<tabs.line.style>),
else 0.

=item C<states>

The states the slot has besides C<normal>, sorted by name.

=item C<default>

The value of every state, C<normal> included, before any theme sets
it: a token name, a style name, C<true> or C<false>, C<none>,
C<reverse>, or C<normal> for a state that looks like the normal
state. The built-in themes keep these
defaults and differ only in their palettes.

=back

Dies for an unknown family or slot, naming the known ones.

=head2 check_value

	my $value = Term::Fabulous::Theme::check_value( 'button', 'border.color', 'focused', 'accent' );
	my $style = Term::Fabulous::Theme::check_value( 'tabs', 'line.style', 'normal', 'Double' );
	my $on    = Term::Fabulous::Theme::check_value( 'input', 'border.enabled', 'normal', 1 );    # 'true'

Checks a value a theme would give a slot in a state, by the rules of
L</Values>, and returns it as the theme stores it: a token name, C<none>
or C<reverse> as a string, a color as C<[r, g, b, a]>, a style as a
L<Term::Fabulous::Enum::BorderStyle> item, a boolean as the string
C<true> or C<false>; C<undef> becomes C<none>.
Dies with the reason when the slot cannot take the value, for example
C<Term::Fabulous::Theme: tabs.line.style cannot be 'none'>, and for a
slot or state the family does not have. Theme editors use it to check a
value before they write it.

=head2 generation, bump_generation

	my $now = Term::Fabulous::Theme::generation();

A process-wide counter that a UI bumps when its theme is set, so that
every widget looks its looks up again in the next frame. Widget
authors read it through L<Term::Fabulous::Role::Themed>; only UI
classes call C<bump_generation>.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Looks/THEMES>, L<Term::Fabulous::Role::Themed>,
L<Term::Fabulous::Color>, L<Term::Fabulous::Enum::BorderStyle>,
L<Term::Fabulous::Widget/classes>.

=cut
