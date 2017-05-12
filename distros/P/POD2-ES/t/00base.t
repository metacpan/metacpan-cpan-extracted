# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POD2-ES.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

BEGIN { use_ok('POD2::ES') };

my $pod2 = POD2::ES->new();

like($pod2->search_perlfunc_re(), qr/^Lista de funciones de Perl/, 'Texto cabecera de perlfunc');
