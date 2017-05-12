use strict;
use warnings;

use Test::More;

use Physics::RayTransfer;

my $ones = [1,0,0,1];
my $element = Physics::RayTransfer::Element->new();
my $obs = Physics::RayTransfer::Observer->new();

isa_ok( $element, 'Physics::RayTransfer::Element' );
is_deeply( $element->as_arrayref, $ones, "Element matrix method returns 'one' matrix" );

isa_ok( $obs, 'Physics::RayTransfer::Element' );
isa_ok( $obs, 'Physics::RayTransfer::Observer' );
is_deeply( $obs->as_arrayref, $ones, "Observer matrix method returns 'one' matrix" );

done_testing;

