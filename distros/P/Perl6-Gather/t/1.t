# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More 'no_plan';
BEGIN { use_ok('Perl6::Gather') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok eq_array([gather { take $_ for 1..10; take 99 }], [1..10, 99]);
ok eq_array([gather { take $_ for 1..10; take 99 unless gathered }], [1..10]);
ok eq_array([gather { take 99 unless gathered }], [99]);
ok eq_array([gather { take $_ for 1..10; pop @{+gathered} }], [1..9]);
ok(!eval{ take 'two' });
ok(!eval{ gathered });
