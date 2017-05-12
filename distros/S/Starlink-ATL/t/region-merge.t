#!/usr/bin/env perl

use strict;

use Test::More tests => 2 + 6;

use Astro::Coords;
use Astro::Coords::Offset;
use Astro::PAL;
use Starlink::AST;

our $plot = 0; # Plot for debugging purposes.

use_ok('Starlink::ATL::Region');


# Set up test scenario.

my $skyframe = new Starlink::AST::SkyFrame('SYSTEM=FK5');
my $basepos = new Astro::Coords(ra => '14:30:00', dec => '+36:15:00',
                                type => 'J2000', units => 'sexagesimal');

prepare_plot() if $plot;


# Construct 3 regions and merge them.

my @regions;
foreach my $off ([0, 0], [60, 0], [0, 60]) {
  my $coord = $basepos->apply_offset(new Astro::Coords::Offset(@$off,
                                           'system' => 'J2000',
                                           projection =>'TAN'));
  push @regions, new Starlink::AST::Circle($skyframe, 1,
                       [map {$_->radians()} $coord->radec2000()],
                       [Astro::PAL::DAS2R * 60], undef, '');
}

my $merged = Starlink::ATL::Region::merge_regions(\@regions);

ok('Starlink::AST::CmpRegion' eq ref $merged);

plot_region($merged, 4) if $plot;


# Check a series of points are inside/outside the merged region.

my %title = (1 => 'no overlap with region', 2 => 'inside region');

foreach ([0, 0, 2], [60, 0, 2], [0, 60, 2],
         [-80, 0, 1], [0, -80, 1], [80, 80, 1]) {
  my @off = @$_;
  my $coord = $basepos->apply_offset(new Astro::Coords::Offset(@off[0, 1],
                                           'system' => 'J2000',
                                           projection =>'TAN'));

  my $region = new Starlink::AST::Circle($skyframe, 1,
                       [map {$_->radians()} $coord->radec2000()],
                       [Astro::PAL::DAS2R * 10], undef, '');

  plot_region($region, 1) if $plot;

  is($region->Overlap($merged), $off[2], 'position ' . join(', ', @off[0, 1]) .
                                         ' ' . $title{$off[2]});
}


# Prepare a PGPLOT display.

sub prepare_plot {
  my $fchan = new Starlink::AST::FitsChan();
  foreach (
        'NAXIS1  = 1000',
        'NAXIS2  = 1000 ',
        'CRPIX1  = 500 ',
        'CRPIX2  = 500',
        'CRVAL1  = ' . $basepos->ra(format => 'deg'),
        'CRVAL2  = ' . $basepos->dec(format => 'deg'),
        'CTYPE1  = \'RA---TAN\'',
        'CTYPE2  = \'DEC--TAN\'',
        'CD1_1   = ' . 360 * Astro::PAL::DAS2R * Astro::PAL::DR2D / 1000,
        'CD2_2   = ' . 360 * Astro::PAL::DAS2R * Astro::PAL::DR2D / 1000,
        'RADESYS = \'FK5\'',
    ) {$fchan->PutFits($_, 0);}
  $fchan->Clear('Card');
  my $wcs = $fchan->Read();
  require PGPLOT;
  require Starlink::AST::PGPLOT;

  my $pgdev = PGPLOT::pgopen('/xserve');
  PGPLOT::pgwnad(0, 1, 0, 1);
  PGPLOT::pgqwin(my $x1, my $y1, my $x2, my $y2);

  $plot = new Starlink::AST::Plot($wcs, [0.0, 0.0, 1.0, 1.0],
                                     [0.5, 0.5, 1000.5, 1000.5],
                 'Grid=1,tickall=0,border=1,tol=0.001'
                 . ',colour(border)=4,colour(grid)=3,colour(ticks)=3'
                 . ',colour(numlab)=5,colour(axes)=3');
  $plot->pgplot();
  $plot->Grid();
  $plot->Set('System=FK5');

  return $plot;
}


# Plot a given region.

sub plot_region {
  my ($region, $color) = @_;

  my $fitswcsb = $plot->Get('Base');
  my $fitswcsc = $plot->Get('Current');

  my $fs = $plot->Convert($region, '');
  $plot->Set('Base='.$fitswcsb);
  my $map = $fs->GetMapping(Starlink::AST::AST__BASE(),
                                Starlink::AST::AST__CURRENT());
  $plot->AddFrame(Starlink::AST::AST__CURRENT(), $map, $region);
  $plot->Set('colour(border)=' . $color);
  $plot->Border();

  my $current = $plot->Get('Current');
  $plot->RemoveFrame($current);
  $plot->Set('Current='.$fitswcsc);
}
