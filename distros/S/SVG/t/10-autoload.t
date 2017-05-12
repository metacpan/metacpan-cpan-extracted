use strict;
use warnings;

use Test::More tests => 1;
use SVG ( -auto => 1 );

my $svg = SVG->new( -foo => "bar" );

ok( eval { $svg->make->it->up->as->we->go->along; },
    "autoload arbitrary xml tags" );

#--> currently this is allowed, in fact. It just has no effect.
#print("Failed in rejecting -auto argument") and exit(0)
#    if eval {
#        my $svg=new SVG(-auto => 1);
#	1;
#    };

