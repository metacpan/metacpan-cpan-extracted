package Term::Fabulous::Event::KeyPress;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::KeyPress :isa(Clay::UI::Events::Event) :strict(params) {
	use Term::Fabulous::Termbox qw(:keys TB_MOD_ALT TB_MOD_CTRL TB_MOD_SHIFT TF_MOD_SUPER TF_MOD_HYPER TF_MOD_META);

	field $key       :param :reader;
	field $char      :param :reader;
	field $modifiers :param :reader;

	# termbox2 reports the keys of the ASCII control range with their byte as
	# the key code.
	my %NAME_BY_KEY = (
		TB_KEY_BACKSPACE()   => 'Backspace',    # Ctrl+H, sent by some terminals for Backspace
		TB_KEY_TAB()         => 'Tab',
		TB_KEY_ENTER()       => 'Enter',
		TB_KEY_ESC()         => 'Escape',
		TB_KEY_SPACE()       => 'Space',
		TB_KEY_BACKSPACE2()  => 'Backspace',
		TB_KEY_ARROW_LEFT()  => 'Left',
		TB_KEY_ARROW_RIGHT() => 'Right',
		TB_KEY_ARROW_UP()    => 'Up',
		TB_KEY_ARROW_DOWN()  => 'Down',
		TB_KEY_HOME()        => 'Home',
		TB_KEY_END()         => 'End',
		TB_KEY_PGUP()        => 'PageUp',
		TB_KEY_PGDN()        => 'PageDown',
		TB_KEY_INSERT()      => 'Insert',
		TB_KEY_DELETE()      => 'Delete',
		TB_KEY_BACK_TAB()    => 'BackTab',
		TB_KEY_F1()          => 'F1',
		TB_KEY_F2()          => 'F2',
		TB_KEY_F3()          => 'F3',
		TB_KEY_F4()          => 'F4',
		TB_KEY_F5()          => 'F5',
		TB_KEY_F6()          => 'F6',
		TB_KEY_F7()          => 'F7',
		TB_KEY_F8()          => 'F8',
		TB_KEY_F9()          => 'F9',
		TB_KEY_F10()         => 'F10',
		TB_KEY_F11()         => 'F11',
		TB_KEY_F12()         => 'F12',

		# Keys only the kitty keyboard protocol reports.
		TF_KEY_CAPS_LOCK()            => 'CapsLock',
		TF_KEY_SCROLL_LOCK()          => 'ScrollLock',
		TF_KEY_NUM_LOCK()             => 'NumLock',
		TF_KEY_PRINT_SCREEN()         => 'PrintScreen',
		TF_KEY_PAUSE()                => 'Pause',
		TF_KEY_MENU()                 => 'Menu',
		TF_KEY_F13()                  => 'F13',
		TF_KEY_F14()                  => 'F14',
		TF_KEY_F15()                  => 'F15',
		TF_KEY_F16()                  => 'F16',
		TF_KEY_F17()                  => 'F17',
		TF_KEY_F18()                  => 'F18',
		TF_KEY_F19()                  => 'F19',
		TF_KEY_F20()                  => 'F20',
		TF_KEY_F21()                  => 'F21',
		TF_KEY_F22()                  => 'F22',
		TF_KEY_F23()                  => 'F23',
		TF_KEY_F24()                  => 'F24',
		TF_KEY_F25()                  => 'F25',
		TF_KEY_F26()                  => 'F26',
		TF_KEY_F27()                  => 'F27',
		TF_KEY_F28()                  => 'F28',
		TF_KEY_F29()                  => 'F29',
		TF_KEY_F30()                  => 'F30',
		TF_KEY_F31()                  => 'F31',
		TF_KEY_F32()                  => 'F32',
		TF_KEY_F33()                  => 'F33',
		TF_KEY_F34()                  => 'F34',
		TF_KEY_F35()                  => 'F35',
		TF_KEY_KP_0()                 => 'Keypad0',
		TF_KEY_KP_1()                 => 'Keypad1',
		TF_KEY_KP_2()                 => 'Keypad2',
		TF_KEY_KP_3()                 => 'Keypad3',
		TF_KEY_KP_4()                 => 'Keypad4',
		TF_KEY_KP_5()                 => 'Keypad5',
		TF_KEY_KP_6()                 => 'Keypad6',
		TF_KEY_KP_7()                 => 'Keypad7',
		TF_KEY_KP_8()                 => 'Keypad8',
		TF_KEY_KP_9()                 => 'Keypad9',
		TF_KEY_KP_DECIMAL()           => 'KeypadDecimal',
		TF_KEY_KP_DIVIDE()            => 'KeypadDivide',
		TF_KEY_KP_MULTIPLY()          => 'KeypadMultiply',
		TF_KEY_KP_SUBTRACT()          => 'KeypadSubtract',
		TF_KEY_KP_ADD()               => 'KeypadAdd',
		TF_KEY_KP_ENTER()             => 'KeypadEnter',
		TF_KEY_KP_EQUAL()             => 'KeypadEqual',
		TF_KEY_KP_SEPARATOR()         => 'KeypadSeparator',
		TF_KEY_KP_LEFT()              => 'KeypadLeft',
		TF_KEY_KP_RIGHT()             => 'KeypadRight',
		TF_KEY_KP_UP()                => 'KeypadUp',
		TF_KEY_KP_DOWN()              => 'KeypadDown',
		TF_KEY_KP_PAGE_UP()           => 'KeypadPageUp',
		TF_KEY_KP_PAGE_DOWN()         => 'KeypadPageDown',
		TF_KEY_KP_HOME()              => 'KeypadHome',
		TF_KEY_KP_END()               => 'KeypadEnd',
		TF_KEY_KP_INSERT()            => 'KeypadInsert',
		TF_KEY_KP_DELETE()            => 'KeypadDelete',
		TF_KEY_KP_BEGIN()             => 'KeypadBegin',
		TF_KEY_MEDIA_PLAY()           => 'MediaPlay',
		TF_KEY_MEDIA_PAUSE()          => 'MediaPause',
		TF_KEY_MEDIA_PLAY_PAUSE()     => 'MediaPlayPause',
		TF_KEY_MEDIA_REVERSE()        => 'MediaReverse',
		TF_KEY_MEDIA_STOP()           => 'MediaStop',
		TF_KEY_MEDIA_FAST_FORWARD()   => 'MediaFastForward',
		TF_KEY_MEDIA_REWIND()         => 'MediaRewind',
		TF_KEY_MEDIA_TRACK_NEXT()     => 'MediaTrackNext',
		TF_KEY_MEDIA_TRACK_PREVIOUS() => 'MediaTrackPrevious',
		TF_KEY_MEDIA_RECORD()         => 'MediaRecord',
		TF_KEY_LOWER_VOLUME()         => 'LowerVolume',
		TF_KEY_RAISE_VOLUME()         => 'RaiseVolume',
		TF_KEY_MUTE_VOLUME()          => 'MuteVolume',
	);

	# The keypad keys the kitty keyboard protocol tells apart, and the
	# main keyboard keys legacy terminals report for them instead.
	my %MAIN_NAME_BY_KEYPAD_NAME = (
		Keypad0         => '0',
		Keypad1         => '1',
		Keypad2         => '2',
		Keypad3         => '3',
		Keypad4         => '4',
		Keypad5         => '5',
		Keypad6         => '6',
		Keypad7         => '7',
		Keypad8         => '8',
		Keypad9         => '9',
		KeypadDecimal   => '.',
		KeypadDivide    => '/',
		KeypadMultiply  => '*',
		KeypadSubtract  => '-',
		KeypadAdd       => '+',
		KeypadEnter     => 'Enter',
		KeypadEqual     => '=',
		KeypadSeparator => ',',
		KeypadLeft      => 'Left',
		KeypadRight     => 'Right',
		KeypadUp        => 'Up',
		KeypadDown      => 'Down',
		KeypadPageUp    => 'PageUp',
		KeypadPageDown  => 'PageDown',
		KeypadHome      => 'Home',
		KeypadEnd       => 'End',
		KeypadInsert    => 'Insert',
		KeypadDelete    => 'Delete',
	);

	# The key codes by name; Backspace is the code terminals send for it.
	my %KEY_BY_NAME = ( reverse(%NAME_BY_KEY), Backspace => TB_KEY_BACKSPACE2 );

	# The modifiers in the order key_name writes them.
	my @MODIFIER_NAMES   = qw(Ctrl Alt Shift Super Hyper Meta);
	my %MODIFIER_BY_NAME = (
		Ctrl  => TB_MOD_CTRL,
		Alt   => TB_MOD_ALT,
		Shift => TB_MOD_SHIFT,
		Super => TF_MOD_SUPER,
		Hyper => TF_MOD_HYPER,
		Meta  => TF_MOD_META,
	);
	my $MODIFIER_PREFIX = join '|', @MODIFIER_NAMES;

	method event_name :common { 'KeyPress' }

	method of :common ($ev) {
		return $class->new(
			key       => $ev->key,
			char      => $ev->ch,
			modifiers => $ev->mod,
		);
	}

	sub _is_control_byte ($code) {
		return $code < 0x20 || $code == 0x7F;
	}

	method fields_for_name :common ($name) {
		my ( $prefix, $base ) = ( $name // '' ) =~ /\A((?:(?:$MODIFIER_PREFIX)\+)*)(.+)\z/s;
		my $modifiers = 0;
		$modifiers |= $MODIFIER_BY_NAME{$_} foreach split /\+/, $prefix // '';
		my %fields = defined $base ? _fields_of_base( $base, $modifiers ) : ();

		# The tables decide: a name is valid when the event reads back as it.
		my $event = %fields ? $class->new( key => $fields{key}, char => $fields{ch}, modifiers => $fields{mod} ) : undef;
		die "Term::Fabulous::Event::KeyPress: no key is named " . ( defined $name ? "'$name'" : 'undef' ) . "; use the names key_name returns, such as 'Ctrl+Shift+Left' or 'a'\n"
			unless defined $event && ( $event->key_name // '' ) eq $name;
		return %fields;
	}

	# What termbox2 reports for a key: a named key by its code, Ctrl plus a
	# letter or symbol by its control byte, any other character by itself.
	# termbox2 sets the Ctrl bit on every control byte, and the kitty
	# keyboard protocol puts a Ctrl combination the control range cannot
	# carry (Ctrl+I, Ctrl+Enter) into the character.
	sub _fields_of_base ( $base, $modifiers ) {
		my $ctrl = $modifiers & TB_MOD_CTRL;
		if ( $base eq 'Space' ) {
			return ( key => 0, ch => $ctrl ? 0 : 0x20, mod => $modifiers );
		}
		if ( exists $KEY_BY_NAME{$base} ) {
			my $code = $KEY_BY_NAME{$base};
			return ( key => 0,     ch => $code, mod => $modifiers ) if $ctrl && _is_control_byte($code);
			return ( key => $code, ch => 0,     mod => _is_control_byte($code) ? $modifiers | TB_MOD_CTRL : $modifiers );
		}
		return () unless length $base == 1;

		my $control_byte = ord($base) - 0x40;
		return ( key => $control_byte, ch => 0, mod => $modifiers )
			if $ctrl && $control_byte > 0 && $control_byte < 0x20 && !exists $NAME_BY_KEY{$control_byte};
		return ( key => 0, ch => ord( $ctrl ? lc $base : $base ), mod => $modifiers );
	}

	# The key without its modifiers, and whether it implies Ctrl: the
	# unnamed bytes of the control range are Ctrl plus a letter or symbol.
	method _base_key () {
		return ( 'Space',              0 ) if $char == 0x20;
		return ( undef,                0 ) if $char >= 0x80 && $char <= 0x9F;    # C1 control characters have no name
		return ( $self->_base_of_char, 0 ) if $char != 0;
		return ( $NAME_BY_KEY{$key},   0 ) if exists $NAME_BY_KEY{$key};
		return ( 'Space',              1 ) if $key == 0x00;
		return ( chr( $key + 0x40 ),   1 ) if $key < 0x20;
		return ( undef,                0 );
	}

	# The kitty keyboard protocol puts the key of a Ctrl combination the
	# legacy encoding cannot carry into the char: a named control key
	# (Ctrl+Enter), or a character, named in upper case like Ctrl+W.
	method _base_of_char () {
		return $NAME_BY_KEY{$char} if _is_control_byte($char);
		my $character = chr $char;
		return $character unless $modifiers & TB_MOD_CTRL;
		my $upper = uc $character;
		return length($upper) == 1 ? $upper : $character;    # 'ß' would become 'SS'
	}

	# termbox2 sets TB_MOD_CTRL on every byte of the control range, Enter
	# and Tab included; there the byte alone says whether Ctrl was held.
	method _with_modifiers ( $base, $implies_ctrl ) {
		my $ctrl  = $char == 0 && _is_control_byte($key) ? $implies_ctrl : $modifiers & TB_MOD_CTRL;
		my @names = grep { $_ eq 'Ctrl' ? $ctrl : $modifiers & $MODIFIER_BY_NAME{$_} } @MODIFIER_NAMES;
		return join '+', @names, $base;
	}

	method key_name () {
		my ( $base, $implies_ctrl ) = $self->_base_key;
		return undef unless defined $base;
		return $self->_with_modifiers( $base, $implies_ctrl );
	}

	method main_key_name () {
		my ( $base, $implies_ctrl ) = $self->_base_key;
		return undef unless defined $base;
		return $self->_with_modifiers( $MAIN_NAME_BY_KEYPAD_NAME{$base} // $base, $implies_ctrl );
	}

	method text () {
		return undef if $modifiers & ( TB_MOD_CTRL | TB_MOD_ALT | TF_MOD_SUPER | TF_MOD_HYPER | TF_MOD_META );
		return chr($char) if $char >= 0x20 && ( $char < 0x7F || $char > 0x9F );
		return ' ' if $char == 0 && $key == 0x20;
		return undef;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::KeyPress - A key press from the terminal

=head1 SYNOPSIS

	use Clay::UI::Enum::Result;

	# Ctrl+S saves, every other key goes on to the ancestors.
	$root->on( KeyPress => sub ($event) {
		my $name = $event->key_name // '';
		if ( $name eq 'Ctrl+S' ) {
			save_document();
			return;    # handled: stop here
		}
		return Clay::UI::Enum::Result->CONTINUE;
	} );

	# What did the user type?
	$widget->on( KeyPress => sub ($event) {
		my $character = $event->text;    # 'a', 'A', 'e' with an accent, ' ', or undef
		return Clay::UI::Enum::Result->CONTINUE unless defined $character;
		append_to_buffer($character);
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous> fires a C<KeyPress> event for every key the terminal
reports while L<Term::Fabulous/run> is active. The event is fired on the
focused widget, or on the root widget when no widget has the focus, and
then bubbles up to the ancestors (see
L<Term::Fabulous::Manual::Events/Return values and bubbling>). Listen for it with
C<< $widget->on( KeyPress => sub ($event) { ... } ) >>.

The class is a subclass of L<Clay::UI::Events::Event>, so C<target>,
C<current_target>, C<name> (C<'KeyPress'> unless given to the
constructor) and C<bubble_mode> (C<IF_CONTINUE>) are available as well.

The most useful methods are L</key_name>, which turns the key into a
readable name such as C<'Ctrl+Left'> for key bindings, L</main_key_name>,
which names the keypad keys after the main keyboard keys they stand
for, and L</text>, which returns the character a key types. The raw
termbox2 values are available through L</key>, L</char> and
L</modifiers>.

Terminals that speak the
L<kitty keyboard protocol|https://sw.kovidgoyal.net/kitty/keyboard-protocol/>
report more keys and modifiers than others; see
L</THE KITTY KEYBOARD PROTOCOL>.

=head1 CONSTRUCTOR

=head2 new

	use Term::Fabulous::Termbox qw(TB_KEY_ARROW_LEFT TB_MOD_CTRL TB_MOD_SHIFT);

	my $typed_a    = Term::Fabulous::Event::KeyPress->new( key => 0, char => ord 'a', modifiers => 0 );
	my $left       = Term::Fabulous::Event::KeyPress->new( key => TB_KEY_ARROW_LEFT, char => 0, modifiers => 0 );
	my $word_left  = Term::Fabulous::Event::KeyPress->new( key => TB_KEY_ARROW_LEFT, char => 0, modifiers => TB_MOD_CTRL | TB_MOD_SHIFT );
	my $ctrl_w     = Term::Fabulous::Event::KeyPress->new( key => 0x17, char => 0, modifiers => TB_MOD_CTRL );
	my $enter      = Term::Fabulous::Event::KeyPress->new( key => 0x0D, char => 0, modifiers => 0 );

	$text_field->fire_event($typed_a);

Programs rarely build key presses themselves; L<Term::Fabulous> does it
for every key. Building one by hand is useful in tests of one widget,
to simulate typing at it; a whole program is tested with the keys of
L<Term::Fabulous::Terminal::Memory/press_key>, which go through the
focus like real ones (see L<Term::Fabulous::Manual::Programs/TESTING>). The
three parameters below are required, and unknown parameters die. The
C<name> and C<bubble_mode> parameters of L<Clay::UI::Events::Event> are
accepted as well.

=over

=item C<key>

An integer. The termbox2 key code: a C<TB_KEY_*> constant for special
keys (arrows, Home, F1, ...), a C<TF_KEY_*> constant for the keys only
the kitty keyboard protocol reports (F13, the keypad, media keys, ...;
see L<Term::Fabulous::Termbox/Kitty keys>), the byte value for keys of
the ASCII control range (C<0x0D> for Enter, C<0x17> for Ctrl+W, ...),
and C<0> for a typed character.

=item C<char>

An integer. The Unicode code point of a typed character (C<ord 'a'>),
or C<0> for a special key. With the kitty keyboard protocol it also
holds the key of a Ctrl combination the legacy encoding cannot carry:
the control byte of Enter, Tab, Backspace or Escape for Ctrl+Enter and
so on, or the unshifted character for Ctrl+I, Ctrl+1 and the like (see
L<Term::Fabulous::Termbox/tf_install_input_parser>).

=item C<modifiers>

An integer. A bit mask of the termbox2 constants C<TB_MOD_ALT> (1),
C<TB_MOD_CTRL> (2) and C<TB_MOD_SHIFT> (4), and of C<TF_MOD_SUPER>
(16), C<TF_MOD_HYPER> (32) and C<TF_MOD_META> (64), which only the
kitty keyboard protocol reports; C<0> for none.

=back

An event object can be fired only once. Build a new one for every
C<fire_event> call.

=head2 of

	my $event = Term::Fabulous::Event::KeyPress->of($termbox_event);

Builds an event from a C<Term::Fabulous::Termbox::Event> as returned by termbox2's
C<tb_peek_event> or C<tb_poll_event>: C<key> from its C<key>, C<char>
from its C<ch> and C<modifiers> from its C<mod>. Called by
L<Term::Fabulous>; class method.

=head2 fields_for_name

	my %fields = Term::Fabulous::Event::KeyPress->fields_for_name('Ctrl+Shift+Left');
	my $termbox_event = Term::Fabulous::Termbox::Event->new( type => TB_EVENT_KEY, %fields );

The other way round from L</key_name>: the C<key>, C<ch> and C<mod>
fields of the termbox2 event a terminal reports for the key with that
name, the way termbox2 and its kitty keyboard protocol parser report
it. C<Ctrl+W> is the control byte 0x17 with the Ctrl bit, C<Enter> the
byte 0x0D (with the Ctrl bit termbox2 sets on every control byte),
C<Ctrl+I> the character C<i> with the Ctrl bit, C<a> the character.
The L<C<press_key>|Term::Fabulous::Terminal::Memory/press_key> method
of Term::Fabulous::Terminal::Memory uses it. Class method.

The name must be one that L</key_name> returns, with its modifiers in
the order C<Ctrl>, C<Alt>, C<Shift>, C<Super>, C<Hyper>, C<Meta> (see
L</KEY NAMES>); a KeyPress built from the fields has exactly that
C<key_name>. Any other name dies with
C<Term::Fabulous::Event::KeyPress: no key is named 'ctrl+w'>.

=head1 METHODS

=head2 key_name

	my $name = $event->key_name;    # 'Left', 'Ctrl+Shift+Right', 'Enter', 'a', 'Ctrl+W', ...

Returns a readable name of the key together with its modifiers, or
C<undef> for a key code that has no name (including the C1 control
characters U+0080 to U+009F, which L</text> does not return either).
Compare it with C<eq> to bind
keys; see L</KEY NAMES> for every possible result. Because the result
can be C<undef>, write C<< ( $event->key_name // '' ) eq 'Ctrl+S' >>
to avoid "uninitialized" warnings.

The name is built as follows:

=over

=item *

The modifiers come first, joined with C<+>, always in the order
C<Ctrl>, C<Alt>, C<Shift>, C<Super>, C<Hyper>, C<Meta>:
C<'Ctrl+Alt+Shift+Left'>, never C<'Shift+Ctrl+Left'>. Only terminals
that speak the kitty keyboard protocol report C<Super>, C<Hyper> and
C<Meta>.

=item *

The key follows: a key name such as C<Left> or C<F5>, an uppercase
letter or a symbol after C<Ctrl+> (C<'Ctrl+W'>), or the typed character
itself (C<'a'>, C<'A'>, C<'?'>, C<'E<eacute>'>).

=back

=head2 main_key_name

	my $name = $event->main_key_name;    # 'Left' for both Left and the keypad's Left

Like L</key_name>, except that a keypad key the kitty keyboard
protocol tells apart is named after the main keyboard key it stands
for, as terminals without the protocol report it: C<KeypadLeft> is
C<'Left'>, C<KeypadEnter> is C<'Enter'>, C<Keypad7> is C<'7'>,
C<KeypadAdd> is C<'+'>, and C<'Ctrl+KeypadHome'> is C<'Ctrl+Home'>.
C<KeypadBegin> has no such key and keeps its name. For every other key
the result is the same as L</key_name>. The built-in widgets bind
their keys with C<main_key_name>, so the keypad works in them with or
without the protocol; use it for bindings that should do the same.

=head2 text

	my $character = $event->text;

Returns the character the key types, as a character string of length
one, or C<undef> when the key does not type anything.

=over

=item *

A printable character typed without Ctrl or Alt returns that character:
C<'a'>, C<'A'>, C<'7'>, C<'?'>, C<'E<eacute>'>, a CJK character, and so on.

=item *

The space bar returns C<' '>, however the terminal reports it.

=item *

Special keys (arrows, Enter, Tab, Backspace, Escape, function keys, ...),
combinations with Ctrl, Alt, Super, Hyper or Meta, and control
characters (U+0000 to U+001F, U+007F to U+009F) return C<undef>.

=back

Text inputs insert exactly what C<text> returns.

=head2 key

	my $code = $event->key;

The raw termbox2 key code given to the constructor (see L</new>).

=head2 char

	my $code_point = $event->char;

The raw Unicode code point of a typed character, C<0> for a special key.
Use C<chr $event-E<gt>char> to get the character, or better L</text>,
which also filters out control characters.

=head2 modifiers

	use Term::Fabulous::Termbox qw(TB_MOD_CTRL);
	my $ctrl_held = $event->modifiers & TB_MOD_CTRL;

The raw bit mask of C<TB_MOD_ALT>, C<TB_MOD_CTRL> and C<TB_MOD_SHIFT>,
and of C<TF_MOD_SUPER>, C<TF_MOD_HYPER> and C<TF_MOD_META> from the
kitty keyboard protocol. Note that termbox2 sets C<TB_MOD_CTRL> on every key of the ASCII control
range, including Enter, Tab, Escape and Backspace; L</key_name> takes
care of that, so prefer it over testing the bits yourself.

=head1 KEY NAMES

These are all the names L</key_name> returns, without modifiers.

=head2 Named keys

=for highlighter language=text

	Name          Key
	------------  -------------------------------------------------
	Left          Arrow left
	Right         Arrow right
	Up            Arrow up
	Down          Arrow down
	Home          Home
	End           End
	PageUp        Page Up
	PageDown      Page Down
	Insert        Insert
	Delete        Delete (forward delete)
	Backspace     Backspace (byte 0x7F or 0x08)
	Tab           Tab (byte 0x09)
	BackTab       Shift+Tab, as most terminals report it
	Enter         Enter / Return (byte 0x0D)
	Escape        Escape (byte 0x1B)
	Space         The space bar (key 0x20, or key 0 with char 0x20)
	F1 .. F12     Function keys

Terminals that speak the kitty keyboard protocol report these keys as
well:

	Name                 Key
	-------------------  ------------------------------------------
	F13 .. F35           Function keys beyond F12
	CapsLock             Caps Lock
	ScrollLock           Scroll Lock
	NumLock              Num Lock
	PrintScreen          Print Screen
	Pause                Pause
	Menu                 Menu (context menu key)
	Keypad0 .. Keypad9   Keypad digits
	KeypadDecimal        Keypad . (decimal point)
	KeypadDivide         Keypad /
	KeypadMultiply       Keypad *
	KeypadSubtract       Keypad -
	KeypadAdd            Keypad +
	KeypadEnter          Keypad Enter
	KeypadEqual          Keypad =
	KeypadSeparator      Keypad separator
	KeypadLeft           Keypad Left (Num Lock off), and so on:
	KeypadRight          KeypadUp, KeypadDown, KeypadPageUp,
	                     KeypadPageDown, KeypadHome, KeypadEnd,
	                     KeypadInsert, KeypadDelete
	KeypadBegin          Keypad 5 with Num Lock off
	MediaPlay            Media keys: MediaPause, MediaPlayPause,
	                     MediaReverse, MediaStop, MediaFastForward,
	                     MediaRewind, MediaTrackNext,
	                     MediaTrackPrevious, MediaRecord
	LowerVolume          Volume down
	RaiseVolume          Volume up
	MuteVolume           Mute

kitty reports the keypad keys only when they do not type text: with
Num Lock on, a keypad digit typed alone is the character C<'7'>, but
Ctrl plus that key is C<'Ctrl+Keypad7'>. L</main_key_name> names the
keypad keys after their main keyboard keys instead. Whether the lock
keys, Print Screen and the media keys reach the program at all depends
on the terminal and the desktop.

=head2 Ctrl and a letter

Terminals send Ctrl plus a letter as a single control byte, and the name
is C<Ctrl+> followed by the uppercase letter: C<'Ctrl+A'> to C<'Ctrl+Z'>.
Some of these bytes are the same bytes other keys send, so the terminal
cannot tell them apart and they get the name of the other key:

	You press   Name
	---------   ---------
	Ctrl+H      Backspace
	Ctrl+I      Tab
	Ctrl+M      Enter
	Ctrl+[      Escape

The remaining control bytes are named after the symbol that produces
them on a US keyboard: C<'Ctrl+Space'> (byte 0, also sent for Ctrl+@ or
Ctrl+2), C<'Ctrl+\'>, C<'Ctrl+]'>, C<'Ctrl+^'> and C<'Ctrl+_'>. Ctrl+J
(byte 0x0A, line feed) is named C<'Ctrl+J'>, not C<'Enter'>.

termbox2 marks every control byte with C<TB_MOD_CTRL>. For these keys
C<key_name> ignores that bit and decides from the byte alone, so Enter is
always C<'Enter'>, never C<'Ctrl+Enter'>. Terminals that speak the kitty
keyboard protocol tell all of these keys apart; see
L</THE KITTY KEYBOARD PROTOCOL>.

=head2 Modifier combinations

	Name                 You press
	-------------------  ----------------------------------------------
	Shift+Left           Shift and Left
	Ctrl+Right           Ctrl and Right
	Ctrl+Shift+Right     Ctrl, Shift and Right
	Alt+Down             Alt and Down
	Ctrl+Alt+Shift+F5    Ctrl, Alt, Shift and F5

Modifiers are reported only for the special keys that terminals send as
xterm modifier sequences: the four arrow keys, Home, End, Insert,
Delete, Page Up, Page Down and F1 to F12. Any combination of Ctrl, Alt
and Shift with these keys gets a name, as far as the terminal sends it.

For every other key, terminals cannot report modifiers, unless they
speak the kitty keyboard protocol (see L</THE KITTY KEYBOARD PROTOCOL>),
which leads to these rules:

=over

=item *

Shift plus a character arrives as the shifted character, without a
modifier: Shift+a is C<'A'>, never C<'Shift+A'>.

=item *

Ctrl plus a letter arrives as a control byte and is named C<'Ctrl+W'>
and so on (see L</Ctrl and a letter>). Ctrl+Shift+W is the same byte,
so it is C<'Ctrl+W'> too.

=item *

Alt plus a character is sent as Escape followed by the character, in
one write. L<Term::Fabulous> recognizes that pair and names it
C<'Alt+x'>, C<'Alt+Enter'>, C<'Alt+E<uuml>'>; Ctrl+Alt+W arrives as
C<'Ctrl+Alt+W'>. A lone Escape is still C<'Escape'>. Alt+[ and Alt+O
cannot be told from the start of the escape sequences of other keys and
are not named. An Escape followed so quickly by a key that both arrive
in the same read looks like Alt plus that key.

=back

=head2 Unnamed keys

C<key_name> returns C<undef> for key codes it does not know, for
example a C<TB_KEY_MOUSE_*> code given to the constructor by mistake.

=head1 THE KITTY KEYBOARD PROTOCOL

L<Term::Fabulous> asks the terminal for the
L<kitty keyboard protocol|https://sw.kovidgoyal.net/kitty/keyboard-protocol/>
when it supports it (kitty and a growing number of other terminals;
see the C<kitty_keyboard> parameter of L<Term::Fabulous/new>). Such a terminal reports keys
without the ambiguities of the legacy encodings, and the names follow:

=over

=item *

Every Ctrl combination gets its own name: Ctrl+I is C<'Ctrl+I'>, not
C<'Tab'>; Ctrl+M is C<'Ctrl+M'>, Ctrl+H C<'Ctrl+H'>, Ctrl+[ C<'Ctrl+['>;
Ctrl+Enter, Ctrl+Tab, Ctrl+Backspace and Ctrl+Escape are
C<'Ctrl+Enter'> and so on; Ctrl+1 is C<'Ctrl+1'>.

=item *

Shift is named together with Ctrl: Ctrl+Shift+W is C<'Ctrl+Shift+W'>,
no longer the same as C<'Ctrl+W'>. Shift+Enter is C<'Shift+Enter'>.

=item *

Alt plus a key no longer depends on timing, and Alt+[ and Alt+O get
names. Alt plus a character is still named after the character Shift
makes, as in other terminals: Alt+Shift+a is C<'Alt+A'>, Alt+Shift+1 on
a US keyboard C<'Alt+!'>.

=item *

Super, Hyper and Meta are reported; they behave like Alt:
C<'Super+a'>, C<'Ctrl+Super+Left'>.

=item *

The keys in the second table of L</Named keys> are reported.

=back

Keys typed without a modifier are unchanged: the character, Enter, Tab,
Backspace and Shift+Tab (C<'BackTab'>) are reported as in any other
terminal, and so are the names of Ctrl+C, Tab and Shift+Tab that
L<Term::Fabulous> acts on itself.

=head1 BINDING KEYS

Compare L</key_name> with the name of the key you want, or
L</main_key_name> when the keypad keys should count as the main keyboard
keys they stand for. To find the name of a key on your terminal, run
F<examples/event-monitor.pl> and press it. A dispatch table keeps longer lists readable:

=for highlighter language=perl

	use Clay::UI::Enum::Result;

	my %action = (
		'Ctrl+S' => sub { save_document() },
		'Ctrl+Q' => sub { $ui->loop->stop },
		'F1'     => sub { show_help() },
	);

	$root->on( KeyPress => sub ($event) {
		my $code = $action{ $event->key_name // '' }
			// return Clay::UI::Enum::Result->CONTINUE;
		$code->();
		return;
	} );

Key presses are fired on the focused widget first. A listener on the
root sees a key only if no widget on the way returned anything other
than C<< Clay::UI::Enum::Result->CONTINUE >>. The input widgets pass on
the keys they do not use (Escape, function keys, Ctrl+S, ...), so
application shortcuts on the root keep working while the user types.
See L<Term::Fabulous::Manual::Events/KEYBOARD>.

Ctrl+C, Tab and Shift+Tab are fired like every other key, but
L<Term::Fabulous> then acts on them itself (it stops on Ctrl+C, unless
it was made with C<< stop_on_ctrl_c =E<gt> 0 >>, and moves the focus on
Tab and Shift+Tab); see
L<Term::Fabulous::Manual::Events/Keys Term::Fabulous handles itself>.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Events/KEYBOARD>, L<Term::Fabulous>,
L<Term::Fabulous::Event::Mouse>, L<Clay::UI::Events::Event>, L<Term::Fabulous::Termbox>,
L<Term::Fabulous::Cookbook::KeyboardAndMouse/Bind a key to an action>,
L<Term::Fabulous::Cookbook::GettingStarted/Quit with q or Escape>.

=cut
