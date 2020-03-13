
# Make sure Cascade labels may contain '.'
# https://rt.cpan.org/Ticket/Display.html?id=125058
# TODO: test 'Name' option more generally
# and whichever other filters were also updated
# (look for "no spaces" in Widget.pm)

use warnings;
use strict;

use Test::More tests => 1;

#use Tk; # verified for consistency with Perl/Tk
use Tcl::pTk;

my $mw = MainWindow->new;
my $menu = $mw->Menu(-tearoff => 0);

# doesn't automatically create menu for cascade
#$menu->add('cascade', -label => 'Menu...');

# *does* automatically create menu for cascade
my $cascade = $menu->Cascade(-label => 'Menu...');

pass(q(Create Cascade with '.' in -label and without -menu));

print '# $menu->type(0): ' . $menu->type(0) . "\n";
print q(# $menu->entrycget(0, '-menu')->PathName: )
        . $menu->entrycget(0, '-menu')->PathName # .menu.menu_ in Perl/Tk
        . "\n";

$mw->configure(-menu => $menu);

(@ARGV) ? MainLoop : $mw->destroy;
