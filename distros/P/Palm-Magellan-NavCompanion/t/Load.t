use Test::More tests => 3;

use_ok( 'Palm::Magellan::NavCompanion' );
use_ok( 'Palm::PDB' );

my $pdb = Palm::PDB->new();
isa_ok( $pdb, 'Palm::PDB' );

$pdb->Load( 'files/waypoints.pdb' );
