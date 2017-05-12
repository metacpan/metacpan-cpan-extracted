# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sakai-Nakamura.t'

#########################

use Test::More tests => 3;
BEGIN { use_ok('Sakai::Nakamura') };

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok( my $nakamura = Sakai::Nakamura->new() );
isa_ok $nakamura, 'Sakai::Nakamura', 'nakamura';
