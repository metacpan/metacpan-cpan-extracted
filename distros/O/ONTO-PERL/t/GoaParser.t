# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl GoaParser.t'

#########################

use Test::More tests => 9;

#########################

use Carp;
use strict;
use warnings;

use IO::File;

$Carp::Verbose = 1;
my $print_obo  = 1;

use OBO::Parser::GoaParser;
use OBO::Parser::OBOParser;

my $obo_parser = OBO::Parser::OBOParser->new ( );
my $goa_parser = OBO::Parser::GoaParser->new ( );
ok ( $goa_parser );

my $data_dir = "./t/data";

# GOA P annottations
# 1st arg
my $in_obo_path = "$data_dir/my_parser_test.obo";
my $onto        = $obo_parser->work ( $in_obo_path );

# 2nd arg
my $goa_path = "$data_dir/all.goa";

# filtering by GO map
my $map_path = "$data_dir/go.map";
my $data     = $goa_parser->parse ( $goa_path, read_map ( $map_path ) );
ok ( %{$data} );

# filtering by UP map
$map_path = "$data_dir/up.map";
$data     = $goa_parser->parse ( $goa_path, read_map ( $map_path ) );
ok ( %{$data} );

# 3rd arg
my $parent_protein_name = 'protein';

# work	
my $result = $goa_parser->work ( 
	$onto, 
	$data, 
	$parent_protein_name
);
ok ( %{$result} );

ok ( my $protein = $onto->get_term_by_id ( "UniProtKB:O94639" ) );
ok ( ! $onto->get_term_by_id ( "UniProtKB:Q9P3E3" ) );
# relations
my @heads_pi = @{$onto->get_head_by_relationship_type ( $protein, $onto->get_relationship_type_by_name ('participates in') )};
ok ( @heads_pi == 1 );

# GOA C and F annotations
# 2nd arg
$goa_path = "$data_dir/all.goa";
$data     = $goa_parser->parse ( $goa_path );

$result = $goa_parser->work ( 
	$onto, 
	$data, 
 );
ok ( %{$result} );
# relations
my @heads_li = @{$onto->get_head_by_relationship_type ( $protein, $onto->get_relationship_type_by_id ('located_in') )};
ok ( @heads_li == 4 );

print_obo ( $onto, "$data_dir/test_goa_parser_out.obo" ) if $print_obo;

sub print_obo {
	my ($onto, $path) = @_;
	my $fh = new IO::File($path, 'w');
	$onto->export('obo', $fh);
	$fh->flush;
	$fh->close;
}

sub read_map {
	my $map_file = shift or croak "No map file provided! \n";
	my %map;
	open my $FH, '<', $map_file or croak "Can't open file '$map_file': $! ";
	while ( <$FH> ) {
		chomp;
		my ( $key, $value ) = split;
		$map{$key} = $value;
	}
	close $FH;
	return \%map;
}
