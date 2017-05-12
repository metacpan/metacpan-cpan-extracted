#!/usr/bin/perl
# When invoked from Sys-Mlockall.t, this script will have a locked memory
# limit of 32mb and should therefore crash when it attempts to allocate 64mb.
#

use strict;
use warnings (FATAL => 'all');

use Sys::Mlockall qw(:all);
use Test::More;

diag "Dropping root permissions";
$< = $> = 65534;

diag "Locking memory";
my $rv = mlockall(MCL_FUTURE | MCL_CURRENT);

diag "Attempting to bite off more then we can chew";
my $buffer = "x" x (1048576*64);

diag "We should not get to this point!!";
exit 0;

