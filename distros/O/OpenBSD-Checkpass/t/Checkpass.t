# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Checkpass.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('OpenBSD::Checkpass') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(&checkpass('password', '$2b$09$.njEqp3CFJMeZVc5ejt12ulcnWLLw7dZKyWwNWpVdribydem0dMqq'), 0);
is(&checkpass('password', '$2b$09$.nJeQP3cfjmEzvC5EjT12ULCNwllW7DzkYwWnwPvDRIBYDEM0DmQQ'), -1);
is(&checkpass('password', &newhash('password')), 0);
