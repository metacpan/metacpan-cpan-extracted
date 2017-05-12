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

my $context = new_ok 'SFML::Graphics::Shader';

can_ok($context,                 qw(loadFromFile loadFromMemory setParameter));
can_ok('SFML::Graphics::Shader', qw(bind isAvailable));

=head1 COPYRIGHT

 ############################################
 # Copyright 2013 Jake Bott, Georgiy Tugai. #
 #=>--------------------------------------<=#
 #  All Rights Reserved. Part of perl-sfml  #
 ############################################

=cut
