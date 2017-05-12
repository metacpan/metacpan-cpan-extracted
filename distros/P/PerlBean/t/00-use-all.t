# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use PerlBean;
use PerlBean::Attribute;
use PerlBean::Attribute::Boolean;
use PerlBean::Attribute::Factory;
use PerlBean::Attribute::Multi::Ordered;
use PerlBean::Attribute::Multi;
use PerlBean::Attribute::Multi::Unique::Associative;
use PerlBean::Attribute::Multi::Unique::Associative::MethodKey;
use PerlBean::Attribute::Multi::Unique::Ordered;
use PerlBean::Attribute::Multi::Unique;
use PerlBean::Attribute::Single;
use PerlBean::Collection;
use PerlBean::Method;
use PerlBean::Style;
my $s = PerlBean::Style->instance();

ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


