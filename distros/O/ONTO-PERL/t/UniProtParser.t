# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl UniProtParser.t'

#########################

use Test::More tests => 11;

#########################

use Carp;
use strict;
use warnings;

use IO::File;

$Carp::Verbose = 1;
my $print_obo  = 1;

SKIP:
{	
	eval 'use SWISS::Entry';
	skip ( 'because SWISS::Entry is required for testing the UniProt parser', 11 ) if $@;
	
	use OBO::Parser::OBOParser;
	use OBO::XO::OBO_ID_Term_Map;
	require OBO::Parser::UniProtParser;
	
	my $obo_parser = OBO::Parser::OBOParser->new ( );
	my $up_parser = OBO::Parser::UniProtParser->new ( );
	ok ( $up_parser );
	
	my $data_dir = "./t/data";
	# 1st arg 
	my $in_onto_path = "$data_dir/my_parser_test.obo";
	my $onto = $obo_parser->work ( $in_onto_path );
	
	# 2nd arg
	my $up_filtered_dat_path = "$data_dir/up.dat";
	my $up_map_path = "$data_dir/up.map";
	my $data = $up_parser->parse ( $up_filtered_dat_path, read_map ( $up_map_path ) );
	ok ( %{$data} );	
	
	# 3rd arg 
	my $parent_protein_name = "protein";
	
	# 4th arg
	my $parent_gene_name = "gene";
	
	# work ( )	
	my $result = $up_parser->work ( $onto, $data, $parent_protein_name, $parent_gene_name );
	ok ( %{$result} );
	
	# protein with 2 genes
	
	#
	# terms
	#
	ok ( my $prot = $onto->get_term_by_name ( 'EF2_SCHPO' ) );
	ok ( my $mod_prot1 = $onto->get_term_by_name ( 'EF2_SCHPO-Phosphoserine-568' ) );
	ok ( my $mod_prot2 = $onto->get_term_by_name ( 'EF2_SCHPO-Phosphothreonine-574' ) );
	ok ( my $mod_prot3 = $onto->get_term_by_name ( 'EF2_SCHPO-Diphthamide-699' ) );
#	ok ( $onto->get_term_by_name ( "EF2_SCHPO gene" ) ); # gene names are now taken from NCBI
	ok ( my $gene1 = $onto->get_term_by_id ( 'GeneID:2539544' ) );
	ok ( my $gene2 = $onto->get_term_by_id ( 'GeneID:3361483' ) );
	
	#
	# relations
	#
	my @heads_poly = @{$onto->get_head_by_relationship_type ( $prot, $onto->get_relationship_type_by_id ( "encoded_by" ) )};
#	ok ( @heads_poly == 2 ); # "encoded_by" currently not used
	my @heads_cf = @{$onto->get_head_by_relationship_type ( $gene1, $onto->get_relationship_type_by_name ( "codes for" ) )};
	ok ( @heads_cf == 1 );
	my @heads_ti = @{$onto->get_head_by_relationship_type ( $prot, $onto->get_relationship_type_by_id ( "transforms_into" ) )};
	ok ( @heads_ti == 3 ); #
	my @heads_to = @{$onto->get_head_by_relationship_type ( $mod_prot1, $onto->get_relationship_type_by_id ( "transformation_of" ) )};
#	ok ( @heads_to == 1 ); # "transformation_of" currently not used

	print_obo ( $onto, "$data_dir/test_uniprot_parser_out.obo" ) if $print_obo;
}

sub print_obo {
	my ($onto, $path) = @_;	
	my $fh = new IO::File($path, 'w');
	$onto->export('obo', $fh);
	$fh->flush;
	$fh->close;
}

sub read_map {
	my $map_file = shift or croak "No map file provided!\n";
	my %map;
	open my $FH, '<', $map_file or croak "Can't open file '$map_file': $!";
	while ( <$FH> ) {
		chomp;
		my ( $key, $value ) = split;
		$map{$key} = $value;
	}
	close $FH;
	return \%map;
}
