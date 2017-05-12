use strict;
use warnings;

use Test::More tests => 2;

use_ok( 'Spoon::Template::Mason' );

my $object = Spoon::Template::Mason->new;

isa_ok( $object, 'Spoon::Template::Mason' );
