#!/usr/bin/perl -w

###########################################
# Test data

$data = {
         'A'  => [ qw(A A C B) ],
         'U'  => [ 'A',undef,'Z' ],
        };

$test = "01";
###########################################

use Template;
use IO::File;

$runtests=shift(@ARGV);
if ( -f "t/test.pl" ) {
  require "t/test.pl";
} elsif ( -f "test.pl" ) {
  require "test.pl";
} else {
  die "ERROR: cannot find test.pl\n";
}

test($test,$data,$runtests);

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

