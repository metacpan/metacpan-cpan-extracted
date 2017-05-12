
use strict;
use warnings;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::More;

# make sure testapp works
use ok 'TestApp';

# build the command that should request pages from the TestApp and the return the content...
my $test_cmd = "$^X $Bin/lib/script/testapp_test.pl ";

diag("Running test calls for pages in TestApp, using: $test_cmd");
like (`$test_cmd /login`,                qr/login_form/,     "Can Request the TestApp login page"    );

done_testing;
