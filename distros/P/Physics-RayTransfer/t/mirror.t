use strict;
use warnings;

use Test::More;

use Physics::RayTransfer;

my $shift = sub { shift };

{
  my $mirror = Physics::RayTransfer::Mirror->new( radius => 2, parameter => $shift );

  isa_ok( $mirror, 'Physics::RayTransfer::Element' );
  isa_ok( $mirror, 'Physics::RayTransfer::Mirror' );

  {
    my $expected = [1,0,-1,1];
    is_deeply( $mirror->get->as_arrayref, $expected, "with init without param" );
  }

  {
    my $expected = [1,0,-0.5,1];
    is_deeply( $mirror->get(-0.5)->as_arrayref, $expected, "with init with param" );
  }
}

{
  my $mirror = Physics::RayTransfer::Mirror->new( parameter => $shift );

  isa_ok( $mirror, 'Physics::RayTransfer::Element' );
  isa_ok( $mirror, 'Physics::RayTransfer::Mirror' );

  {
    my $expected = [1,0,0,1];
    is_deeply( $mirror->get->as_arrayref, $expected, "without init without param"  );
  }

  {
    my $expected = [1,0,-0.25,1];
    is_deeply( $mirror->get(-0.25)->as_arrayref, $expected, "without init with param" );
  }
}

done_testing;

