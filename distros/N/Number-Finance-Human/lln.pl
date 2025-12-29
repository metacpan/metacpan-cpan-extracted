use Scalar::Util qw(looks_like_number);
use strict;

$\ = "\n"; $, = "\t";

for (qw/
	   10
	   10k
	   k10
	   10.05
	   10.05k
	   1,000.05
	   k10.05
       /) {
    print $_, (looks_like_number($_) ? "x" : "-"), 0 + $_;
}
