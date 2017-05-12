use Test::More tests => 6;

use_ok( 'Palm::Magellan::NavCompanion' );

my $pdb = Palm::PDB->new;
isa_ok( $pdb, 'Palm::PDB' );

$pdb->Load( 'files/waypoints.pdb' );

my $records = $pdb->{records};

is( @$records, 22, "Count of records is right" );

{
my $record = $records->[2];
isa_ok( $record, 'Palm::Magellan::NavCompanion::Record' );

is( $record->name, 'Addison', 
	'Last name is right' );
is( $record->description, 'Wrigley Field', 
	'Last description is right' );
}
