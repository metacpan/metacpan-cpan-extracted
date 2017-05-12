# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl SFML.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('SFML::Graphics') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $font = new SFML::Graphics::Font;

isa_ok($font, "SFML::Graphics::Font");

my $font2 = new SFML::Graphics::Font($font);

isa_ok($font2, "SFML::Graphics::Font");

can_ok($font, qw(loadFromFile loadFromMemory getGlyph getKerning getLineSpacing getTexture));

=head1 COPYRIGHT

 ############################################
 # Copyright 2013 Jake Bott, Georgiy Tugai. #
 #=>--------------------------------------<=#
 #  All Rights Reserved. Part of perl-sfml  #
 ############################################

=cut
