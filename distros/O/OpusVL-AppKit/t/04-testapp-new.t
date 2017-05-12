
##########################################################################################################################
# This set of tests should be run against the TestApp within the 't' directory of the OpusVL::AppKit Catalyst app.
#
# This set of tests is based around building the Catalyst object (with the inheritance AppBuilder brings)
# WARNING!... These tests are only for functions, etc that AppKit has, not "functionallity" as we are using the Catalyst
# object in what I think is an invalid way (by effectily just call ->new on it .. althou this works, there is NO! ::Engine
##########################################################################################################################

use strict;
use warnings;
use Catalyst::ScriptRunner;
use Test::More;
# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# instansiate the Catalyst object.. abit pointless without any ::Engine bits.. but for tests tis usful..
my $cat = Catalyst::ScriptRunner->run('TestApp', 'GetNew');

ok ( $cat, "Built 'new' Catalyst - AppBuilder object" );

can_ok($cat, qw/can_access who_can_access/ );

##########################################################################################################################
# Model tests ...
##########################################################################################################################

my $authdb = $cat->model('AppKitAuthDB');
ok($authdb, "Get the AppKitAuthDB model object");

done_testing;
