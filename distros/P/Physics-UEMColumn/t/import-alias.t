use strict;
use warnings;

use Test::More tests => 19;

{
  package Local::Test::None;
  use Physics::UEMColumn;

  Test::More::ok( ! Local::Test::None->can('Column'), 'no aliases are imported' );
}

{
  package Local::Test::Individual;
  use Physics::UEMColumn alias => [ qw/Column/ ];

  Test::More::can_ok( 'Local::Test::Individual', 'Column' );
  Test::More::is( Column, 'Physics::UEMColumn::Column', 'correct definition of Column alias' );
  Test::More::ok( ! Local::Test::Individual->can('Laser'), 'non-requested aliases are not imported' );
}

{
  package Local::Test::Standard;
  use Physics::UEMColumn alias => ':standard';

  for my $alias ( qw/ Laser Column Photocathode MagneticLens DCAccelerator RFCavity / ) {
    my $func = Local::Test::Standard->can($alias);
    Test::More::ok( $func, "Alias is imported ($alias)" );
    Test::More::is( $func->(), "Physics::UEMColumn::$alias", "Alias has correct target" );
  }

  Test::More::ok( ! Local::Test::Standard->can('Element'), 'non-standard aliases are not imported' );
}

{
  package Local::Test::All;
  use Physics::UEMColumn alias => ':all';

  Test::More::can_ok( 'Local::Test::All', 'Element' );
  Test::More::is( Element, 'Physics::UEMColumn::Element', 'correct definition of Element alias' );
}

