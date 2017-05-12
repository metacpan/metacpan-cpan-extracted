# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OWL2Perl.t'
#########################
# change 'tests => 1' to 'tests => last_test_to_print';
#use Test::More tests => 7;
use Test::More qw/no_plan/;
use strict;
use vars qw /$outdir/;

BEGIN {
	use FindBin qw ($Bin);
	use lib "$Bin/../lib";
	$outdir = "$Bin/owl";
}

END {

	# destroy persistent data here
	# delete outdir and its contents ...
	use File::Path qw(remove_tree);
	diag("\nremoving generated modules from $outdir ...");
	remove_tree($outdir, {keep_root => 0});
	diag("done.");
}
#########################
use_ok('OWL::Utils');
use_ok('OWL::Base');
use_ok('OWL::RDF::Predicates::DC_PROTEGE');
use_ok('OWL::RDF::Predicates::OMG_LSID');
use_ok('OWL::RDF::Predicates::OWL');
use_ok('OWL::RDF::Predicates::RDF');
use_ok('OWL::RDF::Predicates::RDFS');
use_ok('OWL::Data::Def::DatatypeProperty');
use_ok('OWL::Data::Def::ObjectProperty');
use_ok('OWL::Data::Def::OWLClass');
use_ok('OWL::Data::OWL::Class');
use_ok('OWL::Data::OWL::DatatypeProperty');
use_ok('OWL::Data::OWL::ObjectProperty');
use_ok('OWL2Perl');

use base qw( OWL::Base );

# construct a default owl2perl object and check its default parameters
diag("setting default outdir() to be $outdir");
$OWLCFG::GENERATORS_OUTDIR = $outdir;
my $owl2perl = OWL2Perl->new();
isa_ok( $owl2perl, 'OWL2Perl', 'Confirm ISA' );
is( $owl2perl->force(),          0,       'Check default force' );
is( $owl2perl->follow_imports(), 0,       'Check default follow_imports' );
is( $owl2perl->outdir,           $outdir, 'check default outdir' );

# set outdir to undef and it should resort back to our default
$owl2perl->outdir(undef);
is( $owl2perl->outdir, $outdir, 'check outdir() that was set to undef' );

# check get/set for force
$owl2perl->force('true');
is( $owl2perl->force, 1, 'check force set with string "true"' );
$owl2perl->force('false');
is( $owl2perl->force, 0, 'check force set with string "false"' );

# check get/set for follow_imports
$owl2perl->follow_imports('true');
is( $owl2perl->follow_imports, 1,
	'check follow_imports set with string "true"' );
$owl2perl->follow_imports('false');
is( $owl2perl->follow_imports, 0,
	'check follow_imports set with string "false"' );

# now generate datatypes to string, eval it and test it out ...
my $cwd = $Bin;
$cwd .= "/t" unless $cwd =~ /t$/;
$owl2perl->outdir($outdir);
my $schema = $owl2perl->process_owl(
	[ "$cwd/datatypes.xml", "$cwd/inheritance-bug.owl", ],
	[
	  "http://sadiframework.org/examples/example.owl#",
	  "http://1sadiframework.org/ontologies/chebiservice.owl#"
	]
);
$owl2perl->generate_datatypes($schema);
use lib "$outdir";

# check that the properties can be used
my @properties = qw/
  sadiframework::org::examples::example::AnnotatedGeneID_Record
  ontology::dumontierlab::com::hasSymbol
  sadiframework::org::ontologies::predicates::hasDescription
  sadiframework::org::ontologies::predicates::hasProteinName
  sadiframework::org::ontologies::predicates::hasName
  purl::oclc::org::SADI::LSRN::KEGG_COMPOUND_Record
  sadiframework::org::ontologies::service_objects::hasCHEBIEntry
  sadiframework::org::ontologies::chebiservice::getCHEBIEntryFromKEGGCompound_Output
  OWL::Utils
  /;
use_ok($_) foreach (@properties);

# check the class default methods
my $class =
  sadiframework::org::examples::example::AnnotatedGeneID_Record->new('#foo');
isa_ok( $class, 'OWL::Data::OWL::Class' );
is( $class->uri,   "#foo", "check uri - set in constructor" );
is( $class->value, "#foo", "check value - set in constructor" );
$class->uri('#bar');
is( $class->uri,   "#bar", "check uri - set with setter" );
is( $class->value, "#bar", "check value - set with setter" );
is( $class->type,
	"http://sadiframework.org/examples/example.owl#AnnotatedGeneID_Record",
	"check type" );
$class->label('my label');
is( $class->label, "my label", "check label - set with setter" );

# check the properties associated with this class
# check hasSymbol
$class->hasSymbol(
			  ontology::dumontierlab::com::hasSymbol->new('Some_Gene_Symbol') );
is( scalar( @{ $class->hasSymbol() } ), 1, "check hasSymbol" );
$class->add_hasSymbol(
			 ontology::dumontierlab::com::hasSymbol->new('Some_Gene_Symbol2') );
