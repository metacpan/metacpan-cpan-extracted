# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };
use vars qw( $loaded );
END { print "not ok 1\n" unless $loaded; }
use Net::Rsh;
$loaded++;
ok($loaded); # If we made it this far, we're ok.

my $r = Net::Rsh->new();
ok($r);

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

