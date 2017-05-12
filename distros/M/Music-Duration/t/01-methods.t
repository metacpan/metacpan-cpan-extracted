#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

require_ok('Music::Duration');

# Set the 32nd and 64th note durations.
my %duration = (
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
# Check the MIDI::Simple::Length 32nd and 64th entries.
for my $d (keys %duration) {
    is sprintf( '%.4f', $MIDI::Simple::Length{$d} ), $duration{$d}, $d;
}

# Split the notes into 5ths.
Music::Duration::fractional('z', 5);
# Set the 1/5th z-note durations.
%duration = (
    zwn => '0.8000',
    zhn => '0.4000',
    zqn => '0.2000',
    zsn => '0.0500',
    zyn => '0.0250',
    zxn => '0.0125',
);
# Check each MIDI::Simple::Length z entry.
for my $d (keys %duration) {
    is sprintf( '%.4f', $MIDI::Simple::Length{$d} ), $duration{$d}, $d;
}

done_testing();

