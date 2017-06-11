use strict;
use warnings;

use PDL::Lite;
use PolyNomial;

my $m = PolyNomial->new( coeffs => [ 3, 4 ], x => PDL->sequence(10) );
print $m, "\n";

$m *= 2;
print $m, "\n";

$m->x( PDL->sequence( 5 ) );
print $m, "\n";

