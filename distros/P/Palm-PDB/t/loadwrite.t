use strict;
use Test::More qw(no_plan);

BEGIN { use_ok('Palm::PDB') }
BEGIN { use_ok('Palm::Raw') }
BEGIN { use_ok('IO::File') }

my $name = "t/Test.pdb";

my $pdb = Palm::Raw->new;
ok( defined $pdb );
$pdb->{name} = "Test";
for( qw(tic tac toe) ) {
	print "storing '$_'\n";
	my $rec = $pdb->append_Record();
	ok( defined $rec );
	$rec->{data} = $_;
}
$pdb->Write( $name );
pass( "Write" );
undef $pdb;

my $fh = new IO::File $name, "r+";
ok( defined $fh );

$pdb = Palm::PDB->new;
ok( defined $pdb );
$pdb->Load( $fh );
pass( "Load" );

for( @{$pdb->{records}} ) {
	print "got '$_->{data}'\n";
	ok( defined $_ and length $_->{data} > 0 );
}

1;
