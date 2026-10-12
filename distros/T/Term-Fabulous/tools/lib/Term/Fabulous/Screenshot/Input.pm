package Term::Fabulous::Screenshot::Input;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Carp qw(croak);
use Encode qw(encode);
use Exporter qw(import);

our @EXPORT_OK = qw(key_bytes text_bytes mouse_bytes);

# The bytes an xterm-compatible terminal sends, in the modes termbox2
# switches on: keypad transmit mode (arrows as ESC O A) and SGR mouse
# reports (ESC [ < button ; column ; row M, or m for a release).

# Keys that a modifier changes by a parameter: ESC [ 1 ; m X or ESC [ n ; m ~.
my %CSI_FINAL_BY_KEY  = ( Up => 'A', Down => 'B', Right => 'C', Left => 'D', Home => 'H', End => 'F' );
my %CSI_NUMBER_BY_KEY = (
	Insert => 2,  Delete => 3,  PageUp => 5,  PageDown => 6,
	F5     => 15, F6     => 17, F7     => 18, F8       => 19, F9 => 20, F10 => 21, F11 => 23, F12 => 24,
);
my %SS3_FINAL_BY_KEY = ( F1 => 'P', F2 => 'Q', F3 => 'R', F4 => 'S' );

# Keys that are a single byte or a fixed sequence, without modifiers.
my %PLAIN_BYTES_BY_KEY = (
	Tab       => "\t",
	BackTab   => "\e[Z",
	Enter     => "\r",
	Escape    => "\e",
	Space     => ' ',
	Backspace => "\x7f",
);

my %MODIFIER_BIT = ( Shift => 1, Alt => 2, Ctrl => 4 );

my %BUTTON_CODE = ( left => 0, middle => 1, right => 2 );
use constant MOTION_FLAG      => 32;
use constant NO_BUTTON_MOTION => 35;    # motion with no button held (any-event tracking)
use constant WHEEL_UP         => 64;
use constant WHEEL_DOWN       => 65;

# 'Ctrl+Shift+Left' => ( { Ctrl => 1, Shift => 1 }, 'Left' ). The key is
# the last part, so 'Ctrl++' names the plus key.
sub _split_key_name ($name) {
	my ( $modifiers, $key ) = $name =~ /\A((?:(?:Ctrl|Alt|Shift)\+)*)(.+)\z/
		or croak "Term::Fabulous::Screenshot::Input: '$name' is not a key name";
	my %held = map { $_ => 1 } grep { length } split /\+/, $modifiers;
	return ( \%held, $key );
}

sub _modifier_parameter ($held) {
	my $bits = 0;
	$bits |= $MODIFIER_BIT{$_} foreach keys %$held;
	return $bits + 1;
}

sub key_bytes ($name) {
	my ( $held, $key ) = _split_key_name($name);
	my $has_modifiers = %$held ? 1 : 0;

	if ( exists $PLAIN_BYTES_BY_KEY{$key} ) {
		return $PLAIN_BYTES_BY_KEY{$key} unless $has_modifiers;
		return "\e[Z" if $key eq 'Tab'                              && join( ',', keys %$held ) eq 'Shift';
		return "\x00" if $key eq 'Space'                            && join( ',', keys %$held ) eq 'Ctrl';
		return "\e" . $PLAIN_BYTES_BY_KEY{$key} if $key ne 'Escape' && join( ',', keys %$held ) eq 'Alt';
		croak "Term::Fabulous::Screenshot::Input: '$name' cannot be sent by a terminal";
	}
	if ( exists $CSI_FINAL_BY_KEY{$key} ) {
		return "\eO$CSI_FINAL_BY_KEY{$key}" unless $has_modifiers;
		return sprintf "\e[1;%d%s", _modifier_parameter($held), $CSI_FINAL_BY_KEY{$key};
	}
	if ( exists $CSI_NUMBER_BY_KEY{$key} ) {
		return "\e[$CSI_NUMBER_BY_KEY{$key}~" unless $has_modifiers;
		return sprintf "\e[%d;%d~", $CSI_NUMBER_BY_KEY{$key}, _modifier_parameter($held);
	}
	if ( exists $SS3_FINAL_BY_KEY{$key} ) {
		return "\eO$SS3_FINAL_BY_KEY{$key}" unless $has_modifiers;
		return sprintf "\e[1;%d%s", _modifier_parameter($held), $SS3_FINAL_BY_KEY{$key};
	}

	croak "Term::Fabulous::Screenshot::Input: unknown key '$key' in '$name'" unless length($key) == 1;
	croak "Term::Fabulous::Screenshot::Input: '$name' cannot be sent by a terminal; type the character instead" if $held->{Shift};

	my $bytes = encode( 'UTF-8', $key, Encode::FB_CROAK | Encode::LEAVE_SRC );
	if ( $held->{Ctrl} ) {
		croak "Term::Fabulous::Screenshot::Input: '$name' has no control code" unless $key =~ /\A[A-Za-z\[\\\]^_@ ]\z/;
		$bytes = chr( ord( uc $key ) & 0x1F );
	}
	return $held->{Alt} ? "\e$bytes" : $bytes;
}

