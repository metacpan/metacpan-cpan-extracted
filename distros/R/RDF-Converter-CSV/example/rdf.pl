use RDF::Converter::CSV;
use strict;
use warnings;
my $rdf = RDF::Converter::CSV->new(
		FILENAME 	=> 'rdf.csv', #MANDATORY
		URI		=>'http://ncbs.org/', #MANDATORY
		PREFIX 		=> 'ars', #MANDATORY
		PRIMARY 	=> 'ID', #OPTIONAL - will take one of the field as primary key, if not given 
		OUTPUT		=> 'test.rdf',#OPTIONAL - will output on the terminal, if not given
		COLUMNS		=> [ 	
					qw/
					ID 
					PUBMED_ID 
					Residues_per_subunit
					Chain_ID
					PDB_PQS 
					OLD
					Biological_unit 
					Extent_of_swapping 
					Residues_in_Hinge_loop 
					Residues_in_swapped_domain
					Sequence_of_Hingeloop 
					HINGE_REGION 
					Sequence_of_swapped_domain 
					Structure_of_swapped_region/
				] #OPTIONAL - will take the first row as the field names, if COLUMNS not given or the number of elements in COLUMN  != the number of fields in the csv file
	);
$rdf->write;

=pod
Other useful methods
$rdf->get_file;
returns the array ref of the file content
$rdf->csv_process;
returns the csv data as a array ref of hash refs
$rdf->version;
returns VERSION
=cut


