use strict;
use warnings;

use Test::More tests => 21;
use List::MoreUtils qw/all/;

use Physics::UEMColumn;
use Physics::UEMColumn::Auxiliary ':constants';

# each call contributes 9 tests
sub make_sim {
  my ($number) = @_;
  $number ||= 1;

  # w_t = 100um, w_z = 50um, dE ~ Ta
  my $pulse = Physics::UEMColumn::Pulse->new(
    number => $number,
    velocity => '1e8 m/s',
    sigma_t => 100 ** 2 / 2 . 'um^2',
    sigma_z => 50 ** 2 / 2 . 'um^2',
    eta_t => me * 5.3 / 3 * 0.5 / 10 . 'kg eV',
  );
  isa_ok($pulse, 'Physics::UEMColumn::Pulse');

  my $column = Physics::UEMColumn::Column->new(
    length => '100 cm',
  );
  isa_ok($column, 'Physics::UEMColumn::Column');

  my $sim = Physics::UEMColumn->new(
    column => $column,
    pulse => $pulse,
  );

  my $result = $sim->propagate;
  ok( $result, 'Got a result from simulation' );
  is( ref $result, 'ARRAY', 'Result is an arrayref' );

  # $result->[i][0] is time (t)
  is( $result->[0][0], 0, 'By default result starts at t=0' );

  # $result->[i][1] is position of electron (z)
  is( $result->[0][1], 0, 'Resulting pulse starts at z=0' );
  ok( $result->[-1][1] > $column->length, 'Resulting pulse position is beyond the end of the column' );

  my (@dw_t, @dw_z);
  for my $i ( 1 .. $#$result ) {
    push @dw_t, ($result->[$i][3] - $result->[$i-1][3]);
    push @dw_z, ($result->[$i][4] - $result->[$i-1][4]);
  }

  ok( (all { $_ >= 0 } @dw_t), 'Pulse always expands transversely' );
  ok( (all { $_ >= 0 } @dw_z), 'Pulse always expands longitudinally' );

  return wantarray ? ($result, $sim) : $result;
}

my $low = make_sim();
my $high = make_sim(1e6);

SKIP: {
  skip 'result dimension is unequal, this is not guaranteed', 3 unless @$low == @$high;
  is( $low->[-1][0], $high->[-1][0], 'Final time of two like simulations is equal' );
  
  my (@dw_t, @dw_z);
  for my $i ( 0 .. $#$low ) {
    push @dw_t, ($high->[$i][3] - $low->[$i][3]);
    push @dw_z, ($high->[$i][4] - $low->[$i][4]);
  }

  ok( (all { $_ >= 0 } @dw_t), 'Higher charge density expands faster (transverse)' );
  ok( (all { $_ >= 0 } @dw_z), 'Higher charge density expands faster (longitudinal)' );
}


