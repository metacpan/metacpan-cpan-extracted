#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Duration';

my %expected = (
    # 32nd
      xn => '0.12500',
     dxn => '0.18750',
    ddxn => '0.21875',
     txn => '0.08333',
    # 64th
      yn => '0.06250',
     dyn => '0.09375',
    ddyn => '0.10938',
     tyn => '0.04167',
    # 128th
      zn => '0.03125',
     dzn => '0.04688',
    ddzn => '0.05469',
     tzn => '0.02083',
);
for my $i ( keys %expected ) {
    is sprintf( '%.5f', $MIDI::Simple::Length{$i} ), $expected{$i}, $i;
}

Music::Duration::tuple( 'qn', 'z', 3 );
is $MIDI::Simple::Length{zqn}, $MIDI::Simple::Length{ten}, 'zqn = ten';

Music::Duration::tuple( 'wn', 'z', 5 );
my $expected = 4 / 5;
is $MIDI::Simple::Length{zwn}, $expected, 'zwn 5-tuple';

$expected = '1.618';
Music::Duration::add_duration( phi => $expected );
is $MIDI::Simple::Length{phi}, $expected, 'phi';

done_testing();