is( scalar( @{ $class->hasSymbol() } ), 2, "check hasSymbol adder" );
is( @{ $class->hasSymbol() }[0]->value,
	'Some_Gene_Symbol', "check hasSymbol getter" );
is( @{ $class->hasSymbol() }[1]->value,
	'Some_Gene_Symbol2', "check hasSymbol getter" );
is( @{ $class->hasSymbol() }[2], undef, "check hasSymbol getter" );
isa_ok( @{ $class->hasSymbol() }[0], 'ontology::dumontierlab::com::hasSymbol' );
isa_ok( @{ $class->hasSymbol() }[1], 'ontology::dumontierlab::com::hasSymbol' );
is(
	@{ $class->hasSymbol() }[0]->uri,
	'http://ontology.dumontierlab.com/hasSymbol',
	"check type of value in hasSymbol slot"
);
is(
	@{ $class->hasSymbol() }[1]->uri,
	'http://ontology.dumontierlab.com/hasSymbol',
	"check type of value in hasSymbol slot"
);

# check hasDescription
$class->hasDescription(
				sadiframework::org::ontologies::predicates::hasDescription->new(
															 'some description')
);
is( scalar( @{ $class->hasDescription() } ), 1, "check hasDescription" );
$class->add_hasDescription(
				sadiframework::org::ontologies::predicates::hasDescription->new(
														   'some description 2')
);
is( scalar( @{ $class->hasDescription() } ), 2, "check hasDescription adder" );
is( @{ $class->hasDescription() }[0]->value,
	'some description',
	"check hasDescription getter" );
is( @{ $class->hasDescription() }[1]->value,
	'some description 2',
	"check hasDescription getter" );
is( @{ $class->hasDescription() }[2], undef, "check hasDescription getter" );
isa_ok( @{ $class->hasDescription() }[0],
		'sadiframework::org::ontologies::predicates::hasDescription' );
isa_ok( @{ $class->hasDescription() }[1],
		'sadiframework::org::ontologies::predicates::hasDescription' );
is(
	@{ $class->hasDescription() }[0]->uri,
	'http://sadiframework.org/ontologies/predicates.owl#hasDescription',
	"check type of value in hasDescription slot"
);
is(
	@{ $class->hasDescription() }[1]->uri,
	'http://sadiframework.org/ontologies/predicates.owl#hasDescription',
	"check type of value in hasDescription slot"
);

# check hasProteinName
$class->hasProteinName(
				sadiframework::org::ontologies::predicates::hasProteinName->new(
															'some protein name')
);
is( scalar( @{ $class->hasProteinName() } ), 1, "check hasProteinName" );
$class->add_hasProteinName(
				sadiframework::org::ontologies::predicates::hasProteinName->new(
														  'some protein name 2')
);
is( scalar( @{ $class->hasProteinName() } ), 2, "check hasProteinName adder" );
is( @{ $class->hasProteinName() }[0]->value,
	'some protein name',
	"check hasProteinName getter" );
is( @{ $class->hasProteinName() }[1]->value,
	'some protein name 2',
	"check hasProteinName getter" );
is( @{ $class->hasProteinName() }[2], undef, "check hasProteinName getter" );
isa_ok( @{ $class->hasProteinName() }[0],
		'sadiframework::org::ontologies::predicates::hasProteinName' );
isa_ok( @{ $class->hasProteinName() }[1],
		'sadiframework::org::ontologies::predicates::hasProteinName' );
is(
	@{ $class->hasProteinName() }[0]->uri,
	'http://sadiframework.org/ontologies/predicates.owl#hasProteinName',
	"check type of value in hasProteinName slot"
);
is(
	@{ $class->hasProteinName() }[1]->uri,
	'http://sadiframework.org/ontologies/predicates.owl#hasProteinName',
	"check type of value in hasProteinName slot"
);

# check hasName
$class->hasName(
		sadiframework::org::ontologies::predicates::hasName->new('some name') );
is( scalar( @{ $class->hasName() } ), 1, "check hasName" );
$class->add_hasName(
	  sadiframework::org::ontologies::predicates::hasName->new('some name 2') );
is( scalar( @{ $class->hasName() } ), 2,             "check hasName adder" );
is( @{ $class->hasName() }[0]->value, 'some name',   "check hasName getter" );
is( @{ $class->hasName() }[1]->value, 'some name 2', "check hasName getter" );
is( @{ $class->hasName() }[2],        undef,         "check hasName getter" );
isa_ok( @{ $class->hasName() }[0],
		'sadiframework::org::ontologies::predicates::hasName' );
isa_ok( @{ $class->hasName() }[1],
		'sadiframework::org::ontologies::predicates::hasName' );
is( @{ $class->hasName() }[0]->uri,
	'http://sadiframework.org/ontologies/predicates.owl#hasName',
	"check type of value in hasName slot" );
is( @{ $class->hasName() }[1]->uri,
	'http://sadiframework.org/ontologies/predicates.owl#hasName',
	"check type of value in hasName slot" );
