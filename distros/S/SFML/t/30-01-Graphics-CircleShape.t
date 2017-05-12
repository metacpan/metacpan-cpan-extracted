# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl SFML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('SFML::Graphics') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $context = new_ok 'SFML::Graphics::CircleShape', [ radius => 20, pointCount => 100 ];

can_ok(
	$context, qw(setRadius setPointCount setTexture setTextureRect setFillColor setOutlineColor setOutlineThickness
	  getPoint getRadius getPointCount getTextureRect getFillColor getOutlineColor getOutlineThickness
	  getLocalBounds getGlobalBounds setPosition getPosition setOrigin getOrigin setRotation getRotation
	  getScale setScale move rotate getTransform getInverseTransform));

is($context->getRadius(),     20,  'getRadius');
is($context->getPointCount(), 100, 'getPointCount');

=head1 COPYRIGHT

 ############################################
 # Copyright 2013 Jake Bott, Georgiy Tugai. #
 #=>--------------------------------------<=#
 #  All Rights Reserved. Part of perl-sfml  #
 ############################################

=cut
