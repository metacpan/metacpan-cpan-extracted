# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl NewIntActParser.t'

#########################

use Test::More tests => 10;

#########################

use Carp;
use strict;
use warnings;

use IO::File;

$Carp::Verbose = 1;
my $print_obo  = 1;

SKIP:
{	
	eval { require XML::XPath };
	skip ( 'because XML::XPath is required for testing the NewIntAct parser', 10 ) if $@;
	
	use OBO::Parser::OBOParser;	
	require OBO::Parser::IntActParser;	
	
	my $obo_parser    = OBO::Parser::OBOParser->new ();	
	my $intact_parser = OBO::Parser::IntActParser->new ();
	ok ($intact_parser);
		
	my $data_dir = "./t/data";
		
	# 1st arg
	my $in_obo_path = "$data_dir/my_parser_test.obo";
	my $onto        = $obo_parser->work($in_obo_path);
	ok (!$onto->get_term_by_name('DDB2_HUMAN'));
	
	# 2nd arg
	my @intact_files = ( "$data_dir/human_small-41.xml" );
	my $intact_files = \@intact_files;
	my $up_map_path  = "$data_dir/up.map";
	my $up_map       = read_map ( $up_map_path );
	my $data         = $intact_parser->parse ( $intact_files, $up_map, $up_map );
	ok ( %{$data} );
	
	# 3rd arg
	my $parent_protein_name = 'protein';
	
	# work ( )		
	my $result = $intact_parser->work ( 
		$onto, 
		$data, 
		$parent_protein_name
	 );
	ok ( %{$result} );
	
	# terms
	# 1 of 2 proteins added
	ok ( my $protein = $onto->get_term_by_id('UniProtKB:Q92466'));
	my $protein1     = $onto->get_term_by_id('UniProtKB:Q01094');
	ok ( !$protein1 );
	ok ( my  $interaction = $onto->get_term_by_id('EBI:1213634'));
	
	# relations
	my @tails_hp = @{$onto->get_tail_by_relationship_type ( $protein, $onto->get_relationship_type_by_name ( "has participant" ) )};
	ok ( @tails_hp == 1 );
	my @heads_hp = @{$onto->get_head_by_relationship_type ( $interaction, $onto->get_relationship_type_by_name ( "has participant" ) )};
	ok ( @heads_hp == 1 );
	my @heads_hs = @{$onto->get_head_by_relationship_type ( $protein, $onto->get_relationship_type_by_name ( "has source" ) )};
	ok ( @heads_hs == 1 );
	print_obo ( $onto, "$data_dir/test_intact_parser_out.obo" ) if $print_obo;
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

sub print_obo {
	my ($onto, $path) = @_;
	my $fh = new IO::File($path, 'w');
	$onto->export('obo', $fh);
	$fh->flush;
	$fh->close;
}
