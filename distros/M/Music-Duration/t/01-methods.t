#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Music::Duration';
#use Data::Dumper;$Data::Dumper::Sortkeys=1;warn Dumper\%MIDI::Simple::Length;exit;

my %expected = (
    # 32nd
      yn => '0.1250',
     dyn => '0.1875',
    ddyn => '0.2188',
     tyn => '0.0833',
    # 64th
      xn => '0.0625',
     dxn => '0.0938',
    ddxn => '0.1094',
     txn => '0.0417',
);
for my $i ( keys %expected ) {
    is sprintf( '%.4f', $MIDI::Simple::Length{$i} ), $expected{$i}, $i;
}

Music::Duration::fractional( 'z', 4 );
%expected = (
    zwn => '4.0000',
    zhn => '2.0000',
    zqn => '1.0000',
    zen => '0.5000',
    zsn => '0.2500',
    zyn => '0.1250',
    zxn => '0.0625',
);
for my $i ( keys %expected ) {
    is sprintf( '%.4f', $MIDI::Simple::Length{$i} ), $expected{$i}, "$i 4";
}

Music::Duration::fractional( 'z', 5 );
%expected = (
    zwn => '5.0000',
    zhn => '2.5000',
    zqn => '1.2500',
    zen => '0.6250',
    zsn => '0.3125',
    zyn => '0.1562',
    zxn => '0.0781',
);
for my $i ( keys %expected ) {
    is sprintf( '%.4f', $MIDI::Simple::Length{$i} ), $expected{$i}, "$i 5";
}

Music::Duration::tuple( 'qn', 'z', 3 );
my $expected = 1 / 3;
is $MIDI::Simple::Length{zqn}, $expected, 'zqn = ten';

Music::Duration::tuple( 'wn', 'z', 5 );
$expected = 4 / 5;
is $MIDI::Simple::Length{zwn}, $expected, 'zwn 5-tuple';

done_testing();
