# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Term-Prompt.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Term::Prompt') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

## Can't run this automagically unless we require expect...
##my $passwd = prompt("p", "Password:", "", "" );
##print "The password is $passwd\n";
##my $resp  = prompt("x", "Type anything:", "don't be dirty", "foo" );
##print "The response is '$resp'\n";


