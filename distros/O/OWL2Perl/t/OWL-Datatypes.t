# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl OWL-Datatypes.t'
#########################
# change 'tests => 1' to 'tests => last_test_to_print';
#use Test::More tests => 7;
use Test::More qw/no_plan/;
use strict;
use Cwd 'abs_path';
use vars qw /$outdir/;

BEGIN {
    use FindBin qw ($Bin);
    use lib "$Bin/../lib";
    if ( $Bin =~ m/t$/ ) {
        $outdir = abs_path("$Bin") . "/owl";
    } else {
        $outdir = abs_path("$Bin/t") . "/owl";
    }
    my $cmd = $Bin;
    $cmd .= "/t" unless $cmd =~ /t$/;
    $cmd = abs_path($cmd);
    diag(
"\nTo run this test, we need to generate perl modules!\nThis is done via the following command:\n"
          . "$^X '"
          . abs_path("$cmd/../bin/scripts/owl2perl-generate-modules.pl")
          . "' -o $outdir $cmd/datatypes.xml $cmd/inheritance-bug.owl" );
    system( $^X, abs_path("$cmd/../bin/scripts/owl2perl-generate-modules.pl"),
            "-o", $outdir, "$cmd/datatypes.xml", "$cmd/inheritance-bug.owl" );
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
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
use lib "$outdir";
use_ok('sadiframework::org::examples::example::AnnotatedGeneID_Record');
use_ok('sadiframework::org::examples::example::getEcGeneComponentPartsHuman_Output');

# check that the properties can be used
my @properties = qw/ontology::dumontierlab::com::hasSymbol
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
  sadiframework::org::examples::example::AnnotatedGeneID_Record->new(
																		'#foo');
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
	  sadiframework::org::ontologies::predicates::hasName->new('some name')
);
is( scalar( @{ $class->hasName() } ), 1, "check hasName" );
$class->add_hasName(
				  sadiframework::org::ontologies::predicates::hasName->new(
																  'some name 2')
);
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

# class with specific hasValue restrictions
$class = new sadiframework::org::examples::example::getEcGeneComponentPartsHuman_Output();
isa_ok($class, 'purl::oclc::org::SADI::LSRN::KEGG_ec_Record', 'Check our classes equivalent class');
is(OWL::Utils->trim(@{ $class->hasName() }[0]->value()), 'some resource name', 'Check the hasValue field for datatype property');
diag(@{ $class->hasName2() }[0]->value());
is(@{ $class->hasResource() }[0]->value(), 'http://lsrn.org/taxon:9606', 'Check the hasValue field for object property');
isa_ok(@{ $class->hasResource() }[0], 'purl::oclc::org::SADI::LSRN::taxon_Record', 'Confirm hasResource is a taxon_Record');
isa_ok(@{ $class->hasResource2() }[0], 'OWL::Data::OWL::Class', 'Confirm hasResource2 is a OWL::Data::OWL::Class since its type is not explicitly set');
is(@{ $class->hasResource2() }[0]->value(), 'http://lsrn.org/taxon:90100', 'Check the hasValue field for object property with no type');
