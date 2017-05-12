# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl SFML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6 + 5 + 1;
BEGIN { use_ok('SFML::Window'); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $vm = SFML::Window::VideoMode->new(800, 600);
isa_ok($vm, 'SFML::Window::VideoMode');
new_ok 'SFML::Window::Window';
my $window = new_ok 'SFML::Window::Window', [ $vm, "perl-sfml test window" ];

can_ok(
	$window, qw(create close isOpen getSettings getPosition setPosition getSize setSize setTitle
	  setVisible setIcon setVerticalSyncEnabled setMouseCursorVisible setKeyRepeatEnabled
	  setFramerateLimit setJoystickThreshold setActive display
	  pollEvent waitEvent));

my $cs = new_ok 'SFML::Window::ContextSettings', [ 'depthBits' => 24, 'stencilBits' => 8, 'minorVersion' => 1 ];
$window->create($vm, "perl-sfml test window", SFML::Window::Style::Default, $cs);
isa_ok($window, 'SFML::Window::Window');
my $c = $window->getSettings;
isa_ok($c, "SFML::Window::ContextSettings");

my $d = new SFML::Window::ContextSettings(depthBits => 24, stencilBits => 8, minorVersion => 1);
is($c->getDepthBits,   $d->getDepthBits,   "getSettings DepthBits value check");
is($c->getStencilBits, $d->getStencilBits, "getSettings StencilBits value check");
TODO: {
	local $TODO = 'Some hardware forces particular versions of GL context.';
	is($c->getMajorVersion, $d->getMajorVersion, "getSettings MajorVersion value check");
	is($c->getMinorVersion, $d->getMinorVersion, "getSettings MinorVersion value check");
}

=ignore
$window->setPosition(10, 20);

my ($x, $y) = $window->getPosition;

is($x, 10, "getPosition - x"); #Commented until further info available
is($y, 20, "getPosition - y");

$window->setSize(640, 480);

($x, $y) = $window->getSize;

is($x, 640, "getSize - x"); #Commented until further info available
is($y, 480, "getSize - y");
=cut

#our %t = qw(Width 800 Height 600 BitsPerPixel 16);
#is(eval '$window->get' . $_, $t{$_}, $_) for keys %t;

=head1 COPYRIGHT

 ############################################
 # Copyright 2013 Jake Bott, Georgiy Tugai. #
 #=>--------------------------------------<=#
 #  All Rights Reserved. Part of perl-sfml  #
 ############################################

=cut
