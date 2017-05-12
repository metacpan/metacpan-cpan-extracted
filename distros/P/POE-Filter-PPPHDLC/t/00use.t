# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl POE-Filter-PPPHDLC.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('POE::Filter::PPPHDLC') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $filter = POE::Filter::PPPHDLC->new;
isa_ok( $filter, 'POE::Filter::PPPHDLC' );

# when the framing buffer is '', return undef
ok(!defined $filter->get_pending, "framing buffer empty");
