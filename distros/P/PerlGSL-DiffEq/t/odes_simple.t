use strict;
use warnings;

use Test::More;

use PerlGSL::DiffEq;

my $comp_level = "%0.4f";

my %ODES = ( 
  DE1 => {
    desc => "y'=y, y(0)=2, y(x) = 2 e^{-x}", 
    ODE  => sub { return 2 unless @_; my ($t,$y) = @_; -$y; },
    t    => 2, 
    sol  => sub { my $t=shift; 2 * exp(-$t) },
  },
  DE2 => {
    desc => "y'=y^2, y(0)=1, y(x)=-1/(x-1)",
    ODE  => sub { return 1 unless @_; my ($t,$y) = @_; $y ** 2; },
    t    => 0.5,
    sol  => sub { my $t=shift; -1/($t-1) },
  },
  DEgauss => {                    
    desc => "y'=-2 x exp(-x^2), y(0) = 1, y(x) = exp(-x^2)",
    ODE  => sub { return 1 unless @_; my ($t,$y) = @_; - 2 * $t * exp ( - $t ** 2 ); },
    t    => 2,
    sol  => sub { my $t=shift;  exp(-$t**2) },
  },
  DElog  => {
    desc => "y' = x^-1, y(1) = 0, y(x) = ln(x)",
    ODE  => sub { return 0 unless @_; my ($t,$y) = @_; 1/$t; },
    t    => [1, 2, 100],
    sol  => sub { log(shift) },
  },
  DEtan  => {
    desc => "y' = y^2+1, y(0) = 0, y(x) = tan(x)", # singularity at pi/2 = 1.57...
    ODE  => sub { return 0 unless @_; my ($t,$y) = @_; $y ** 2 + 1; },
    t    => 1,
    sol  => sub { my $t=shift; sin($t)/cos($t); },
  }
);

for my $ode (keys %ODES) {
    verify_ode($ode, $ODES{$ode});
}

done_testing;

### 

sub verify_ode {
  my ($name, $ode) = @_;

  my $desc = "$name: '$ode->{desc}'";
  print $desc . "\n";

  my $result = ode_solver( $ode->{ODE}, $ode->{t} );

  my @result_t = map { $_->[0] } @$result;
  my @result_y = map { sprintf $comp_level, $_ } map { $_->[1] } @$result;

  my @sol_t = map { sprintf $comp_level, $_ } map { $ode->{sol}->($_) } @result_t;
  is_deeply(\@result_y, \@sol_t, $desc);
}



