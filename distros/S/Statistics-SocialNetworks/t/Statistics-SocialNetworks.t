# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Graph-Statistics.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Statistics::SocialNetworks') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %g = (
"a" => {"b" => 1, "c" => 1, "d" => 1},
"b" => {"a" => 1},
"c" => {"a" => 1},
"d" => {"a" => 1},
);


ok( Statistics::SocialNetworks::constraint(\%g,"a") == 1/3, "constraint on a");
ok( Statistics::SocialNetworks::constraint(\%g,"b") == 1, "constraint on b");

%g = (
"a" => {"b" => 1, "c" => 1, "d" => 1},
"b" => {"a" => 1, "c" => 1, "d" => 1},
"c" => {"b" => 1, "a" => 1, "d" => 1},
"d" => {"b" => 1, "c" => 1, "a" => 1},
);

ok(Statistics::SocialNetworks::constraint(\%g,"a") == 1/3, "constraint on a with no flush");
Statistics::SocialNetworks::flushCache();
ok(Statistics::SocialNetworks::constraint(\%g,"a") == 0.925925925925926, "new constraint on a");
