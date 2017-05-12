#!perl
use strict;
use warnings;

use PerlIO::Util;

*STDERR->push_layer(scalar => \my $buffer);

$a = $a + 1;

*STDERR->pop_layer();

chomp $buffer;
print "[$buffer]\n";
