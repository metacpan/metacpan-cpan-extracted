use strict;
use warnings;

use Test::More;

use Physics::RayTransfer;

my $shift = sub { shift };

{
  my $space = Physics::RayTransfer::Space->new( length => 2, parameter => $shift );

  isa_ok( $space, 'Physics::RayTransfer::Element' );
  isa_ok( $space, 'Physics::RayTransfer::Space' );

  {
    my $expected = [1,2,0,1];
    is_deeply( $space->get->as_arrayref, $expected, "with init without param" );
  }

  {
    my $expected = [1,3,0,1];
    is_deeply( $space->get(3)->as_arrayref, $expected, "with init with param" );
  }
}

{
  my $space = Physics::RayTransfer::Space->new( parameter => $shift );

  isa_ok( $space, 'Physics::RayTransfer::Element' );
  isa_ok( $space, 'Physics::RayTransfer::Space' );

  {
    my $expected = [1,0,0,1];
    is_deeply( $space->get->as_arrayref, $expected, "without init without param"  );
  }

  {
    my $expected = [1,3,0,1];
    is_deeply( $space->get(3)->as_arrayref, $expected, "without init with param" );
  }
}

done_testing;

