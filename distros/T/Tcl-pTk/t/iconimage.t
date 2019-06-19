# Test of iconimage method. This method is implemented in Tcl as the iconphoto method,
#  which only exists is Tcl/pTk > 8.5
use warnings;
use strict;

use Tcl::pTk;

use Test;

my $top = MainWindow->new();

my $version = $top->tclVersion;
# print "version = $version\n";

# Skip if Tcl/pTk version is < 8.5
if( $version < 8.5 ){
    print "1..0 # Skipped: iconimage only works for Tcl >= 8.5\n";
    exit;
}

plan tests => 1;

my $icon = $top->Photo(-file =>  Tcl::pTk->findINC("icon.gif"));

$top->iconimage($icon);

$top->after(1000,sub{$top->destroy});

MainLoop;

ok(1);

