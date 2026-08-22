use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Physics::Etch::Layout;

# two square openings: 2x2 um and 4x4 um, in a 10x10 um field
my @polys = (
    [ [ 0, 0 ], [ 2, 0 ], [ 2, 2 ], [ 0, 2 ], [ 0, 0 ] ],
    [ [ 5, 5 ], [ 9, 5 ], [ 9, 9 ], [ 5, 9 ], [ 5, 5 ] ],
);

my $lay = Physics::Etch::Layout->new(
    polygons => \@polys, tone => 'clear', field => [ 10, 10 ] );

is( $lay->count, 2, 'feature count' );

# areas: 4 + 16 = 20 um^2 of 100 um^2 field
ok( abs( $lay->drawn_area_um2 - 20 ) < 1e-9, 'drawn area' );
ok( abs( $lay->open_area_um2 - 20 ) < 1e-9,  'open area (clear tone)' );
ok( abs( $lay->open_fraction - 0.20 ) < 1e-9, 'open fraction 20%' );
ok( abs( $lay->open_area_cm2 - 20e-8 ) < 1e-18, 'open area in cm^2' );

# CD = narrow side: 2 um (2000 nm) and 4 um (4000 nm)
my $cd = $lay->cd_stats_nm;
is( $cd->{min}, 2000, 'min CD nm' );
is( $cd->{max}, 4000, 'max CD nm' );
ok( abs( $cd->{mean} - 3000 ) < 1e-6, 'mean CD nm' );

# dark tone: open = field - drawn = 80 um^2
my $dark = Physics::Etch::Layout->new(
    polygons => \@polys, tone => 'dark', field => [ 10, 10 ] );
ok( abs( $dark->open_area_um2 - 80 ) < 1e-9, 'dark tone open area' );
ok( abs( $dark->open_fraction - 0.80 ) < 1e-9, 'dark tone open fraction' );

# density map: mean open density over bbox should be > 0
my $den = $lay->density_map( cell_um => 2, subsamples => 5 );
ok( $den->{nx} >= 1 && $den->{ny} >= 1, 'density grid built' );
ok( $den->{mean} > 0 && $den->{mean} <= 1, 'density mean in (0,1]' );
ok( $den->{max} >= $den->{mean} && $den->{min} <= $den->{mean},
    'density min <= mean <= max' );

# point-in-polygon sanity via density at a fully-covered cell
ok( $lay->_point_drawn( 1, 1 ),  'point inside small square' );
ok( !$lay->_point_drawn( 3, 3 ), 'point in the gap is open' );

like( $lay->summary, qr/open/, 'summary renders' );

done_testing;
