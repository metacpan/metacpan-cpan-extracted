# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl NCBIParser.t'

#########################

use Test::More tests => 5;

#########################

use strict;
use Carp;
use warnings;

$Carp::Verbose = 1;
my $print_obo  = 1;

use IO::File;

use OBO::Parser::OBOParser;
use OBO::Parser::NCBIParser;

my $obo_parser  = OBO::Parser::OBOParser->new ();
my $ncbi_parser = OBO::Parser::NCBIParser->new ();
ok($ncbi_parser);

my $data_dir = "./t/data";

# 1st arg
my $in_onto_path = "$data_dir/my_parser_test.obo";
my $onto = $obo_parser->work($in_onto_path);

# 2nd arg
my $ncbi_nodes_path = "$data_dir/nodes_dummy.dmp";
my $nodes = $ncbi_parser->parse($ncbi_nodes_path);
ok ( %{$nodes} );

# 3rd arg
my $ncbi_names_path = "$data_dir/names_dummy.dmp";
my $name_type = 'scientific name';
my $names = $ncbi_parser->parse($ncbi_names_path, $name_type);
ok ( %{$names} );

# 4th arg
my $parent = $onto->get_term_by_id('GRAO:0000001');

# 5th arg
my @taxon_ids = ( '3702' );

# work
my $result = $ncbi_parser->work ( 
	$onto, 
	$nodes, 
	$names,
	$parent,
	\@taxon_ids, 
 );
ok ( %{$result} );

# terms
ok ( $onto->has_term ( $onto->get_term_by_name ('Mikel') ) );
print_obo ( $onto, "$data_dir/test_ncbi_parser_out.obo" ) if $print_obo;

sub print_obo {
	my ($onto, $path) = @_; 
	my $fh = new IO::File($path, 'w');
	$onto->export('obo', $fh);
	$fh->flush;
}
