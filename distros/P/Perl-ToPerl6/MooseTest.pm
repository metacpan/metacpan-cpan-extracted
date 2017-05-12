package Point;
use Moose;
#has 'x';
#has "x1";
#has qw(x2);
#has $x3,1;
#has $x3,1;
#has ($x3,1);
#has foo => 1;
#has ['a'];

has 'a';
has b => is => 'rw';
has 'c' => is => 'rw';
has 'd', is => 'rw';
has x => ( is => 'rw' );
has y => ( is => 'rw', isa => 'Int' );
has z => ( is => 'r0', isa => 'Bool' );
has w => ( is => 'r0', isa => 'Bool', default => 32 );
