# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl SFML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 12;
#Strange that this works.
BEGIN { use_ok('SFML::Window'); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

new_ok 'SFML::Graphics::RenderWindow';

my $vm = SFML::Window::VideoMode->new(800, 600);
isa_ok($vm, 'SFML::Window::VideoMode');

my $window = new_ok 'SFML::Graphics::RenderWindow', [ $vm, "perl-sfml test renderWindow" ];

can_ok(
	$window, qw(getSize capture create close isOpen getSettings pollEvent waitEvent getPosition
	  setPosition setSize setTitle setIcon setVisible setVerticalSyncEnabled setMouseCursorVisible
	  setKeyRepeatEnabled setFramerateLimit setJoystickThreshold setActive display clear setView
	  getView getDefaultView getViewport mapPixelToCoords mapCoordsToPixel draw pushGLStates
	  popGLStates resetGLStates));

my $cs = new_ok 'SFML::Window::ContextSettings', [ 'depthBits' => 24, 'stencilBits' => 8, 'minorVersion' => 1 ];
$window->create($vm, "perl-sfml test window", SFML::Window::Style::Default, $cs);
isa_ok($window, 'SFML::Graphics::RenderWindow');
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

=head1 COPYRIGHT

 ############################################
 # Copyright 2013 Jake Bott, Georgiy Tugai. #
 #=>--------------------------------------<=#
 #  All Rights Reserved. Part of perl-sfml  #
 ############################################

=cut
