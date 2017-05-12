# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OWL-Base.t'
#########################
# change 'tests => 1' to 'tests => last_test_to_print';
#use Test::More tests => 7;
use Test::More qw/no_plan/;

BEGIN {
	use FindBin qw ($Bin);
	use lib "$Bin/../lib";
	use_ok('OWL::Base');
	use_ok('OWL::Data::Boolean');
	use_ok('OWL::Data::DateTime');
	use_ok('OWL::Data::Float');
	use_ok('OWL::Data::Integer');
	use_ok('OWL::Data::String');
}

END {

	# destroy persistent data here
}
#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
# test primed object
my $data = OWL::Data::Object->new( namespace => "NCBI_gi", id => "545454" );
is( ref $data, "OWL::Data::Object",
	'is object reference a OWL::Data::Object?' );
can_ok( $data, ( 'toString', 'id', 'namespace', 'primitive', 'throw' ) );
ok( $data->id eq '545454', 'Check id we primed this object with' );
ok( $data->namespace eq 'NCBI_gi',
	'Check namespace we primed this object with' );
ok( !$data->primitive, 'Check if we are a primitive' );

# test unprimed object
$data = OWL::Data::Object->new();
is( ref $data, "OWL::Data::Object",
	'is object reference a OWL::Data::Object?' );
can_ok( $data, ( 'toString', 'id', 'namespace' ) );
ok( $data->id        eq '', 'Check id (should be empty)' );
ok( $data->namespace eq '', 'Check namespace (should be empty)' );
ok( !$data->primitive, 'Check if we are a primitive' );

# test primed boolean
$data =
  OWL::Data::Boolean->new( namespace => "NCBI_gi", id => "545454", value => 1 );
is( ref $data, "OWL::Data::Boolean",
	'check object reference (OWL::Data::Boolean)' );
can_ok( $data, ( 'toString', 'id', 'namespace', 'value' ) );
ok( $data->id eq '545454', 'Check id we primed this object with' );
ok( $data->namespace eq 'NCBI_gi',
	'Check namespace we primed this object with' );
ok( $data->primitive, 'Check if we are a primitive' );
ok( $data->value eq 1, 'check the value' );

# test unprimed boolean
$data = OWL::Data::Boolean->new();
is( ref $data, "OWL::Data::Boolean",
	'check object reference (OWL::Data::Boolean)' );
can_ok( $data, ( 'toString', 'id', 'namespace', 'value' ) );
ok( $data->id        eq '', 'Check id (should be empty)' );
ok( $data->namespace eq '', 'Check namespace (should be empty)' );
ok( $data->primitive, 'Check if we are a primitive' );
ok( $data->value eq 1, 'check the value' );

# test primed datetime
$data = OWL::Data::DateTime->new(
								  namespace => "NCBI_gi",
								  id        => "545454",
								  value     => '2009-07-15 19:44:55Z'
);
is( ref $data, "OWL::Data::DateTime",
	'check object reference (OWL::Data::DateTime)' );
can_ok( $data, ( 'toString', 'id', 'namespace', 'value' ) );
ok( $data->id eq '545454', 'Check id we primed this object with' );
ok( $data->namespace eq 'NCBI_gi',
	'Check namespace we primed this object with' );
ok( $data->primitive, 'Check if we are a primitive' );
ok( $data->value eq '2009-07-15 19:44:55Z', 'check the value' );

# test unprimed datetime
$data = OWL::Data::DateTime->new();
is( ref $data, "OWL::Data::DateTime",
	'check object reference (OWL::Data::DateTime)' );
can_ok( $data, ( 'toString', 'id', 'namespace', 'value' ) );
ok( $data->id        eq '', 'Check id (should be empty)' );
ok( $data->namespace eq '', 'Check namespace (should be empty)' );
ok( $data->primitive,     'Check if we are a primitive' );
ok( defined $data->value, 'check the value' );

# test incorrectly primed datetime
$data = OWL::Data::DateTime->new( value => 'a' );
is(
	ref $data,
	"OWL::Data::DateTime",
	'check object reference for incorrectly primed object (OWL::Data::DateTime)'
);
can_ok( $data, ( 'toString', 'id', 'namespace', 'value' ) );
ok( $data->id        eq '', 'Check id (should be empty)' );
ok( $data->namespace eq '', 'Check namespace (should be empty)' );
ok( $data->primitive,     'Check if we are a primitive' );
ok( defined $data->value, 'check the value' );

# test check for package names created from uris:
# create empty string object for this test
$data = OWL::Data::String->new( );
my @packages = qw(
  http://dev.biordf.net/~kawas/owl/getUniprotByKeggGene.owl#UniprotByKeggGeneOutputClass
  http://dev.biordf.net/~kawas/owl/getUniprotByKeggGene.owl#~UniprotByKeggGeneOutputClass
  http://dev.biordf.net/~kawas/owl/getUniprotByKeggGene.owl#UniprotByKeggGeneOutputClass#
  http://dev.biordf.net/~kawas/owl/getUniprotByKeggGene.owl#UniprotByKeggGeneOutputClass##///
  http://dev.biordf.net/~kawas/owl/getUniprotByKeggGene.owl#UniprotByKeggGeneOutputClass/
  http://dev.biordf.net/~kawas/owl/getUniprotByKeggGene.owl#UniprotByKeggGeneOutputClass//
  http://dev.biordf.net/~kawas/owl/getUniprotByKeggGene.owl##UniprotByKeggGeneOutputClass
  http://dev.biordf.net/~kawas/owl/getUniprotByKeggGene.owl/UniprotByKeggGeneOutputClass
  http://dev.biordf.net/~kawas/owl/getUniprotByKeggGene.owl//UniprotByKeggGeneOutputClass
  http://dev.biordf.net/~kawas/owl/getUniprotByKeggGene.owl/#UniprotByKeggGeneOutputClass
  http://dev.biordf.net/~kawas/owl/getUniprotByKeggGene.owl#/UniprotByKeggGeneOutputClass
);

my $pac = undef;
$pac = $data->uri2package($_) and ok( $pac
	 eq
'dev::biordf::net::kawas::owl::getUniprotByKeggGene::UniprotByKeggGeneOutputClass',
	"check uri2package($_) = $pac"
) foreach (@packages);

ok ($data->uri2package("urn:lsid:dev.biordf.net:getUniprotByKeggGene.owl:UniprotByKeggGeneOutputClass") eq 
'dev::biordf::net::getUniprotByKeggGene::UniprotByKeggGeneOutputClass',"Check uri2package(LSID)");
