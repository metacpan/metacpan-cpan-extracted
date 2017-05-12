# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
ok(1); # If we made it this far, we're ok.

#use_ok( "Sman::Config" );


__END__

# this is the real test
BEGIN { plan tests => 1 };

use SWISH::API;
use Sman::Util;

my $str = Sman::Util::GetVersionString($0, "");

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

