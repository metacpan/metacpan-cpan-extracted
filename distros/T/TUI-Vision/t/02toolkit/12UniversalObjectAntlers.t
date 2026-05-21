use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dumper;

BEGIN {
  unless ( eval { require UNIVERSAL::Object } ) {
    plan skip_all => 'Test irrelevant without UNIVERSAL::Object';
  }
  require_ok 'TUI::toolkit::UO::Antlers';
}

BEGIN {
  package Point;
  use TUI::toolkit::UO::Antlers;

  has x => ( default => sub { 0 } );
  has y => ( is => 'rw', default => 0 );

  $INC{"Point.pm"} = 1;
}

BEGIN { 
  package Point3D;
  use TUI::toolkit::UO::Antlers;

  extends 'Point';

  has z => ( is => 'ro', default => sub { 0 } );

  $INC{"Point3D.pm"} = 1;
}

{
  no warnings 'once';
  use_ok 'Point';
  is_deeply(
    [ sort keys %Point::HAS ],
    [ qw( x y ) ],
    'keys %Point::HAS is equal to fields'
  );
  my $HAS = Point->TUI::toolkit::UO::Antlers::get_fields();
  is_deeply(
    [ sort keys %$HAS ],
    [ qw( x y ) ],
    'get_fields() for Point works correctly'
  );
  $_ = Dumper $HAS;
  s/\$VAR1/*{'Point::HAS'}{HASH}/;
  note $_;
}

{
  no warnings 'once';
  use_ok 'Point3D';
  is_deeply(
    [ sort keys %Point3D::HAS ],
    [ qw( x y z ) ],
    'keys %Point3D::HAS is equal to fields'
  );
  my $HAS = Point3D->TUI::toolkit::UO::Antlers::get_fields();
  is_deeply(
    [ sort keys %$HAS ],
    [ qw( x y z ) ],
    'get_fields() for Point3D works correctly'
  );
  $_ = Dumper $HAS;
  s/\$VAR1/*{'Point3D::HAS'}{HASH}/;
  note $_;
}

{
  my $point = Point->new( x => 5, y => 10 );
  is( $point->x, 5,  "Point->new sets x correctly" );
  is( $point->y, 10, "Point->new sets y correctly" );
}

{
  my $point = Point3D->new( z => 4 );
  is( $point->x, 0, "Point3D->new sets x correctly" );
  is( $point->y, 0, "Point3D->new sets y correctly" );
  is( $point->z, 4, "Point3D->new sets z correctly" );

  isa_ok( $point, 'UNIVERSAL::Object' );
  dies_ok { $point->z(5) } 'Access to attribute z works correctly';

  is_deeply(
    [ sort keys %$point ],
    [ qw( x y z ) ],
    'keys %$point is equal to fields'
  );
}

note 'Class::XSAccessor: ', TUI::toolkit::UO::Antlers::CAN_HAZ_XS() ? 1 : 0;

done_testing();
