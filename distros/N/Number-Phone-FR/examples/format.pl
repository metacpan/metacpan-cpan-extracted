use strict;
use warnings;

use Number::Phone::FR 'Full';

my $num = Number::Phone::FR->new($ARGV[0]) or exit 1;
print $num->format, "\n";
