# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;
use Test::More qw(no_plan);
use Encode 'decode';

# HACK: cpan smoke tester can't find Palm::PDB, nor can other things
eval {
	require Palm::PDB;
};
if( $@ ) {
	print STDERR "Palm::PDB not installed, can't test.";
	exit 0;
}

BEGIN { use_ok('Palm::Doc' ); }

my $doc = new Palm::Doc;
ok( defined $doc );

$doc->textfile( 'latin1.txt' );
ok( defined $doc->Write( 'latin1.pdb' ) );

$doc->{attributes}{resource} = 1;
$doc->textfile( 'latin1.txt' );
ok( defined $doc->Write( 'latin1.prc' ) );

$doc = new Palm::PDB;
ok( defined $doc );
ok( defined $doc->Load( 'latin1.prc' ) );
print decode( "iso-8859-1", $doc->text()), "\n\n";

ok(1);
exit 0;
