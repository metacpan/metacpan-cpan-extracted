use strict;
use warnings;

use Test::More;
use Data::Dumper;
local $Data::Dumper::Terse = 1;
local $Data::Dumper::Indent = 0;

BEGIN { use_ok('PerlGSL::DiffEq', ':all') };

sub eqn {

  #initial conditions returned if called without parameters
  unless (@_) {
    return (0,1);
  }

  my ($t, @y) = @_;
  
  #sine func except starts throwing undef at some point
  my @derivs = (
    ($y[0]<0.5) ? $y[1] : undef,
    -$y[0],
  );
  return @derivs;
}

## Test basic functionality ##

{
  my $sin;
  my $message;
  {
    local $SIG{__WARN__} = sub { ($message) = @_ };
    $sin = ode_solver(\&eqn, [0, 2*3.14, 100]);
  }

  is( $message, "'ode_solver' has encountered a bad return value\n", "Generated error message");

  is( ref $sin, "ARRAY", "ode_solver returns array ref" );

  is_deeply($sin->[0], [0,0,1], "Initial conditions are included in return");

  isnt( scalar @$sin, 101, "Returned fewer than requested elements");
  isnt( scalar @$sin, 0, "Still returned some elements");

  isnt( $sin->[0], 0.0, "Doesn't include failed step" );

  

  #my ($pi_by_2) = grep { sprintf("%.2f", $_->[0]) == 1.57 } @$sin;

  #is( ref $pi_by_2, "ARRAY", "each solved element is an array ref");
  #is( sprintf("%.5f", $pi_by_2->[1]), sprintf("%.5f", 1), "found sin(pi/2) == 1");

}

done_testing();