sub text_bytes ($text) {
	croak 'Term::Fabulous::Screenshot::Input: text to type must not be empty' unless length $text;
	croak 'Term::Fabulous::Screenshot::Input: type control characters as keys, not as text' if $text =~ /[\x00-\x1f\x7f]/;
	return encode( 'UTF-8', $text, Encode::FB_CROAK | Encode::LEAVE_SRC );
}

# One mouse report. $action is press, release, drag (motion with the
# button held), move (motion without a button) or wheel_up / wheel_down.
# Cells count from 0, like everywhere in Term::Fabulous.
sub mouse_bytes ( $action, $x, $y, $button = 'left' ) {
	croak "Term::Fabulous::Screenshot::Input: the mouse position ($x, $y) must be two cells counted from 0"
		unless $x =~ /\A\d+\z/ && $y =~ /\A\d+\z/;
	croak "Term::Fabulous::Screenshot::Input: unknown mouse button '$button' (left, middle or right)" unless exists $BUTTON_CODE{$button};

	my %code_by_action = (
		press      => $BUTTON_CODE{$button},
		release    => $BUTTON_CODE{$button},
		drag       => $BUTTON_CODE{$button} + MOTION_FLAG,
		move       => NO_BUTTON_MOTION,
		wheel_up   => WHEEL_UP,
		wheel_down => WHEEL_DOWN,
	);
	croak "Term::Fabulous::Screenshot::Input: unknown mouse action '$action'" unless exists $code_by_action{$action};
	return sprintf "\e[<%d;%d;%d%s", $code_by_action{$action}, $x + 1, $y + 1, $action eq 'release' ? 'm' : 'M';
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::Input - The bytes a terminal sends for keys,
text and the mouse

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::Input qw(key_bytes text_bytes mouse_bytes);

	key_bytes('Tab');                 # "\t"
	key_bytes('Ctrl+Shift+Left');     # "\e[1;6D"
	text_bytes("Gr\x{fc}\x{df}e");    # UTF-8 bytes
	mouse_bytes( press => 10, 4 );    # "\e[<0;11;5M"

=head1 DESCRIPTION

Maintainer tool, not installed. The screenshot harness writes these
bytes into the pseudo terminal an example program runs in, so the
program receives them exactly as it would from a real xterm-compatible
terminal: termbox2 parses them, and Term::Fabulous turns them into
events.

=head1 FUNCTIONS

All functions die with a descriptive message on input a terminal could
not send.

=head2 key_bytes

	my $bytes = key_bytes($key_name);

C<$key_name> uses the names of L<Term::Fabulous::Event::KeyPress/key_name>:
C<Tab>, C<BackTab>, C<Enter>, C<Escape>, C<Space>, C<Backspace>, C<Up>,
C<Down>, C<Left>, C<Right>, C<Home>, C<End>, C<PageUp>, C<PageDown>,
C<Insert>, C<Delete>, C<F1> to C<F12> or a single character, with any
of the prefixes C<Ctrl+>, C<Alt+> and C<Shift+> in front. Control
characters exist only for letters, C<@ [ \ ] ^ _> and C<Space>;
C<Shift+> combines only with the named keys (type an uppercase letter
as text instead).

=head2 text_bytes

	my $bytes = text_bytes($text);

The UTF-8 encoding of a character string, as typed. Control characters
are refused; send them with L</key_bytes>.

=head2 mouse_bytes

	my $bytes = mouse_bytes( $action, $x, $y, $button );

One SGR mouse report at cell C<$x>, C<$y> (counted from 0). C<$action>
is C<press>, C<release>, C<drag> (motion while C<$button> is held),
C<move> (motion with no button held), C<wheel_up> or C<wheel_down>.
C<$button> is C<left> (the default), C<middle> or C<right>.

=cut
