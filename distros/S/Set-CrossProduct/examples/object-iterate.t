use warnings;
use strict;

use lib qw(/Users/brian/Dev/set-crossproduct/lib);

use Set::CrossProduct;
use Object::Iterate qw(imap);
use Mojo::Util qw(dumper);

*Set::CrossProduct::__next__ = \&Set::CrossProduct::next;
*Set::CrossProduct::__more__ = sub { ! $_[0]->done };

my $cross = Set::CrossProduct->new( [ [qw(a b c)], [1,2,3] ] );
my @tuples = imap { print dumper($_) } $cross;
