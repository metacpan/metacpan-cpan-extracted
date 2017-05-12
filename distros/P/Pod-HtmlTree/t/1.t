# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################
# change 'tests => 1' to 'tests => last_test_to_print';

BEGIN { unshift @INC, "./lib"; }

use Pod::HtmlTree;
use Test;
use File::Path;

BEGIN { plan tests => 6 };

ok(1); # If we made it this far, we're ok.

#########################

ok(2); # Loaded ok

#########################
my @pms = Pod::HtmlTree::pms(".");

    # Check if there's only one pm file
ok(@pms == 1 and $pms[0] eq 'lib/Pod/HtmlTree.pm');

#########################
my @modules = Pod::HtmlTree::modules(".");

    # Check if there's only one module
ok(@modules == 1 and $modules[0] eq 'Pod::HtmlTree');

#########################
# Create html documentation for our own module

ok(Pod::HtmlTree::pod2htmltree("/perldoc", "t/docs/html"));
ok(-f "t/docs/html/Pod/HtmlTree.html");

#########################
# Cleanup

rmtree("t/docs");
