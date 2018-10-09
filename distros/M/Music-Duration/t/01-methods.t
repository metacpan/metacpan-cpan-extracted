#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Duration';
#use Data::Dumper;$Data::Dumper::Sortkeys=1;warn Dumper\%MIDI::Simple::Length;exit;

my %expected = (
    # 32nd
      yn => '0.12500',
     dyn => '0.18750',
    ddyn => '0.21875',
     tyn => '0.08333',
    # 64th
      xn => '0.06250',
     dxn => '0.09375',
    ddxn => '0.10938',
     txn => '0.04167',
);
for my $i ( keys %expected ) {
    is sprintf( '%.5f', $MIDI::Simple::Length{$i} ), $expected{$i}, $i;
}

Music::Duration::tuple( 'qn', 'z', 3 );
is $MIDI::Simple::Length{zqn}, $MIDI::Simple::Length{ten}, 'zqn = ten';

Music::Duration::tuple( 'wn', 'z', 5 );
my $expected = 4 / 5;
is $MIDI::Simple::Length{zwn}, $expected, 'zwn 5-tuple';

done_testing();
