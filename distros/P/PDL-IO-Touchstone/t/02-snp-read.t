#!/usr/bin/perl

use strict;
use warnings;

use PDL;
use PDL::IO::Touchstone;
use File::Temp qw/tempfile/;

use Test::More tests => 1;

my ($fh, $fn) = tempfile();

# Test input formats.  These are col-major even though they are dispalyed like
# row-major as a "matrix" format.  This is because  I want to test the 2-port format
# in a matrix layout with unusual numerical values as the first line of input.
print $fh q{
# MHz S DB R 50
1  1 1   2 1
  -1 2   2 2
2  1 1   2 1
  .1 2   2 2
3  1 1   2 1
  1e1 2   2 2
4  1 1   2 1
  +1e1 2   2 2
};

close($fh);

use Data::Dumper;
my @ret = eval { rsnp($fn) };
my $err = $@ // '';

ok(scalar(@ret), "unusual first line numeric values ($err)");

unlink($fn);
