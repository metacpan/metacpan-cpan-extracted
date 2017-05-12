#!/usr/bin/env perl

use strict;
use warnings;

my $use_pdl;
BEGIN {
  for my $lib ( 'lib', '../lib' ) {
    unshift @INC, $lib if -d $lib;
  }
  $use_pdl = eval { require PDL; require PDL::Graphics::Prima::Simple; 1 } || 0;
}

use Physics::UEMColumn alias => ':standard';

my $laser = Laser->new(
  width    => '1 mm',
  duration => '1 ps',
  energy   => '4.75 eV',
);

my $acc = DCAccelerator->new(
  length  => '20 mm',
  voltage => '20 kilovolts',
);

my $column = Column->new(
  length       => '400 mm', 
  laser        => $laser,
  accelerator  => $acc,
  photocathode => Photocathode->new( work_function => '4.25 eV' ), # Ta
);

my $sim = Physics::UEMColumn->new(
  column      => $column,
  number      => 1,
  debug       => 1,
);

my $z_rf       = 20; #cm
my $l_mag_lens = '1 in';
my $cooke_sep  = 5; #cm
my $str_mag    = 33e-13;

my $lens1 = MagneticLens->new(
  location => ($z_rf - $cooke_sep) . 'cm',
  length   => $l_mag_lens,
  strength => $str_mag,
);
my $lens2 = MagneticLens->new(
  location => ($z_rf + $cooke_sep) . 'cm',
  length   => $l_mag_lens,
  strength => $str_mag,
);
$sim->add_element($lens1);
$sim->add_element($lens2);

my $rf_cav = RFCavity->new(
  location  => $z_rf . 'cm',
  length    => '2 cm',
  strength  => '230 kilovolts / m',
  frequency => '3 gigahertz',
);
$sim->add_element($rf_cav);

my $result = $sim->propagate;

if ( $use_pdl ) {

  PDL->import;
  PDL::Graphics::Prima::Simple->import([700,500]);

  my $result = pdl( $result );

  my $z  = $result->slice('(1),');
  my $st = $result->slice('(3),');
  my $sz = $result->slice('(4),');

  plot(
    -st => ds::Pair( 
      $z, sqrt( $st / maximum($st) ),
      colors => pdl(255,0,0)->rgb_to_color,
      plotType => ppair::Lines,
      lineWidths => 3,
    ),
    -sz => ds::Pair( 
      $z, sqrt( $sz / maximum($sz) ),
      colors => pdl(0,255,0)->rgb_to_color,
      plotType => ppair::Lines,
      lineWidths => 3,
    ),
    x => { label => 'Position (m)' },
  );

  my $min_length = sqrt( 2 * minimum($sz)->sclr );
  my $min_duration = $min_length / $sim->pulse->velocity;
  printf "Min Length: %.2fnm (%.2ffs)\n", $min_length/1e-9, $min_duration/1e-15;

} else {
  warn "PDL or PDL::Graphics::Prima are not available\n";
  print join( ',', @$_ ) . "\n" for @$result;
}

