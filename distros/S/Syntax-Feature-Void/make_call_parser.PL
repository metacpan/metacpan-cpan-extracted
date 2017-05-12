use strict;
use warnings;

use Devel::CallParser qw( callparser1_h );

my ($qfn) = @ARGV;

open(my $fh, '>', $qfn)
   or die("Can't create \"$qfn\": $!\n");
print($fh callparser1_h())
   or die("Can't write to \"$qfn\": $!\n");
close($fh)
   or die("Can't write to \"$qfn\": $!\n");
