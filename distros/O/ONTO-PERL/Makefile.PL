# $Id: Makefile.PL 2014-01-17 09:22:13Z erick.antezana $
use 5.006;
use ExtUtils::MakeMaker;
use strict;

my $p = 'Date::Manip';
if (!eval "require $p") {
    print <<MSG;

   Date::Manip is missing. This module is required in order to perform checks 
   of dates while parsing OBO-formatted files (e.g. 'creation_date' tag).

MSG
      
}

$p = 'SWISS::Entry';
if (!eval "require $p") {
    print <<MSG;

   SWISS::Entry is missing. This module is only required in order to
   perform parsing operations with UniProt files. However, this 
   module is not required for using the rest of ONTO-PERL. If you do 
   not intend to use UniProt files, then you may continue, and install 
   SWISS::Entry in the future.

MSG
      
}

$p = 'XML::Parser';
if (!eval "require $p") {
    print <<MSG;

   XML::Parser is missing. This module is only required in order to
   perform parsing operations with XML files (obo2owl). However, this 
   module is not fully required for using the rest of ONTO-PERL. If you 
   do not intend to convert your files to OWL, then you may continue, 
   and install XML::Parser in the future.

MSG
      
}

$p = 'XML::XPath';
if (!eval "require $p") {
    print <<MSG;

   XML::XPath is missing. This module is only required in order to
   perform parsing operations with IntAct-XML files. However, this 
   module is not required for using the rest of ONTO-PERL. If you do 
   not intend to use IntAct XML files, then you may continue, and 
   install XML::XPath in the future.

MSG
      
}

$p = 'Text::CSV';
if (!eval "require $p") {
    print <<MSG;

   Text::CSV is missing. This module is only required in order to
   generate an OBO-formatted file from any CSV file found at the 
   BioPortal (http://bioportal.bioontology.org/). However, this 
   module is not required for using the rest of ONTO-PERL. If you do 
   not intend to use those CSV files, then you may continue, and 
   install Text::CSV in the future.

MSG
      
}

my @license = $ExtUtils::MakeMaker::VERSION > 6.84
? qw(LICENSE perl)
: ();

my @authors = ('Erick Antezana <erick.antezana -@- gmail.com>, Vladimir Mironov <vladimir.n.mironov -@- gmail.com>');

WriteMakefile(
	NAME               => 'Ontology',
	DISTNAME           => 'ONTO-PERL',
	ABSTRACT           => 'PERL modules for manipulating OBO-formatted ontologies, such as the Gene Ontology (GO)',
	VERSION_FROM       => 'lib/OBO/Core/Ontology.pm',
	MIN_PERL_VERSION   => '5.005',
	@license,
	PREREQ_PM          => {
						'Date::Manip'         => 6.42,
						#'SWISS::Entry'       => 1.67, # optional
						#'XML::Parser'        => 2.41, # optional
						#'XML::XPath'         => 1.13, # optional
						#'Text::CSV'          => 1.32  # optional
						},
	PREREQ_PRINT       => 'TRUE',
	BUILD_REQUIRES     => { 'Date::Manip' => 6.42, 'ExtUtils::MakeMaker' => 6.84 },
	CONFIGURE_REQUIRES => { 'Date::Manip' => 6.42, 'ExtUtils::MakeMaker' => 6.84 },
	EXE_FILES          => [
							qw(
								scripts/bioportal_csv2obo.pl
								scripts/get_ancestor_terms.pl
								scripts/get_child_terms.pl
								scripts/get_descendent_terms.pl
								scripts/get_lowest_common_ancestor.pl
								scripts/get_obsolete_term_id_vs_def_in_go.pl
								scripts/get_obsolete_term_id_vs_name_in_go.pl
								scripts/get_obsolete_terms.pl
								scripts/get_parent_terms.pl
								scripts/get_relationship_id_vs_relationship_def.pl
								scripts/get_relationship_id_vs_relationship_name.pl
								scripts/get_relationship_id_vs_relationship_namespace.pl
								scripts/get_relationship_types.pl
								scripts/get_root_terms.pl
								scripts/get_subontology_from.pl
								scripts/get_term_id_vs_term_def.pl
								scripts/get_term_id_vs_term_name.pl
								scripts/get_term_id_vs_term_namespace.pl
								scripts/get_term_local_neighbourhood.pl
								scripts/get_term_synonyms.pl
								scripts/get_terms.pl
								scripts/get_terms_and_synonyms.pl
								scripts/get_terms_by_name.pl
								scripts/go2csv.pl
								scripts/go2owl.pl
								scripts/goa2rdf.pl
								scripts/obo2apo.pl
								scripts/obo2owl.pl
								scripts/obo2rdf.pl
								scripts/obo2tran.pl	
								scripts/obo2xml.pl
								scripts/obo_intersection.pl
								scripts/obo_transitive_reduction.pl
								scripts/obo_trimming.pl
								scripts/obo_union.pl
								scripts/owl2obo.pl
							)
						],
			
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	(AUTHOR   => @authors) : ()),
	dist      => { 
					'SUFFIX'       => '.gz',
					'DIST_DEFAULT' => 'all tardist',
					'COMPRESS'     => 'gzip -9f' 
				},
	clean      => {FILES =>"t/data/test0.obo
							t/data/test1.obo
							t/data/test1.rdf
							t/data/test1.xml
							t/data/test2.dot
							t/data/test2.obo
							t/data/test2.owl
							t/data/test2.rdf
							t/data/test2.xml
							t/data/test_go.obo
							t/data/test_go_transitive_closure.obo
							t/data/test_go_transitive_reduction.obo
							t/data/test_goa.rdf
							t/data/test_goa_parser_out.obo
							t/data/test_intact_parser_out.obo
							t/data/test_ncbi.rdf
							t/data/test_ncbi_parser_out.obo
							t/data/test_ulo_apo.dot
							t/data/test_ulo_apo.owl
							t/data/test_ulo_apo2.obo
							t/data/test_uniprot_parser_out.obo
							t/data/test_uo.rdf"},
);
