use strict;
use warnings;

use Test::More;

use Physics::RayTransfer;

my $shift = sub { shift };

{
  my $lens = Physics::RayTransfer::Lens->new( f => 2, parameter => $shift );

  isa_ok( $lens, 'Physics::RayTransfer::Element' );
  isa_ok( $lens, 'Physics::RayTransfer::Lens' );

  {
    my $expected = [1,0,-0.5,1];
    is_deeply( $lens->get->as_arrayref, $expected, "with init without param" );
  }

  {
    my $expected = [1,0,-0.25,1];
    is_deeply( $lens->get(-0.25)->as_arrayref, $expected, "with init with param" );
  }
}

{
  my $lens = Physics::RayTransfer::Lens->new( parameter => $shift );

  isa_ok( $lens, 'Physics::RayTransfer::Element' );
  isa_ok( $lens, 'Physics::RayTransfer::Lens' );

  {
    my $expected = [1,0,0,1];
    is_deeply( $lens->get->as_arrayref, $expected, "without init without param"  );
  }

  {
    my $expected = [1,0,-0.125,1];
    is_deeply( $lens->get(-0.125)->as_arrayref, $expected, "without init with param" );
  }
}

done_testing;

