use strict;
use warnings;

use Test::More;

use PerlGSL::DiffEq;

my $comp_level = "%0.4f";

# ODEs: f'' - g' = 0        
#       g'' + f*g' + f'*g = 0
#       f(0)=0,f'(0)=1,f''(0)=-1,g(0)=1
# Solution: f(x) = 1 - exp(-x)
#           g(x) = exp(-x)

my $system = sub {

  unless (@_) {
    return (0, 1, -1, 1);
  }

  my ($t, @y) = @_;

  return (
    $y[1],
    $y[2],
    $y[1] * $y[3] - $y[0] * $y[2],
    $y[2],
  );

};

my $sol1 = sub { my $x=shift; 1 - exp(-$x)  };
my $sol2 = sub { my $x=shift; exp(-$x)      };

my $result = ode_solver( $system, 10 );

my @t = map { $_->[0] } @$result;
my @result_f = map { sprintf $comp_level, $_ } map { $_->[1] } @$result;
my @result_g = map { sprintf $comp_level, $_ } map { $_->[4] } @$result;

my @sol_f = map { sprintf $comp_level, $_ } map { $sol1->($_) } @t;
my @sol_g = map { sprintf $comp_level, $_ } map { $sol2->($_) } @t;

is_deeply(\@result_f, \@sol_f, "f(x) = 1-exp(-x)");
is_deeply(\@result_g, \@sol_g, "g(x) = exp(-x)"  );

done_testing;
