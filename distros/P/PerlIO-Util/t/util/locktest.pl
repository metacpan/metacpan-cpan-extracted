#!perl

use strict;
use warnings;
use PerlIO::Util;

my $in;
my $status = open $in, $ARGV[0], $ARGV[1];

exit( defined($status) ? $status : 42 );
