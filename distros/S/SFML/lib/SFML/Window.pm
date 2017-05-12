package SFML;

use 5.008009;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SFML ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
	'all' => [ qw(

		  ) ]);

our @EXPORT_OK = (@{ $EXPORT_TAGS{'all'} });

our @EXPORT = qw(

);

our $VERSION = '0.01';    # Alpha!

require XSLoader;
XSLoader::load('SFML', $VERSION);

package SFML::Window::Style;

use constant {
	None       => 0,
	Titlebar   => 1 << 0,
	Resize     => 1 << 1,
	Close      => 1 << 2,
	Fullscreen => 1 << 3,
	Default    => ((1 << 0) | (1 << 1) | (1 << 2)), };

package SFML::Window::Event;

use constant {
	Closed                 => 0,
	Resized                => 1,
	LostFocus              => 2,
	GainedFocus            => 3,
	TextEntered            => 4,
	KeyPressed             => 5,
	KeyReleased            => 6,
	MouseWheelMoved        => 7,
	MouseButtonPressed     => 8,
	MouseButtonReleased    => 9,
	MouseMoved             => 10,
	MouseEntered           => 11,
	MouseLeft              => 12,
	JoystickButtonPressed  => 13,
	JoystickButtonReleased => 14,
	JoystickMoved          => 15,
	JoystickConnected      => 16,
	JoystickDisconnected   => 17,
	Count                  => 18 };

package SFML::Window::Keyboard;

use constant {
	A         => 0,
	B         => 1,
	C         => 2,
	D         => 3,
	E         => 4,
	F         => 5,
	G         => 6,
	H         => 7,
	I         => 8,
	J         => 9,
	K         => 10,
	L         => 11,
	M         => 12,
	N         => 13,
	O         => 14,
	P         => 15,
	Q         => 16,
	R         => 17,
	S         => 18,
	T         => 19,
	U         => 20,
	V         => 21,
	W         => 22,
	X         => 23,
	Y         => 24,
	Z         => 25,
	Num0      => 26,
	Num1      => 27,
	Num2      => 28,
	Num3      => 29,
	Num4      => 30,
	Num5      => 31,
	Num6      => 32,
	Num7      => 33,
	Num8      => 34,
	Num9      => 35,
	Escape    => 36,
	LControl  => 37,
	LShift    => 38,
	LAlt      => 39,
	LSystem   => 40,
	RControl  => 41,
	RShift    => 42,
	RAlt      => 43,
	RSystem   => 44,
	Menu      => 45,
	LBracket  => 46,
	RBracket  => 47,
	SemiColon => 48,
	Comma     => 49,
	Period    => 50,
	Quote     => 51,
	Slash     => 52,
	BackSlash => 53,
	Tilde     => 54,
	Equal     => 55,
	Dash      => 56,
	Space     => 57,
	Return    => 58,
	Back      => 59,
	Tab       => 60,
	PageUp    => 61,
	PageDown  => 62,
	End       => 63,
	Home      => 64,
	Insert    => 65,
	Delete    => 66,
	Add       => 67,
	Subtract  => 68,
	Multiply  => 69,
	Divide    => 70,
	Left      => 71,
	Right     => 72,
	Up        => 73,
	Down      => 74,
	Numpad0   => 75,
	Numpad1   => 76,
	Numpad2   => 77,
	Numpad3   => 78,
	Numpad4   => 79,
	Numpad5   => 80,
	Numpad6   => 81,
	Numpad7   => 82,
	Numpad8   => 83,
	Numpad9   => 84,
	F1        => 85,
	F2        => 86,
	F3        => 87,
	F4        => 88,
	F5        => 89,
	F6        => 90,
	F7        => 91,
	F8        => 92,
	F9        => 93,
	F10       => 94,
	F11       => 95,
	F12       => 96,
	F13       => 97,
	F14       => 98,
	F15       => 99,
	Pause     => 100,
	KeyCount  => 101 };

package SFML::Window::Mouse::Button;

use constant {
	Left        => 0,
	Right       => 1,
	Middle      => 2,
	XButton1    => 3,
	XButton2    => 4,
	ButtonCount => 5 };

package SFML::Window::Joystick::Axis;

use constant {
	X    => 0,
	Y    => 1,
	Z    => 2,
	R    => 3,
	U    => 4,
	V    => 5,
	PovX => 6,
	PovY => 7 };

package SFML::Window::Joystick;

use constant {
	Count       => 8,
	ButtonCount => 32,
	AxisCount   => 8 };

1;

package SFML::Window::VideoMode;

#XXX: Move @{} etc overloads into XS for speed, add lvalue support!
use overload
  '""'  => sub { $_[0]->getWidth() . 'x' . $_[0]->getHeight() . ':' . $_[0]->getBitsPerPixel },
  '@{}' => sub { [ $_[0]->getWidth(), $_[0]->getHeight(), $_[0]->getBitsPerPixel ] },
  '%{}' => sub { { width => $_[0]->getWidth(), height => $_[0]->getHeight(), depth => $_[0]->getBitsPerPixel() } },
  '<=>' => sub { };

=head1 COPYRIGHT

 ############################################
 # Copyright 2013 Jake Bott, Georgiy Tugai. #
 #=>--------------------------------------<=#
 #  All Rights Reserved. Part of perl-sfml  #
 ############################################

=cut
