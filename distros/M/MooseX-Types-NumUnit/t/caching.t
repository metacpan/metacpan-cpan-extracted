use strict;
use warnings;

use Test::More tests => 6;

use MooseX::Types::NumUnit qw/num_of_unit/;

# Test simple units
my $unit1 = num_of_unit('m');

{
  my $unit2 = num_of_unit('m');
  ok( $unit1 == $unit2, 'Using the same definition returns the same object' );
}

{
  my $unit2 = num_of_unit('meters');
  ok( $unit1 == $unit2, 'Using an equivalent definition returns the same object' );
}

{
  my $unit2 = num_of_unit('ft');
  ok( $unit1 != $unit2, 'Compatible but non-equal definitions do not return same object' );
}

# Test compound units
my $compound1 = num_of_unit('m / s');

{
  my $compound2 = num_of_unit('m / s');
  ok( $compound1 == $compound2, '(Compound) Using the same definition returns the same object' );
}

{
  my $compound2 = num_of_unit('meters / second');
  ok( $compound1 == $compound2, '(Compound) Using an equivalent definition returns the same object' );
}

{
  my $compound2 = num_of_unit('ft / s');
  ok( $compound1 != $compound2, '(Compound) Compatible but non-equal definitions do not return same object' );
}
