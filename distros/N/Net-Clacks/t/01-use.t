# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl PageCamel.t'

use strict;
use warnings;

#########################

# There is currently a problem under Windows with Date::Manip on
# certain non-english installations of XP (and possible others).
#
# So we set our time zone to CET
BEGIN {
    if(!defined($ENV{TZ})) {
        $ENV{TZ} = "CET";
    }
}

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { 
    use_ok('Net::Clacks');
    use_ok('Net::Clacks::Server');
    use_ok('Net::Clacks::Client');
    use_ok('Net::Clacks::ClacksCache');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

