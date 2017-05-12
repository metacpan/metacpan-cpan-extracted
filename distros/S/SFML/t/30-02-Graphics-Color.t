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

my $color = new_ok 'SFML::Graphics::Color', [ 255, 255, 255, 255 ];

my $color2 = new_ok 'SFML::Graphics::Color', [ 255, 255, 255 ];

new_ok 'SFML::Graphics::Color';

can_ok(
	$color, qw(setR setG setB setA setRGBA
	  getR getG getB getA getRGBA));

#TODO: Add tests for + * == !=

=head1 COPYRIGHT

 ############################################
 # Copyright 2013 Jake Bott, Georgiy Tugai. #
 #=>--------------------------------------<=#
 #  All Rights Reserved. Part of perl-sfml  #
 ############################################

=cut
