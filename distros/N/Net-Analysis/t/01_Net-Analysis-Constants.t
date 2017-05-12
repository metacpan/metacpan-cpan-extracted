# Before `make install' is performed this script should be runnable with
# `make test'.
# After `make install' it should work as `perl 01_Net-Analysis-Constants.t'
# $Id: 01_Net-Analysis-Constants.t 143 2005-11-03 17:36:58Z abworrall $

use strict;
use warnings;

use Test::More tests => 2;

#########################

BEGIN { use_ok('Net::Analysis::Constants') };

# This is a bit pathetic, really.
use Net::Analysis::Constants qw(:all);
isnt (URG, undef, "URG is defined");

__END__
