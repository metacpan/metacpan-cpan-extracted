use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Physics::Etch;
use Physics::Etch::Layout;
use Physics::Etch::Chamber;
use Physics::Etch::Loading;
use Physics::Etch::Simulation;

# narrow 0.2 um line and wide 5 um pad, well separated (micro loading isolated)
my $layout = Physics::Etch::Layout->new(
    polygons => [
        [ [ 0,  0 ], [ 0.2, 0 ], [ 0.2, 10 ], [ 0, 10 ], [ 0, 0 ] ],
        [ [ 40, 0 ], [ 45,  0 ], [ 45,  10 ], [ 40, 10 ], [ 40, 0 ] ],
    ],
    tone  => 'clear',
    field => [ 50, 50 ],
);

my $chamber = Physics::Etch::Chamber->new(
    wafer_diameter_mm => 150, pressure_mtorr => 20, power_w => 300, flow_sccm => 50 );

# sharp RIE lag; disable micro loading to isolate the ARDE effect
my $loading = Physics::Etch::Loading->new( kappa => 0.01, k_micro => 0, arde_length => 2 );

my $etch = Physics::Etch->dry_etch( 'silicon_nitride',
    thickness => 500, overetch => 0.10, anisotropy => 0.9 );

my $sim = Physics::Etch::Simulation->new(
    process => $etch, chamber => $chamber,
    layout  => $layout, loading => $loading );
$sim->run;
my $r = $sim->result;

# 1) chamber conditions applied to the process
ok( abs( $etch->bias - $chamber->self_bias_v ) < 1e-6,
    'chamber DC bias handed to the process' );
is( $etch->pressure, $chamber->pressure_mtorr, 'chamber pressure handed over' );

# 2) macro loading lowers the global rate (relative to the sim's own base,
#    which already includes the chamber-applied bias/pressure)
ok( $r->{macro_factor} < 1, 'macro loading factor < 1' );
ok( $r->{loaded_rate} < $r->{base_rate}, 'loaded rate below base rate' );
ok( abs( $r->{loaded_rate} - $r->{base_rate} * $r->{macro_factor} ) < 1e-6,
    'loaded rate = base * macro factor' );

# 3) ARDE: narrow feature etches shallower than the wide one
my %by_cd = map { sprintf( '%.0f', $_->{cd_nm} ) => $_ } @{ $sim->features_by_cd };
my $narrow = $by_cd{200};
my $wide   = $by_cd{5000};
ok( $narrow && $wide, 'both CD groups present' );
ok( $narrow->{aspect_ratio} > $wide->{aspect_ratio}, 'narrow has higher AR' );
ok( $narrow->{arde_factor} < $wide->{arde_factor}, 'narrow suffers more RIE lag' );
ok( $narrow->{depth} < $wide->{depth}, 'narrow etches shallower (RIE lag)' );

# 4) with sharp lag the narrow feature should fail to clear while wide clears
ok( $wide->{cleared},    'wide feature clears' );
ok( !$narrow->{cleared}, 'narrow feature does not clear (RIE lag)' );

# 5) anisotropy is reported per feature and taper is slightly worse when narrow
ok( $narrow->{anisotropy} <= $wide->{anisotropy} + 1e-9,
    'narrow feature no more anisotropic than wide (tapering)' );

# 6) report renders
like( $sim->report, qr/ETCH SIMULATION/, 'simulation report renders' );

# 7) works without a chamber/loading too (process-only)
my $sim2 = Physics::Etch::Simulation->new(
    process => Physics::Etch->dry_etch( 'tantalum', thickness => 150 ),
    layout  => $layout );
ok( $sim2->run->result->{features}, 'runs without chamber/loading' );

done_testing;
