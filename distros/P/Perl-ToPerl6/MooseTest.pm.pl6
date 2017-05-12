unit class Point;
use Moose:from<Perl5>;
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
has $.b is rw;

has 'c' => is => 'rw';
has $.c is rw;

has 'd', is => 'rw';
has $.d is rw;

has x => ( is => 'rw' );
has $.x is rw;

has y => ( is => 'rw', isa => 'Int' );
has Int $.y is rw;

has z => ( is => 'r0', isa => 'Bool' );
has Bool $.z;

has w => ( is => 'r0', isa => 'Bool', default => 32 );
has Bool $.w = 32;

