use Test::More tests => 5;

use_ok( 'Palm::Magellan::NavCompanion' );

my $pdb = Palm::PDB->new;
isa_ok( $pdb, 'Palm::PDB' );

$pdb->Load( 'files/waypoints.pdb' );

my $records = $pdb->{records};

is( @$records, 22, "Count of records is right" );

{
my $record = $records->[-1];

is( $record->{name}, 'Wilson El Stop', 
	'Last name is right' );
is( $record->{description}, 'Named after the president', 
	'Last description is right' );
}
